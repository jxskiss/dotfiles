# dotfiles

https://www.chezmoi.io/

https://github.com/twpayne/chezmoi/

## mac setup

Setup homebrew and pip source mirror

```bash
# Setup mirrors
curl -fsSL https://raw.githubusercontent.com/jxskiss/dotfiles/master/dot_proxy_env > ~/.proxy_env
source ~/.proxy_env

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
source ~/.proxy_env
[[ -s "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
/bin/bash brew-install/install.sh
rm -rf brew-install

# Install essential packages
brew install coreutils wget htop \
  powerlevel10k zsh-autosuggestions zsh-syntax-highlighting \
  fish chezmoi ripgrep gojq caddy pandoc \
  mise uv go

# fix: omz_urlencode:5: command not found: pygmentize
# fix: zsh: command not found: pygmentize
brew install pygments
```

Install and configure Xray-core

See [https://github.com/jxskiss/xray-config-files]()


Install oh-my-zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Apply chezmoi dotfiles

```bash
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
