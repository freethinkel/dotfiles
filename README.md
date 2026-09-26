# dotfiles

Plain [GNU stow](https://www.gnu.org/software/stow/) packages + a Brewfile. No nix, no slicker.

```sh
git clone https://github.com/freethinkel/dotfiles ~/Developer/infra/dotfiles
~/Developer/infra/dotfiles/install.sh
```

`install.sh` (re-runnable):

- macOS: `brew bundle`, the IoskeleyMono font, a few `defaults write`
- `stow` the packages into `$HOME`: terminal ones everywhere, desktop ones on macOS
- applies `snowfall-dark` on the first run

Edit files here, they are live (symlinks). New package: a dir that mirrors `$HOME`,
e.g. `foo/.config/foo/config`, then add `foo` to `PACKAGES` in `install.sh`.

| path | what |
|---|---|
| `<package>/` | stow package, mirrors `$HOME` |
| `bin/` | scripts, on `PATH` via `.zshrc` (`theme`, `wallpaper`, …) |
| `themes/` | palettes + templates for `theme set <name>` (downloaded ones are gitignored) |
| `niri/`, `waybar/`, `quickshell/` | linux desktop, not stowed by default |
| `.env` | secrets, gitignored |

Themes: `theme set <name>` renders `themes/templates` into `~/.config/theme` and links apps to it;
`theme link` only redoes the links.
