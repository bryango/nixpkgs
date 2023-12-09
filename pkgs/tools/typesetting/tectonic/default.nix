/*
  This file provides the `tectonic-unwrapped` package. On the other hand,
  the `tectonic` package is defined in `./wrapper.nix`, by wrapping
  - [`tectonic-unwrapped`](./default.nix) i.e. this package, and
  - [`biber-for-tectonic`](./biber.nix),
    which provides a compatible version of `biber`.
*/

{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, rustPlatform
, darwin
, fontconfig
, harfbuzz
, openssl
, pkg-config
, makeBinaryWrapper
, icu
}:

rustPlatform.buildRustPackage rec {
  pname = "tectonic";
  version = "0.14.1";

  src = fetchFromGitHub {
    owner = "tectonic-typesetting";
    repo = "tectonic";
    rev = "tectonic@${version}";
    fetchSubmodules = true;
    sha256 = "sha256-Cd8YzjU5mCA5DmgLBjg8eVRc87chVVIXinJuf8cNw3o=";
  };

  patches = [
    # Provides a version lock of the tectonic web bundle for reproducible builds
    # by specifying the environment variable `TECTONIC_WEB_BUNDLE_LOCKED`.
    # Upstream PR: https://github.com/tectonic-typesetting/tectonic/pull/1131
    # This patch should be removed once the upstream PR is merged
    (fetchpatch {
      url = "https://github.com/tectonic-typesetting/tectonic/commit/4491480dab6578941f8516dd40563cdc5c5f9ebc.patch";
      hash = "sha256-lnV4ZJLsAB0LC6PdKNjUreUPDKeD+L5lPod605tQtYo=";
    })
  ];

  cargoHash = "sha256-1WjZbmZFPB1+QYpjqq5Y+fDkMZNmWJYIxmMFWg7Tiac=";

  # `makeBinaryWrapper` is needed later on for wrapping with biber
  nativeBuildInputs = [ pkg-config makeBinaryWrapper ];

  buildInputs = [ icu fontconfig harfbuzz openssl ]
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ ApplicationServices Cocoa Foundation ]);

  # workaround for https://github.com/NixOS/nixpkgs/issues/166205
  NIX_LDFLAGS = lib.optionalString (stdenv.cc.isClang && stdenv.cc.libcxx != null) " -l${stdenv.cc.libcxx.cxxabi.libName}";

  postInstall = lib.optionalString stdenv.isLinux ''
    substituteInPlace dist/appimage/tectonic.desktop \
      --replace Exec=tectonic Exec=$out/bin/tectonic
    install -D dist/appimage/tectonic.desktop -t $out/share/applications/
    install -D dist/appimage/tectonic.svg -t $out/share/icons/hicolor/scalable/apps/

    ln -s $out/bin/tectonic $out/bin/nextonic
  '';

  doCheck = true;

  meta = with lib; {
    description = "Modernized, complete, self-contained TeX/LaTeX engine, powered by XeTeX and TeXLive";
    homepage = "https://tectonic-typesetting.github.io/";
    changelog = "https://github.com/tectonic-typesetting/tectonic/blob/tectonic@${version}/CHANGELOG.md";
    license = with licenses; [ mit ];
    mainProgram = "tectonic";
    maintainers = with maintainers; [ lluchs doronbehar bryango ];
  };
}
