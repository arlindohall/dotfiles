#!/usr/bin/env bash

function copy_files() {
  folder_name="$1"
  cp "$HOME/$folder_name" "$HOME/backup/"
}

function backup() {
  mkdir -p "$HOME/backup"

  copy_files var
  copy_files workspace
  copy_files Documents

  # shellcheck disable=SC2164
  cd "$HOME/backup"

  zip -r Archive.zip var workspace Documents
}
