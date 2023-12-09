{ lib, callPackage, fetchFromGitHub, fetchpatch }:

lib.fix (self: {
  biber-from-texlive = callPackage ./. { };
  biber-for-tectonic = self.biber_2_17;
  biber_2_17 = let version = "2.17"; in callPackage ./. {
    biberSource = {
      inherit version;
      pname = "biber";
      meta = with lib; {
        license = licenses.artistic2;
        maintainers = [ maintainers.bryango ];
      };
      src = fetchFromGitHub {
        owner = "plk";
        repo = "biber";
        rev = "v${version}";
        hash = "sha256-Tt2sN2b2NGxcWyZDj5uXNGC8phJwFRiyH72n3yhFCi0=";
      };
      patches = [
        (fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/plk/biber/pull/411.patch";
          hash = "sha256-osgldRVfe3jnMSOMnAMQSB0Ymc1s7J6KtM2ig3c93SE=";
        })
      ];
    };
  };
})
