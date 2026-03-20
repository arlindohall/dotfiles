#!/usr/bin/env bash

cargo build
cp target/debug/agent-progress $HOME/bin/
