#!/usr/bin/env bash

FOLDER_EXCLUDE_HIDDEN_REGEX="Trash|gem|rm-trash-can|local|android|pyenv|rvm-old|minikube|nvm|rbenv|gradle|rustup|cargo|npm|cache|dev"
FOLDER_EXCLUDE_REGEX="^(Library|Movies|Pictures|Support|Google Drive|src|backup|go|\.|\.($FOLDER_EXCLUDE_HIDDEN_REGEX|\.))$"

function files_for_backup() {
  ls -a | rg -v "$FOLDER_EXCLUDE_REGEX"
}

function file_sizes() {
  files_for_backup |
    xargs du -hs | # Human readable, summary
    sort -hrb      # Human readable, reverse, ignore leading spaces for sorting
}

function backup() {
  cd
  mkdir -p "backup"

  zip -r "backup/Archive.zip" $(files_for_backup)
}
