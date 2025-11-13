/*
  This file provides the `tectonic-unwrapped` package. On the other hand,
  the `tectonic` package is defined in `../tectonic/package.nix`, by wrapping
  - [`tectonic-unwrapped`](./package.nix) i.e. this package, and
  - [`biber-for-tectonic`](../../bi/biber-for-tectonic/package.nix),
    which provides a compatible version of `biber`.
*/

{
  lib,
  clangStdenv,
  fetchFromGitHub,
  rustPlatform,
  fontconfig,
  harfbuzzFull,
  openssl,
  pkg-config,
  icu,
  nix-update-script,
}:

let

  buildRustPackage = rustPlatform.buildRustPackage.override {
    # use clang to work around build failure with GCC 14
    # see: https://github.com/tectonic-typesetting/tectonic/issues/1263
    stdenv = clangStdenv;
  };

in

buildRustPackage rec {
  pname = "tectonic";
  # https://github.com/tectonic-typesetting/tectonic/issues/1263
  version = "0.15.0-unstable-2025-10-06";

  src = fetchFromGitHub {
    owner = "tectonic-typesetting";
    repo = "tectonic";
    rev = "42171eeade1641d846fef03566d1e26e9c6e3004";
    sha256 = "sha256-PEDhyDJHFGN2zGPx2x5H7KYUtwX7F/04Dw2qzQyiOSo=";
  };

  cargoHash = "sha256-0ks9JcVq1dRQZd7E5DdcZiI36RL2xgRHIGRkYDTRaps=";

  nativeBuildInputs = [ pkg-config ];

  buildFeatures = [ "external-harfbuzz" ];

  buildInputs = [
    icu
    fontconfig
    harfbuzzFull
    openssl
  ];

  postInstall = ''
    # Makes it possible to automatically use the V2 CLI API
    ln -s $out/bin/tectonic $out/bin/nextonic
  ''
  + lib.optionalString clangStdenv.hostPlatform.isLinux ''
    substituteInPlace dist/appimage/tectonic.desktop \
      --replace Exec=tectonic Exec=$out/bin/tectonic
    install -D dist/appimage/tectonic.desktop -t $out/share/applications/
    install -D dist/appimage/tectonic.svg -t $out/share/icons/hicolor/scalable/apps/
  '';

  doCheck = true;
  preCheck = ''
    export HOME="$(mktemp -d)"
  '';
  checkFlags = [
    # https://github.com/tectonic-typesetting/tectonic/issues/1263
    "--skip=tests::no_segfault_after_failed_compilation"
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=continuous"
      "--version-regex=tectonic@(.*)"
    ];
  };

  meta = {
    description = "Modernized, complete, self-contained TeX/LaTeX engine, powered by XeTeX and TeXLive";
    homepage = "https://tectonic-typesetting.github.io/";
    changelog = "https://github.com/tectonic-typesetting/tectonic/blob/tectonic@${version}/CHANGELOG.md";
    license = with lib.licenses; [ mit ];
    mainProgram = "tectonic";
    maintainers = with lib.maintainers; [
      lluchs
      doronbehar
      bryango
    ];
  };
}
