{ lib, callPackage, fetchFromGitHub, fetchpatch, biber }:

{
  biber-from-texlive = biber;
  biber-for-tectonic = let version = "2.17"; in (
    biber.override {
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
    }
  ).overrideAttrs (prevAttrs: {
    src = fetchFromGitHub {
      owner = "plk";
      repo = "biber";
      rev = "v${version}";
      hash = "sha256-Tt2sN2b2NGxcWyZDj5uXNGC8phJwFRiyH72n3yhFCi0=";
    };
    patches = [
      # Perl 5.38 compatibility
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/plk/biber/pull/411.patch";
        hash = "sha256-osgldRVfe3jnMSOMnAMQSB0Ymc1s7J6KtM2ig3c93SE=";
      })
    ];
    meta = prevAttrs.meta // {
      maintainers = with lib.maintainers; [ bryango ];
    };
  });
}
