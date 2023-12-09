{ lib
, tectonic-unwrapped
, biber-for-tectonic
}:

tectonic-unwrapped.overrideAttrs (prevAttrs: {

  /*
    The version locked tectonic web bundle, redirected from:
      https://relay.fullyjustified.net/default_bundle_v33.tar
    To check for updates: look up `get_fallback_bundle_url` from:
      https://github.com/tectonic-typesetting/tectonic/blob/master/crates/bundles/src/lib.rs
  */
  TECTONIC_WEB_BUNDLE_LOCKED = "https://data1.fullyjustified.net/tlextras-2022.0r0.tar";

  passthru = {
    unwrapped = tectonic-unwrapped;
    biber = biber-for-tectonic;
  };

  # tectonic runs biber when it detects it needs to run it, see:
  # https://github.com/tectonic-typesetting/tectonic/releases/tag/tectonic%400.7.0
  postInstall = ''
    wrapProgram $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber-for-tectonic}/bin"
  '' + (prevAttrs.postInstall or "");

  meta = prevAttrs.meta // {
    description = "Tectonic, wrapped with the correct biber version";
    longDescription = ''
      This package wraps tectonic with a compatible version of biber.
      The tectonic web bundle is pinned to ensure reproducibility.
      This serves as a downstream fix for:
      - https://github.com/tectonic-typesetting/tectonic/issues/893
    '';
    maintainers = with lib.maintainers; [ doronbehar bryango ];
  };

})
