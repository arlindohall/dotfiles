#!/bin/bash
# Capture the current Ghostty window position so we can refocus it when clicked.
# Window position is stable (unlike titles which have spinners), so we use it as identifier.
WIN_POS=$(osascript 2>/dev/null <<'ASEOF'
tell application "System Events"
  tell process "Ghostty"
    set p to position of front window
    return (item 1 of p as text) & "," & (item 2 of p as text)
  end tell
end tell
ASEOF
)

POS_FILE="$HOME/.claude/.notify-window-pos"
printf '%s' "$WIN_POS" > "$POS_FILE"

EXECUTE_SCRIPT=$(cat <<'EOEXEC'
set posFile to (POSIX path of (path to home folder)) & ".claude/.notify-window-pos"
set storedPos to do shell script "cat " & quoted form of posFile
tell application "System Events"
  tell process "Ghostty"
    set frontmost to true
    repeat with w in every window
      set p to position of w
      set wPos to (item 1 of p as text) & "," & (item 2 of p as text)
      if wPos is storedPos then
        perform action "AXRaise" of w
        exit repeat
      end if
    end repeat
  end tell
end tell
EOEXEC
)

/opt/homebrew/bin/terminal-notifier \
  -title "Claude Code" \
  -message "needs your attention" \
  -activate "com.mitchellh.ghostty" \
  -execute "osascript -e $(printf '%s' "$EXECUTE_SCRIPT" | python3 -c 'import sys,shlex; print(shlex.quote(sys.stdin.read()))')"
