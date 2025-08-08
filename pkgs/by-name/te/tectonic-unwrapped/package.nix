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
  unstableGitUpdater,
  writeScript,
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
  version = "0.15.0-unstable-2025-08-04";

  src = fetchFromGitHub {
    owner = "tectonic-typesetting";
    repo = "tectonic";
    rev = "cfcb70a1447d329fdea8af7d3b12bcf9e5d26f40";
    sha256 = "sha256-ghzXs0oMWSN5A40djwRuAyBgQmUbmXyV2WGf8KO+84c=";
  };

  cargoHash = "sha256-r1q4tHLIybaYqqJR7AQM9R/L/Vnuw93OKb7WXclmbmE=";

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

  passthru.updateScript = writeScript "update-tectonic" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p nix-update

    set -euo pipefail
    set -x

    ${lib.concatStringsSep " " (unstableGitUpdater rec {
      tagFormat = "${tagPrefix}*";
      tagPrefix = "tectonic@";
      branch = "continuous";
    })}

    nix-update --version=skip
  '';

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
