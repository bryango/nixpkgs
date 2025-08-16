{
  tectonic-unwrapped,
  fetchFromGitHub,
  rustPlatform,
}:

tectonic-unwrapped.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "texpresso-tonic";
    version = "0.15.0-unstable-2025-02-22";
    src = fetchFromGitHub {
      owner = "let-def";
      repo = "tectonic";
      rev = "bf124880d9901e12e2efe59df4818a921fb1398c";
      hash = "sha256-VydcTdcX0Qn0jZrt145bA8L5HxgXk6WDjPNERdjB83E=";
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
