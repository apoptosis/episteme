#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/episteme"
REPO_DIR=`realpath ${0%/*}`


emacs -Q \
      --eval "(setq byte-compile-warnings '(cl-functions))" \
      --eval "(setq user-emacs-directory \"$CONFIG_DIR\")" \
      --eval "(setq user-init-file \"$REPO_DIR/support.el\")" \
      --load "$REPO_DIR/support.el" \
      --debug-init
