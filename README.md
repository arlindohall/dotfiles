# Dotfiles and Install Scripts

## Summary

These are all my configuration files, plus a handful of scripts that install them on a fresh computer.
Any dependencies that these files reference are also installed by the install scripts.

The install scripts use `rc_helpers.sh` or `dependencies_helpers.sh` for helper functions, but each helper detects where the script was run from to avoid path issues.
That said, the scripts should be located in `~/dotfiles` or `~/workspace/dotfiles`, which make sense if you've just cloned the repo to a new machine, or if you're working on the files, respectively.
The `dependencies-install.sh` script really only needs to be run once for each new VM or system.

## Contents

- `bin`: little helper programs I like to have on each machine
- `setup-server.sh`: run this first on a new server, sets up my user to get ready for other installs
  - Once this has been run, run the other two scripts as user instead of root
- `install.sh`: installs dotfiles, meant to be run very quickly
- `lib/*helpers.sh`: just defines functions, no actions
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

### Edit

```
javascript:window.location.host.includes('google.com')&&window.location.assign(window.location.href.replace(/preview|copy/, 'edit'))
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


