#!/usr/bin/env bash
# Claude Code statusLine command
#
# Field layout (left → right):
#   1. proxy icon     - env vars: HTTPS_PROXY / HTTP_PROXY (ALL_PROXY excluded: SOCKS only)
#                       proxy on → green [P]   proxy off → yellow ⚠️  (work env expects proxy)
#   2. model          - stdin: .model.display_name  (magenta)
#   3. dir (branch*)  - stdin: .workspace.current_dir / .cwd → last 2 segments (cyan)
#                       git branch appended as "dir (branch)"; dirty → branch* in red
#                       omitted when not in a git repo
#   4. Tokens+cost    - stdin: .context_window.total_input_tokens + total_output_tokens (orange)
#                       cost from stdin: .cost.total_cost_usd (Claude Code statusline schema)
#   5. ctx bar        - stdin: .context_window.used_percentage (10-cell ▓/░ bar + %)
#                       <50% green · 50-80% yellow · >80% red
#   6. rate limits    - stdin: .rate_limits.five_hour / .rate_limits.seven_day → 5h:X% 7d:X%
#                       each independently: <50% green · 50-80% yellow · >80% red

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
ORANGE='\033[38;5;208m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DIM='\033[2m'
RESET='\033[0m'

sep="${DIM} | ${RESET}"

# ---------------------------------------------------------------------------
# Read stdin JSON once
# ---------------------------------------------------------------------------
input=$(cat)

# ---------------------------------------------------------------------------
# Field 1: Proxy icon  (source: environment variables)
# ---------------------------------------------------------------------------
# Detection:
#   - HTTPS_PROXY / HTTP_PROXY non-empty → proxy on
#   - ALL_PROXY excluded: Claude Code does not support SOCKS proxies
proxy_on=false

if [ -n "${HTTPS_PROXY:-}" ] || [ -n "${HTTP_PROXY:-}" ]; then
    proxy_on=true
fi

if $proxy_on; then
    proxy_part="${GREEN}[P]${RESET}"
else
    # Yellow warning: work environment normally requires a proxy
    proxy_part="${YELLOW}⚠️ ${RESET}"
fi

# ---------------------------------------------------------------------------
# Field 2: Model  (source: stdin .model.display_name)
# ---------------------------------------------------------------------------
model=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model" ]; then
    model_part="${MAGENTA}${model}${RESET}"
else
    model_part="${MAGENTA}model:--${RESET}"
fi

# ---------------------------------------------------------------------------
# Field 3: dir (branch*)  (source: stdin cwd + git commands)
#   Directory: last 2 path segments in cyan
#   Branch: appended as " (branch)" in cyan; dirty marker * in red
#   Skipped entirely when not inside a git repo
# ---------------------------------------------------------------------------
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
cwd="${cwd:-$(pwd)}"

# Extract last 2 path segments
dir=$(printf '%s' "$cwd" | awk -F'/' '{
    parts[0]=""; n=0
    for (i=1; i<=NF; i++) { if ($i != "") { parts[n++]=$i } }
    if (n==0)      print "/"
    else if (n==1) print parts[0]
    else           print parts[n-2] "/" parts[n-1]
}')

# Git branch + dirty check (skip optional locks via -c core.checkStat=minimal)
git_branch=""
git_dirty=false
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" -c core.checkStat=minimal symbolic-ref --short HEAD 2>/dev/null \
                 || git -C "$cwd" -c core.checkStat=minimal rev-parse --short HEAD 2>/dev/null)
    if git -C "$cwd" -c core.checkStat=minimal status --porcelain 2>/dev/null | grep -q .; then
        git_dirty=true
    fi
fi

if [ -n "$git_branch" ]; then
    if $git_dirty; then
        # branch name in cyan, dirty * in red, closing ) in cyan
        dir_part="${CYAN}${dir} (${git_branch}${RESET}${RED}*${RESET}${CYAN})${RESET}"
    else
        dir_part="${CYAN}${dir} (${git_branch})${RESET}"
    fi
else
    dir_part="${CYAN}${dir}${RESET}"
fi

# ---------------------------------------------------------------------------
# Shared helper: SI suffix formatting
# ---------------------------------------------------------------------------
_si_format() {
    local n=$1
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        printf "%.2fM" "$(echo "scale=2; $n / 1000000" | bc 2>/dev/null || echo 0)"
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc 2>/dev/null || echo 0)"
    else
        printf "%s" "$n"
    fi
}

