# dotfiles

Plain [GNU stow](https://www.gnu.org/software/stow/) packages and a Brewfile.

## Install

```sh
git clone https://github.com/freethinkel/dotfiles ~/Developer/infra/dotfiles
make -C ~/Developer/infra/dotfiles
```

On macOS Homebrew must be installed.
On plain Arch (`ID=arch`, no Omarchy) it runs `pacman -Syu --needed` over `arch.pkgs`, enables NetworkManager, power-profiles-daemon and fstrim,
and also links `ghostty` and `niri`; logging in on tty1 then starts `niri-session` (from `niri/.zprofile`).
On Omarchy and Asahi the CLI tools come from pacman.
On any Linux the configs already there are moved to `*.bak`.
On other Linux (x86_64 servers) only the CLI packages are linked,
and the tools are fetched as release binaries into `~/.local/bin`, no sudo; git, stow, zsh, tmux and nvim come from the system.
The clone can live anywhere.
`make` (`scripts/install.sh`) is safe to run again after every pull. On macOS it does this:

- runs `brew bundle`, installs the IoskeleyMono font and sets a few `defaults`
- links `~/.dotfiles` to the clone (for configs that can't find it themselves, like `.skhdrc`)
- stows every package, clones tpm, starts skhd and OmniWM
- applies `snowfall-dark` on the first run, and only relinks the current theme after that

A tap brew doesn't trust yet (like `leoafarias/fvm`) fails `brew bundle` until you run `brew trust <tap>`; the rest of the install goes on.

If an app replaced one of the symlinks with a real file, stow stops with a conflict.
Move that file away and run it again.

## Editing

Everything in `$HOME` links back here, so editing a file in the repo changes the live config.
To add a package, make a dir that mirrors `$HOME`, like `foo/.config/foo/config`,
and add `foo` to `PACKAGES` in `scripts/install.sh`.

## Layout

| path | what |
|---|---|
| `<package>/` | stow package, mirrors `$HOME` |
| `arch.pkgs` | pacman packages for plain Arch, the Brewfile of the T14 |
| `bin/` | scripts like `theme` and `wallpaper`, added to `PATH` in `.zshrc` |
| `scripts/` | `install.sh`, `bt-trackpad.sh` (Magic Trackpad pairing shared with Asahi), run through `make`; not a stow package |
| `themes/` | palettes and templates for `theme set <name>`, downloaded ones are gitignored |
| `.env` | secrets, gitignored |

## Themes

`theme set <name>` renders `themes/templates` into `~/.config/theme` and points the apps at it.
`theme link` redoes the links without rendering.
`theme install <git-url>` clones an Omarchy theme into `themes/`, moves its backgrounds to the wallpaper folder and applies it.

## Wallpaper

Wallpapers live in `~/Pictures/wallpapers/<theme>/`, outside git.
`wallpaper next` cycles through the folder for the current theme, `wallpaper set <path>` sets one image.
