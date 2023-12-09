{ lib
, tectonic
, biber
, fetchFromGitHub
, fetchpatch
}:

let

  version = "2.17";

  /*
    `biber-for-tectonic` provides an alternative version of `biber`
    as an optional runtime dependency of `tectonic`.

    The development of tectonic has slowed down recently, such that its `biber`
    dependency has been lagging behind the one in the nixpkgs `texlive` bundle.
    See:

    https://github.com/tectonic-typesetting/tectonic/discussions/1122

    It is now feasible to track this dependency in nixpkgs, as the biber
    version bump is not so frequent, and it would provide a more complete user
    experience of tectonic in nixpkgs.
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

  # the wrapper is versioned by the biber package
  inherit version;

  patches = (prevAttrs.patches or [ ]) ++ [
    # pin the tectonic web bundle to a specific version for reproducible build
    ./pin-web-bundle.patch
  ];

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
