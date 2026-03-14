#!/usr/bin/env bash
# Usage: commit-info.sh [ref]
# Prints structured commit metadata: hash, author, date, subject, body.
# Defaults to HEAD.
set -euo pipefail
ref="${1:-HEAD}"
git log --format="hash:    %H
author:  %an <%ae>
date:    %ad
subject: %s
---body---
%b" "${ref}~1..${ref}"
