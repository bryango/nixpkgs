{ lib
, symlinkJoin
, tectonic-unwrapped
, biber-for-tectonic
, makeWrapper
, callPackage
}:

let

  # The version locked tectonic web bundle, redirected from:
  #   https://relay.fullyjustified.net/default_bundle_v33.tar
  # To check for updates, see:
  #   https://github.com/tectonic-typesetting/tectonic/blob/master/crates/bundles/src/lib.rs
  # ... and look up `get_fallback_bundle_url`.
  TECTONIC_WEB_BUNDLE_LOCKED = "https://data1.fullyjustified.net/tlextras-2022.0r0.tar";

in

symlinkJoin {
  name = "${tectonic-unwrapped.pname}-wrapped-${tectonic-unwrapped.version}";
  paths = [ tectonic-unwrapped ];

  nativeBuildInputs = [ makeWrapper ];

  passthru = {
    unwrapped = tectonic-unwrapped;
    biber = biber-for-tectonic;
    tests = callPackage ./tests.nix { };
  };

  # Replace the unwrapped tectonic with the one wrapping it with biber
  postBuild = ''
    rm $out/bin/{tectonic,nextonic}
  ''
    # Pin the version of the online TeX bundle that Tectonic's developer
    # distribute, so that the `biber` version and the `biblatex` version
    # distributed from there are compatible.
    #
    # Note also that upstream has announced that they will put less time and
    # energy for the project:
    #
    # https://github.com/tectonic-typesetting/tectonic/discussions/1122
    #
    # Hence, we can be rather confident that for the near future, the online
    # TeX bundle won't be updated and hence the biblatex distributed there
    # won't require a higher version of biber.
  + ''
    makeWrapper ${lib.getBin tectonic-unwrapped}/bin/tectonic $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber-for-tectonic}/bin" \
      --add-flags "--web-bundle ${TECTONIC_WEB_BUNDLE_LOCKED}"
    ln -s $out/bin/tectonic $out/bin/nextonic
  '';

  meta = tectonic-unwrapped.meta // {
    description = "Tectonic TeX/LaTeX engine, wrapped with a compatible biber";
    maintainers = with lib.maintainers; [ doronbehar bryango ];
  };
}
