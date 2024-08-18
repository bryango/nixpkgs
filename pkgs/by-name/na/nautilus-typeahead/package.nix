{ callPackage }:

let
  patch = callPackage ./patch.nix {};
in

with builtins; trace (readFile "${patch}") patch
