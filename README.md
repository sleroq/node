# node

Short flake aliases for Node.js versions built from [`nficca/nix-anynode`](https://github.com/nficca/nix-anynode).

## Usage

With `direnv`:

```sh
echo 'use flake github:sleroq/node#24_14_1' > .envrc
direnv allow
node --version
```

Without `direnv`:

```sh
nix develop github:sleroq/node#24_14_1 -c node --version
```

## Alias format

- Exact versions use underscores instead of dots:
  - `24_14_1` -> `v24.14.1`
  - `0_10_48` -> `v0.10.48`
- Minor aliases resolve to the latest patch in that minor line from the current lockfile:
  - `24_14` -> currently `v24.14.1`
- Major aliases resolve to the latest version in that major from the current lockfile:
  - `14` -> currently `v14.21.3`
  - `24` -> currently `v24.14.1`
- `lts` resolves to the newest LTS release line available in the current lockfile:
  - `lts` -> currently `v24.14.1`

## Examples

```sh
use flake github:sleroq/node#24_14_1
use flake github:sleroq/node#24_14
use flake github:sleroq/node#14
use flake github:sleroq/node#lts
use flake github:sleroq/node#0_10_48
```

## Notes

- Available aliases depend on the current system and what `nix-anynode` provides for that platform.
- Older versions like `0_10_48` are available on `x86_64-darwin` and `x86_64-linux`, but not on `aarch64-darwin`.
