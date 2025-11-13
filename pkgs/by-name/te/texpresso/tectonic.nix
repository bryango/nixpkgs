{
  tectonic-unwrapped,
  fetchFromGitHub,
  rustPlatform,
}:

tectonic-unwrapped.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "texpresso-tonic";
    version = "0-unstable-2025-08-11";
    src = fetchFromGitHub {
      owner = "let-def";
      repo = "tectonic";
      rev = "be0a9543600ab3a98f6ae6c37047522c09c2a02e";
      hash = "sha256-u1t2UuQ2Oumjpjkb4W+RvybmFPPBxbYRWrSWJuqpZIc=";
    };

    cargoHash = "sha256-mX9DsucLbls1w0ULQ6kEHel/u1PZjQPcGZK3pjN7RVE=";
    # rebuild cargoDeps by hand because `.overrideAttrs cargoHash`
    # does not reconstruct cargoDeps (a known limitation):
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      name = "${finalAttrs.pname}-${finalAttrs.version}";
      hash = finalAttrs.cargoHash;
      patches = finalAttrs.cargoPatches or [ ];
    };
    # binary has a different name, bundled tests won't work
    doCheck = false;
    postInstall = ''
      ${prevAttrs.postInstall or ""}

      # Remove the broken `nextonic` symlink
      # It points to `tectonic`, which doesn't exist because the exe is
      # renamed to texpresso-tonic
      rm $out/bin/nextonic
    '';
    meta = prevAttrs.meta // {
      mainProgram = "texpresso-tonic";
    };
  }
)
