{
  lib,
  symlinkJoin,
  tectonic,
  tectonic-unwrapped,
  biber-for-tectonic,
  makeBinaryWrapper,
  callPackage,
}:

let

  tectonic-patched = tectonic-unwrapped.overrideAttrs (
    {
      env ? { },
      meta ? { },
      ...
    }@_prevAttrs:
    {
      env = env // {
        TECTONIC_BUNDLE_LOCKED = tectonic.passthru.bundleUrl; # defined below
      };
      meta = meta // {
        description = "${meta.description or "Tectonic"} (patched with a locked bundle URL)";
      };
    }
  );

in

symlinkJoin {
  name = "${tectonic-patched.pname}-wrapped-${tectonic-patched.version}";
  paths = [ tectonic-patched ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  passthru = {
    unwrapped = tectonic-unwrapped;
    patched = tectonic-patched;
    biber = biber-for-tectonic;
    tests = callPackage ./tests.nix { };

    /**
      The version locked tectonic web bundle, redirected from:
        https://relay.fullyjustified.net/default_bundle_v33.tar
      To check for updates, see:
        https://github.com/tectonic-typesetting/tectonic/blob/master/crates/bundles/src/lib.rs
      ... and look up `get_fallback_bundle_url`.

      We pin the version of the online TeX bundle that Tectonic's developer
      distribute, so that the `biber` version and the `biblatex` version
      distributed from there are compatible.

      Upstream is updating it's online TeX bundle slower then
      https://github.com/plk/biber. That's why we match here the `bundleURL`
      version with that of `biber-for-tectonic`. See also upstream discussion:

      https://github.com/tectonic-typesetting/tectonic/discussions/1122

      Hence, we can be rather confident that for the near future, the online
      TeX bundle won't be updated and hence the biblatex distributed there
      won't require a higher version of biber.
    */
    bundleUrl = "https://data1.fullyjustified.net/tlextras-2022.0r0.tar";
  };

  # Replace the unwrapped tectonic with the one wrapping it with biber
  postBuild = ''
    rm $out/bin/{tectonic,nextonic}
    makeWrapper ${lib.getBin tectonic-patched}/bin/tectonic $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber-for-tectonic}/bin" \
      --inherit-argv0 ## make sure binary name e.g. `nextonic` is passed along
    ln -s $out/bin/tectonic $out/bin/nextonic
  '';

  meta = tectonic-patched.meta // {
    description = "TeX/LaTeX engine, wrapped with a compatible biber";
    maintainers = with lib.maintainers; [
      doronbehar
      bryango
    ];
  };
}
