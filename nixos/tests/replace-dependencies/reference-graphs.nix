/**
  Test that the JSON reference graph reproduces the desired set of references,
  same as the legacy implementation with plain texts gymnastics in bash, which
  is moved here from previous versions of `replace-dependencies.nix`.
*/
{ lib
, jq
, runCommandLocal
, closureReferences
}:

drv:

let
  /**
    Convert the reference graph into a nix expression, excluding self-
    references of dependencies. This is the legacy implementation moved
    from previous versions of `replace-dependencies.nix`.
  */
  referencesNix = drv:
    runCommandLocal "references.nix"
      { exportReferencesGraph = [ "graph" drv ]; }
      ''
        (echo {
        while read path
        do
            echo "  \"$path\" = ["
            read newline_separator
            read count
            while [ "0" != "$count" ]
            do
                read ref_path
                if [ "$ref_path" != "$path" ]
                then
                    echo "    \"$ref_path\""
                fi
                count=$(($count - 1))
            done
            echo "  ];"
        done < graph
        echo }) > $out
      '';

  # These are import from derivations which need to be run in a NixOS test,
  # because Hydra cannot do IFDs:
  legacyNix = import (referencesNix drv).outPath;

  # This is the new implementation supplied by the `closureReferences` package
  jsonDrv = closureReferences { rootPaths = [ drv ]; };
  jsonNix = with builtins; lib.pipe jsonDrv.outPath [
    readFile
    unsafeDiscardStringContext
    # ^ necessary to avoid store path referencing complaints from nix
    fromJSON
  ];

in
assert legacyNix == jsonNix; jsonDrv
