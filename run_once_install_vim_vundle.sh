#!/bin/sh

if [ -d "$HOME/.vim/bundle/Vundle.vim" ]; then
    cd $HOME/.vim/bundle/Vundle.vim && git pull --ff-only origin master
else
    mkdir -p $HOME/.vim/bundle/Vundle.vim
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi
