---
name: morning-coffee
description: Use when the user says "good morning" or asks for a morning briefing. Gathers GitHub, Google Docs, and Slack activity to provide a summary of yesterday's work, overnight activity (after 3:30 PM EST), and the top 3 priorities for today.
---

# Morning Coffee

Daily briefing that pulls together your GitHub, Google Workspace, and Slack activity.

## What This Skill Produces

1. **Top 3 Priorities for Today** — Based on calendar events, open PRs needing attention, unread messages, and pending work
2. **Yesterday's Work Rollup** — What you accomplished across all three platforms
3. **Overnight Activity** — Messages, PR reviews, comments, and updates after 3:30 PM EST

## Execution Steps

### Step 1: Determine Time Boundaries

```bash
# Get timestamps for queries
# "Yesterday" = previous calendar day
# "Overnight" = after 3:30 PM EST yesterday until now
```

Use these time boundaries:
- **Yesterday start**: Previous calendar day 00:00 EST
- **Signoff time**: Previous calendar day 15:30 EST (3:30 PM)
- **Now**: Current time

### Step 2: Gather GitHub Activity

GitHub username: `arlindohall`

```bash
# Notifications (unread and recent)
gh api notifications --jq '.[] | {reason, subject: .subject.title, repo: .repository.full_name, updated_at}'

# PRs you authored (open)
gh pr list --author @me --state open --json title,url,updatedAt,reviewDecision,reviews

# PRs requesting your review
gh pr list --search "review-requested:@me" --state open --json title,url,author,createdAt

# Your recent PR activity (merged/closed yesterday)
gh pr list --author @me --state merged --json title,url,mergedAt --limit 20

# Issues assigned to you
gh issue list --assignee @me --state open --json title,url,updatedAt

# Recent notifications (to catch overnight activity)
gh api notifications?all=true --jq '.[] | select(.updated_at > "SIGNOFF_TIMESTAMP") | {reason, title: .subject.title, repo: .repository.full_name}'
```

### Step 3: Gather Google Workspace Activity

Use the gworkspace CLI at `~/.claude/skills/gworkspace/cli.js`.

```bash
# Today's calendar events (priorities)
node ~/.claude/skills/gworkspace/cli.js calendar-events --time-min "TODAY_START" --time-max "TODAY_END" --include-attendees true

# Recent email (overnight)
node ~/.claude/skills/gworkspace/cli.js read-mail --query "after:YESTERDAY" --max-results 20

# Recent Drive activity (files you touched yesterday)
node ~/.claude/skills/gworkspace/cli.js search-drive --query "modifiedTime > 'YESTERDAY_START'"
```

### Step 4: Gather Slack Activity

Use the agent-slack-read CLI.

```bash
# Direct messages and mentions after signoff
agent-slack-read search "to:me after:SIGNOFF_DATE" --limit 30 --json channel,channelName,user,text,permalink,ts

# Messages in channels you're active in (use specific channels if known)
agent-slack-read search "from:me during:yesterday" --limit 20 --json channel,channelName,text,permalink,ts
```

### Step 5: Synthesize the Briefing

After gathering all data, produce a briefing with three sections:

#### Format

```markdown
# ☕ Good Morning!

## 🎯 Top 3 Priorities Today

1. **[Priority 1]** — [Why this is important, source]
2. **[Priority 2]** — [Why this is important, source]
3. **[Priority 3]** — [Why this is important, source]

## 📝 Yesterday's Rollup

### GitHub
- [PRs merged, reviewed, issues closed]

### Google Workspace
- [Docs edited, meetings attended]

### Slack
- [Key conversations, decisions made]

## 🌙 Overnight Activity (after 3:30 PM EST)

### Needs Response
- [DMs, mentions, PR reviews requesting action]

### FYI
- [Updates, notifications that don't need immediate action]
```

## Priority Determination Logic

Rank priorities by:
1. **Calendar**: Meetings in the next 4 hours, especially 1:1s or with external attendees
2. **PR reviews requested**: Others are blocked waiting on you
3. **Unread DMs/mentions**: Direct requests for your attention
4. **Open PRs with feedback**: Your PRs that have new reviews
5. **Deadlines**: Issues or calendar items with due dates today

## Notes

- All times use EST (America/New_York timezone)
- Signoff time is 3:30 PM EST
- If a service fails, note it and continue with available data
- Keep the summary scannable — link to details rather than inline everything
