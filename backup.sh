#!/usr/bin/env bash

FOLDER_EXCLUDE_REGEX="^(Library|Support|Google Drive|src|Archive.zip|\.|\.(Trash|gem|rm-trash-can|local|android|pyenv|rvm-old|minikube|nvm|rbenv|gradle|rustup|backup|\.))$"

function files_for_backup() {
  ls -a | rg -v "$FOLDER_EXCLUDE_REGEX"
}

function file_sizes() {
  files_for_backup |
    xargs du -hs |  # Human readable, summary
    sort -hrb       # Human readable, reverse, ignore leading spaces for sorting
}

function backup() {
  cd
  mkdir -p "backup"

  echo zip -r "backup/Archive.zip" $(files_for_backup)
}
