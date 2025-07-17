# dotfiles

https://www.chezmoi.io/

https://github.com/twpayne/chezmoi/

## mac setup

Setup homebrew and pip source mirror

```bash
cat > ~/.shell_env<< EOF
# Set non-default Git remotes for Homebrew/brew and Homebrew/homebrew-core.
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
[[ -s "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
EOF

# Set pip using thinghua mirror
mkdir -p ~/.config/pip ~/.config/uv
cat > ~/.config/pip/pip.conf<< EOF
[global]
index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
EOF
cat > ~/.config/uv/uv.toml<< EOF
[[index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/"
default = true
EOF
```

Install homebrew and essential packages

```bash
# Install homebrew
source ~/.shell_env
git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
/bin/bash brew-install/install.sh
rm -rf brew-install

# Install essential packages
brew install coreutils wget htop
brew install zsh-autosuggestions zsh-completions zsh-syntax-highlighting
brew install fish pandoc ripgrep
brew isntall go gojq caddy
brew install uv
# fix: omz_urlencode:5: command not found: pygmentize
# fix: zsh: command not found: pygmentize
brew install pygments
```

Install and configure v2ray

```bash
brew tap v2raya/v2raya
brew install v2raya

# run on terminal
v2raya --lite

# run as a brew service
brew services start v2raya
```

Install oh-my-zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Apply chezmoi dotfiles

```bash
brew install chezmoi
chezmoi init --apply jxskiss
```

More development tools

```bash
# bun, for macOS, Linux, and WSL
curl -fsSL https://bun.sh/install | bash

# python and IPython
uv python install --default --preview 3.13
uv pip install --system --break-system-packages ipython numpy pandas matplotlib duckdb
```