# ---------------------------------------------------------------------------
# Field 4: Tokens + cost  (orange; source: stdin cumulative token fields + cost field)
#   Tokens: .context_window.total_input_tokens + .context_window.total_output_tokens
#   Cost:   .cost.total_cost_usd  (documented field in Claude Code statusline JSON;
#           shows $-- before any API response or if field missing)
# ---------------------------------------------------------------------------
tok_in=$(echo  "$input" | jq -r '.context_window.total_input_tokens  // empty')
tok_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Build token string
if [ -n "$tok_in" ] && [ -n "$tok_out" ]; then
    tok_total=$(( tok_in + tok_out ))
    tok_str="Tokens:$(_si_format "$tok_total")"
else
    tok_str="Tokens:--"
fi

# Build cost string
if [ -n "$cost_usd" ]; then
    # Format to 2 decimal places; use awk for portability (bc lacks printf %f on some macOS)
    cost_str=$(awk -v v="$cost_usd" 'BEGIN { printf "$%.2f", v }')
else
    cost_str='$--'
fi

tok_part="${ORANGE}${tok_str} ${cost_str}${RESET}"

# ---------------------------------------------------------------------------
# Shared helper: threshold-based color
# ---------------------------------------------------------------------------
_pct_color() {
    local pct=$1
    if [ "$pct" -ge 80 ] 2>/dev/null; then
        printf '%s' "${RED}"
    elif [ "$pct" -ge 50 ] 2>/dev/null; then
        printf '%s' "${YELLOW}"
    else
        printf '%s' "${GREEN}"
    fi
}

# ---------------------------------------------------------------------------
# Field 5: Context window progress bar  (source: stdin pre-calculated fields)
#   Format: ▓▓▓░░░░░░░ 30%
#   Color:  <50% green · 50-80% yellow · >80% red
# ---------------------------------------------------------------------------
_ctx_bar() {
    local pct=$1          # integer 0-100
    local filled=$(( pct / 10 ))
    local empty=$(( 10 - filled ))
    local bar="" i
    for i in $(seq 1 "$filled"); do bar="${bar}▓"; done
    for i in $(seq 1 "$empty");  do bar="${bar}░"; done
    printf '%s' "$bar"
}

ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$ctx_used" ]; then
    ctx_int=$(printf '%.0f' "$ctx_used")
    ctx_color=$(_pct_color "$ctx_int")
    ctx_part="${ctx_color}$(_ctx_bar "$ctx_int") ${ctx_int}%${RESET}"
else
    ctx_part="${GREEN}░░░░░░░░░░ --${RESET}"
fi

# ---------------------------------------------------------------------------
# Field 6: Rate limits  (source: stdin .rate_limits.five_hour / .rate_limits.seven_day)
#   Each limit colored independently: <50% green · 50-80% yellow · >80% red
#   Only present for Claude.ai subscribers after first API response.
# ---------------------------------------------------------------------------
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage  // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage  // empty')

_fmt_rate() {
    local pct_raw=$1
    local label=$2
    if [ -z "$pct_raw" ]; then
        printf '%b%s:--%b' "${GREEN}" "$label" "${RESET}"
        return
    fi
    local pct_int
    pct_int=$(printf '%.0f' "$pct_raw")
    local col
    col=$(_pct_color "$pct_int")
    printf '%b%s:%d%%%b' "$col" "$label" "$pct_int" "${RESET}"
}

rate_part="$(_fmt_rate "$five_pct" "5h") $(_fmt_rate "$week_pct" "7d")"

# ---------------------------------------------------------------------------
# Assemble final output
# Order: proxy | model | dir (branch) | Tokens+cost | ctx_bar | 5h+7d
# ---------------------------------------------------------------------------
printf "%b%b%b%b%b%b%b%b%b%b%b\n" \
    "${proxy_part}" \
    "${sep}" \
    "${model_part}" \
    "${sep}" \
    "${dir_part}" \
    "${sep}" \
    "${tok_part}" \
    "${sep}" \
    "${ctx_part}" \
    "${sep}" \
    "${rate_part}"
