{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "manix";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "manix";
    rev = "v${finalAttrs.version}";
    hash = "sha256-b/3NvY+puffiQFCQuhRMe81x2wm3vR01MR3iwe/gJkw=";
  };

  cargoHash = "sha256-4qyFVVIlJXgLnkp+Ln4uMlY0BBl8t1na67rSM2iIoEA=";

  meta = with lib; {
    description = "A fast CLI documentation searcher for Nix";
    homepage = "https://github.com/nix-community/manix";
    license = licenses.mpl20;
    maintainers = with maintainers; [ iogamaster lecoqjacob ];
    mainProgram = "manix";
  };
})
