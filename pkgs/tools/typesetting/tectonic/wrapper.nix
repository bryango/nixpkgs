{ lib
, tectonic
, biber
, fetchFromGitHub
, fetchpatch
}:

let

  /*
    The version locked tectonic web bundle, redirected from:
      https://relay.fullyjustified.net/default_bundle_v33.tar
    To check for updates: look up `get_fallback_bundle_url` from:
      https://github.com/tectonic-typesetting/tectonic/blob/master/crates/bundles/src/lib.rs
  */
  TECTONIC_WEB_BUNDLE_LOCKED = "https://data1.fullyjustified.net/tlextras-2022.0r0.tar";

  # The version of biber compatible with the above tectonic bundle
  version = "2.17";

  /*
    `biber-for-tectonic` provides a compatible version of `biber`
    as an optional runtime dependency of `tectonic`.

    The development of tectonic is slowing down recently, such that its `biber`
    dependency has been lagging behind the one in the nixpkgs `texlive` bundle.
    See:

    https://github.com/tectonic-typesetting/tectonic/discussions/1122

    It is now feasible to track the biber dependency in nixpkgs, as the
    version bump is not very frequent, and it would provide a more complete
    user experience of tectonic in nixpkgs.
  */
  biber-for-tectonic = (biber.override {
    /*
      It is necessary to first override the `version` data here, which is
      passed to `buildPerlModule`, and then to `mkDerivation`.

      If we simply do `biber.overrideAttrs` the resulting package `name`
      would be incorrect, since it has already been preprocessed by
      `buildPerlModule`.
    */
    texlive.pkgs.biber.texsource = {
      inherit version;
      inherit (biber) pname meta;
    };
  }).overrideAttrs (prevAttrs: {
    src = fetchFromGitHub {
      owner = "plk";
      repo = "biber";
      rev = "v${version}";
      hash = "sha256-Tt2sN2b2NGxcWyZDj5uXNGC8phJwFRiyH72n3yhFCi0=";
    };
    patches = [
      # Perl>=5.36.0 compatibility
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/plk/biber/pull/411.patch";
        hash = "sha256-osgldRVfe3jnMSOMnAMQSB0Ymc1s7J6KtM2ig3c93SE=";
      })
    ];
    meta = prevAttrs.meta // {
      maintainers = with lib.maintainers; [ bryango ];
    };
  });

in

tectonic.overrideAttrs (prevAttrs: {

  pname = "tectonic-with-biber";

  # this wrapper is versioned by the biber package
  inherit version;

  patches = (prevAttrs.patches or [ ]) ++ [
    # allow locked version of the tectonic web bundle for reproducible builds
    # by specifying the env variable `TECTONIC_WEB_BUNDLE_LOCKED`
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/tectonic-typesetting/tectonic/pull/1131.patch";
      hash = "sha256-u+klJxEOZ4mB6whil/b2QqWkpgThAOH2grS6LXA8bm4=";
    })
  ];
  inherit TECTONIC_WEB_BUNDLE_LOCKED;

  passthru = { biber = biber-for-tectonic; };

  meta = prevAttrs.meta // {
    description = "Tectonic, wrapped with the correct biber version";
    longDescription = ''
      This package wraps tectonic with a compatible version of biber.
      The tectonic web bundle is pinned to ensure reproducibility.
      This serves as a downstream fix for:
      - https://github.com/tectonic-typesetting/tectonic/issues/893
    '';
    maintainers = with lib.maintainers; [ bryango ];
  };

  # tectonic runs biber when it detects it needs to run it, see:
  # https://github.com/tectonic-typesetting/tectonic/releases/tag/tectonic%400.7.0
  postInstall = ''
    wrapProgram $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber-for-tectonic}/bin"
  '' + (prevAttrs.postInstall or "");

})
