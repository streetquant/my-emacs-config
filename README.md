# my-emacs-config

A minimal, fast Emacs setup focused on **Org mode + LaTex + journaling**, while keeping a strong navigation and completion workflow.

## What This Config Provides

- Minimal startup profile (only essential modules are loaded)
- Automatic package setup via `package.el` + MELPA
- UTF-8 locale defaults and shell `PATH` import
- Startup performance tuning (`gcmh`, larger process read buffers)

### Org + LaTex + Journal

- Org core editing defaults
- Org link and agenda shortcuts
- Org Journal support (`org-journal`)
- LaTex fragment preview process auto-selection (`dvisvgm` preferred, fallback to `dvipng`)
- Org Babel enabled for:
  - `emacs-lisp`
  - `latex`
  - `shell`
- ODT export preference set to `docx`

### Completion and Search

- Minibuffer completion stack:
  - `vertico`
  - `consult`
  - `marginalia`
  - `embark`
  - `orderless`
- In-buffer completion (`corfu` + terminal support when available)
- Better search UX:
  - `anzu` match counts/replacements
  - enhanced isearch helpers
  - `consult-line` from isearch
  - ripgrep shortcut (`M-?`) when `rg` is installed

### Navigation and Windows

- `switch-window` for `C-x o`
- Winner mode (undo/redo window layouts)
- Enhanced split behavior for `C-x 2` / `C-x 3`
- Fast buffer navigation using `C-x <left>` / `C-x <right>`
- Repeat behavior enabled so arrow navigation can continue briefly after one `C-x` sequence
- Windmove + windswap on non-Windows systems

### File/Buffers

- Dired improvements (`diredfl`, wdired key, jump shortcuts)
- VC-aware ibuffer groups (`ibuffer-vc`)
- Human-readable ibuffer size column
- Recent files tracking (`recentf`)
- Better duplicate buffer naming (`uniquify`)

### UI / Look and Feel

- Theme setup from `color-theme-sanityinc-*`
- Light/dark theme switching helpers (`M-x light`, `M-x dark`)
- Optional dimming support (`dimmer`)
- GUI cleanup: no splash, no toolbar/scrollbar/menu
- Easy global text scaling (`default-text-scale`)
- Mouse disable helper package loaded (`disable-mouse`)
- Your current font and theme customizations stay in `custom.el`

### Persistence and Session State

- Restore open buffers/windows across restarts (`desktop-save-mode`)
- Persist command/search/file history (`savehist-mode`)
- Restore cursor position per file (`save-place-mode`)

### Clipboard and Utilities

- Selected region auto-copies to system clipboard
- `M-/` bound to `hippie-expand`
- `ai-cleaner` loaded for text cleanup commands

## Important Keybindings

- `C-x b` -> `switch-to-buffer`
- `C-x c` -> quit Emacs (`save-buffers-kill-terminal`)
- `C-x <left>` / `C-x <right>` -> previous/next buffer
- `C-c <left>` / `C-c <right>` -> winner undo/redo window layout
- `C-x o` -> `switch-window`
- `C-x C-b` -> `ibuffer`
- `M-?` -> ripgrep at point (when `rg` exists)
- `C-c l` -> `org-store-link`
- `C-c a` -> `org-agenda`
- `C-c j` -> `org-journal-new-entry`
- `C-h` -> `delete-backward-char`

## Requirements

- Emacs `27.1+`
- Recommended external tools:
  - `rg` (ripgrep)
  - LaTex toolchain (`dvisvgm` or `dvipng`, plus TeX distribution)

## Install

```bash
git clone https://github.com/streetquant/my-emacs-config.git ~/.emacs.d
```

Start Emacs once and packages will be installed automatically as needed.

## Package Management

You can install any package:

1. `M-x package-refresh-contents`
2. `M-x package-install RET <package-name> RET`

Installed packages are tracked in `custom.el` under `package-selected-packages`.

## Notes

- Local overrides can be added in:
  - `lisp/init-preload-local.el` (early)
  - `lisp/init-local.el` (late)
- `custom.el` is used for Customize-managed settings.
