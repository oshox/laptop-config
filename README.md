# laptop-config

Per-user configuration (dotfiles, `~/.config`, a few `~/.local` bits) for a
Fedora Atomic / sway laptop. The OS image itself is built by
[laptop-setup](https://github.com/oshox/laptop-setup); this repo holds only
what lives in `$HOME`.

Files under `home/` are a **scrubbed copy**, not symlinks: personal values are
replaced by placeholders so the repo can be public.

| Placeholder        | Filled from                         |
|--------------------|-------------------------------------|
| `@HOME@`           | install target (default `$HOME`)    |
| `@USER@`           | `id -un`                            |
| `@GIT_NAME@`       | `GIT_NAME`                          |
| `@GIT_EMAIL@`      | `GIT_EMAIL`                         |
| `@WTTR_LOCATION@`  | `WTTR_LOCATION` (waybar weather)    |

## Usage

```sh
# save values once (untracked)
cat > ~/.config/laptop-config.env <<'X'
GIT_NAME=you
GIT_EMAIL=you@users.noreply.github.com
WTTR_LOCATION=London
X

./install.sh --dry-run    # preview; existing files are kept as *.pre-install
./install.sh

./capture.sh              # pull current ~ back into home/, scrub, pii-check
```

- `include.txt` / `exclude.txt` — what gets captured.
- `scrub.sed` — PII → placeholder rules.
- `pii-check.sh` — fails on usernames, emails, tokens, keys, LAN IPs and image
  metadata. Add private terms (real name, zip code, hostname…) one per line to
  `~/.config/laptop-config.pii`.

## Not included

Secrets/state (`.ssh`, `gh/hosts.yml`, browser profiles, Deluge auth/web
config, histories, caches) and third-party binaries in `~/.local/bin`
(`uv`/`uvx`, `ruff`, `tea`, `wttrbar`, `mount-s3`, `agy`, …) — install those
from upstream.
