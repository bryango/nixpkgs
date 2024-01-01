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
    /*
      Provides a consistent `--web-bundle` option across the CLIs. This enables
      a version lock of the tectonic web bundle for reproducible builds by
      specifying a default `--web-bundle` flag, which can be overridden as
      needed. This patch should be removed once the upstream PR is merged:
        https://github.com/tectonic-typesetting/tectonic/pull/1132
    */
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/tectonic-typesetting/tectonic/pull/1132.patch";
      hash = "sha256-MFPU0t8ScsM9ap9/XHVkhp/8gTgmdpv6t03L4uzLZjM=";
    })
  ];

  cargoHash = "sha256-1WjZbmZFPB1+QYpjqq5Y+fDkMZNmWJYIxmMFWg7Tiac=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ icu fontconfig harfbuzz openssl ]
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ ApplicationServices Cocoa Foundation ]);

  # workaround for https://github.com/NixOS/nixpkgs/issues/166205
  NIX_LDFLAGS = lib.optionalString (stdenv.cc.isClang && stdenv.cc.libcxx != null) " -l${stdenv.cc.libcxx.cxxabi.libName}";

  postInstall = ''
    # Makes it possible to automatically use the V2 CLI API
    ln -s $out/bin/tectonic $out/bin/nextonic
  '' + lib.optionalString stdenv.isLinux ''
    substituteInPlace dist/appimage/tectonic.desktop \
      --replace Exec=tectonic Exec=$out/bin/tectonic
    install -D dist/appimage/tectonic.desktop -t $out/share/applications/
    install -D dist/appimage/tectonic.svg -t $out/share/icons/hicolor/scalable/apps/
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
