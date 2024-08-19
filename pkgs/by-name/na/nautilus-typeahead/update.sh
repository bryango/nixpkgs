#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages git pacman nix
# shellcheck shell=bash
##
## Automatic `updateScript` for `patch.nix` of `nautilus-typeahead`
##
## Available flags:
##   `--fake`: fake `version` and `rev` for debug testing
##   `--dry-run`: do not write to the actual target
##

set -eo pipefail
set -x

REGEX_REV='[a-f0-9]+'

init_dir=$(realpath "$(dirname "$0")")
tmp_dir=$(mktemp -d)
cd "$tmp_dir"

git clone --filter=blob:none https://aur.archlinux.org/nautilus-typeahead.git
cd nautilus-typeahead

## pacman's `makepkg` generates normalized source info
## from the package definitions
makepkg --printsrcinfo > .SRCINFO

read_src_info() {
  local key=$1
  sed --silent -E s/$'\t'"$key = (.*)$/\1/p" .SRCINFO
}
pkgver=$(read_src_info pkgver | head -1)
pkgrel=$(read_src_info pkgrel | head -1)

version="$pkgver-$pkgrel"
rev=$(read_src_info source \
  | sed --silent -E "s|.*albertvaka/nautilus.*commit=($REGEX_REV)$|\1|p" \
  | head -1)

rm -rf "$tmp_dir"
cd "$init_dir"

dry_run=
if [[ "$1" == "--fake" ]]; then
  version=fakeVersion
  rev=fakeRev
  dry_run=1
  shift
fi
if [[ "$1" == "--dry-run" ]]; then
  dry_run=1
fi

new_file=$(sed -E "
  s/(^\s*version\s*=\s*\")(.*)(\".*)$/\1$version\3/;
  s/(^\s*rev\s*=\s*\")($REGEX_REV)(\".*)$/\1$rev\3/;
  s/(^\s*outputHash\s*=)(.*)$/\1 lib.fakeHash;/;
" patch.nix)

set +x -v

package_expr() {
  local pkg=$1
  echo "with import <nixpkgs> {}; callPackage ($pkg) {}"
}
package=$(package_expr "$new_file")

test_instantiate() {
  nix-instantiate --eval --expr "$package" --attr "$@"
}
[[ $(test_instantiate "version") == "\"$version\"" ]]
[[ $(test_instantiate "rev") == "\"$rev\"" ]]

set +v

test_build=$(nix-build --expr "$package" 2>&1 || true)
echo "$test_build" >&2

outputHash=$(
  sed --silent -E 's/.*got:\s*(sha256-.*=)\s*$/\1/p' <<< "$test_build" \
  | head -1
)
echo "outputHash: $outputHash" >&2

hashed_file=$(sed -E "
  s|(^\s*outputHash\s*=)(.*)$|\1 \"$outputHash\";|
" <<< "$new_file")
## ^ note that here we must use `s|..|..|` instead of `s/../../`
## because "$outputHash" may contain `/`

nix-build --expr "$(package_expr "$hashed_file")" --no-out-link

if [[ -z "$dry_run" ]]; then
  echo "$hashed_file" > patch.nix
fi
