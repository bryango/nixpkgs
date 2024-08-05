{ callPackage, lib, overrideCC, pkgs, buildPackages, openssl, python311, fetchpatch, enableNpm ? true }:

let
  # Clang 16+ cannot build Node v14 due to -Wenum-constexpr-conversion errors.
  # Use an older version of clang with the current libc++ for compatibility (e.g., with icu).
  ensureCompatibleCC = packages:
    if packages.stdenv.cc.isClang && lib.versionAtLeast (lib.getVersion packages.stdenv.cc.cc) "16"
      then overrideCC packages.llvmPackages_15.stdenv (packages.llvmPackages_15.stdenv.cc.override {
        inherit (packages.llvmPackages) libcxx;
        extraPackages = [ packages.llvmPackages.libcxxabi ];
      })
      else packages.stdenv;

  buildNodejs = callPackage ./nodejs.nix {
    inherit openssl;
    stdenv = ensureCompatibleCC pkgs;
    buildPackages = buildPackages // { stdenv = ensureCompatibleCC buildPackages; };
    /** pin python to python311, fixes:
      Node.js configure: Found Python 3.12.4...
      Please use python3.11 or python3.10 or python3.9 or python3.8 or python3.7 or python3.6.
    */
    python = python311;
  };

  npmPatches = callPackage ./npm-patches.nix { };
in
  (buildNodejs {
    inherit enableNpm;
    # If you do upgrade here, please update in pkgs/top-level/release.nix
    # the permitted insecure version to ensure it gets cached for our users
    # and backport this to stable release (23.05).
    version = "16.20.2";
    sha256 = "sha256-V28aA8RV5JGo0TK1h+trO4RlH8iXS7NjhDPdRNIsj0k=";
    patches = [
      ./disable-darwin-v8-system-instrumentation.patch
      ./bypass-darwin-xcrun-node16.patch
      ./node-npm-build-npm-package-logic-node16.patch
    ] ++ npmPatches;
  }).overrideAttrs ({ checkTarget ? "", ... }: {
    /** disable flaky tests; see e.g.
      https://github.com/NixOS/nixpkgs/commit/d25d9b6a2dc90773039864bbf66c3229b6227cde
    */
    checkTarget = lib.replaceStrings [ "test-ci-js" ] [ "" ] checkTarget;
  })
