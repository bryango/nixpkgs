/**
  Convert the reference graph for derivations in `rootPaths` into a
  "references.json" file, excluding self-references. This is achieved with
  `__structuredAttrs` and depends on the `jq` command-line JSON processor.

  This package is built for the `replaceDependencies` utility. Similar
  functionalities are also provided by the `closureInfo` package.

  # Example

  ```nix
  with pkgs; closureJson { rootPaths = [ hello bash ]; }
  ```

  This builds a `/nix/store/aa8l97wg3pg7k55h4vnhp3qmjrciz9r8-references.json`
  in store with the following content:

  ```json
  {
    "/nix/store/5l50g7kzj7v0rdhshld1vx46rf2k5lf9-bash-5.2p26": [
      "/nix/store/cyrrf49i2hm1w7vn2j945ic3rrzgxbqs-glibc-2.38-44"
    ],
    "/nix/store/63l345l7dgcfz789w1y93j1540czafqh-hello-2.12.1": [
      "/nix/store/cyrrf49i2hm1w7vn2j945ic3rrzgxbqs-glibc-2.38-44"
    ],
    "/nix/store/83p2f8svzmaq38xy1al0issan2ww1wb9-libidn2-2.3.7": [
      "/nix/store/8xqsi87qd3p2hxrm0jmha03b9bxinlil-libunistring-1.1"
    ],
    "/nix/store/8xqsi87qd3p2hxrm0jmha03b9bxinlil-libunistring-1.1": [],
    "/nix/store/cyrrf49i2hm1w7vn2j945ic3rrzgxbqs-glibc-2.38-44": [
      "/nix/store/83p2f8svzmaq38xy1al0issan2ww1wb9-libidn2-2.3.7",
      "/nix/store/f5my15qww10swmf66ns13l24yp6j5dmq-xgcc-13.2.0-libgcc"
    ],
    "/nix/store/f5my15qww10swmf66ns13l24yp6j5dmq-xgcc-13.2.0-libgcc": []
  }
  ```
*/

{ lib
, jq
, runCommandLocal
}:

{ rootPaths }:

assert builtins.langVersion >= 5;

runCommandLocal "references.json"
{
  __structuredAttrs = true;
  exportReferencesGraph.closure = rootPaths;
  nativeBuildInputs = [ jq ];
  empty = rootPaths == [ ];
}
  ''
    if [[ -n "$empty" ]]; then
      # handle an empty input gracefully; see also `pkgs.closureInfo`.
      echo "{}" > $out
    else
      jq -r '[ .closure[] | .path as $path | { (.path): [ .references[] | select(. != $path ) ] } ] | add' \
        < "$NIX_ATTRS_JSON_FILE" > $out
    fi
  ''
