# Dotfiles and Install Scripts

## Summary

These are all my configuration files, plus a handful of scripts that install them on a fresh computer.
Any dependencies that these files reference are also installed by the install scripts.

The install scripts use `helpers.sh` for shared or helper functions, so the scripts have to be run from this directory (to avoid any annoying manipulation of the path).
The `dependencies-install.sh` script really only needs to be run once for each new VM or system.

## Contents

- `bin`: little helper programs I like to have on each machine
- `install.sh`: installs dotfiles, meant to be run very quickly
- `helpers.sh`: just defines functions, no actions
- `dependencies-install.sh`: sometimes downloads items, calls other programs, can be slow
- dotfiles: each dotfile is named after the program it's for

## Note: Bookmarklets

These would be really cool as scripts, but I don't know how to script creating bookmarks in Google Chrome.
Maybe I'll make them into a bookmark import file later.

Each one is a javascript bookmarklet to transform a google document or sheet.

### Preview

```
javascript:window.location.host.includes('google.com')&&window.location.assign(window.location.href.replace(/edit|copy/, 'preview'))
```
### Preview as PDF

```
javascript:((window.location.href.includes('google.com/drawings')||window.location.href.includes('google.com/presentation'))&&window.location.assign(window.location.href.replace(/(edit|preview|copy).*/, 'export/pdf')))||((window.location.host.includes('docs.google.com')||window.location.host.includes('sheets.google.com'))&&window.location.assign(window.location.href.replace(/(edit|preview|copy).*/, 'export?format=pdf%27)))
```

### Copy

```
javascript:window.location.host.includes('google.com')&&window.location.assign(window.location.href.replace(/(edit|preview).*/, 'copy'))
```

### Copy with Comments

```
javascript:window.location.host.includes('google.com')&&window.location.assign(window.location.href.replace(/(edit|preview).*/, 'copy?copyComments=true%27))
```

### Create Template

```
javascript:window.location.host.includes('google.com')&&window.location.assign(window.location.href.replace(/(edit|copy|preview).*/, 'template/preview'))
```

Scripts based on the comment found below:

https://support.google.com/docs/thread/14614410/send-a-link-that-will-open-a-google-doc-in-view-mode-even-if-the-recipient-has-the-rights-to-edit?hl=en

```
Jim@Work
Original Poster
Sep 18, 2019
After some more searching I found the solution here:
https://learninginhand.com/blog/google-document-url-tricks

To make a link open in:
Preview mode: → Replace /edit with /preview
Force a copy: → Replace /edit with /copy
Force a copy with comment: → Replace /edit with /copy?copyComments=true
Create a template: → Replace /edit with /template/preview
In PDF:  → Google Docs & Sheets: Replace /edit with /export?format=pdf
→ Google Slides & Drawings: Replace /edit with /export/pdf
Original Poster Jim@Work marked this as an answer
```


