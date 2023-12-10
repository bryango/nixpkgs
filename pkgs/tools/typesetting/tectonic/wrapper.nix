{ lib
, makeBinaryWrapper
, symlinkJoin
, tectonic
, biber-for-tectonic
, biber
}:

let

  pname = "tectonic-with-biber";
  inherit (biber-for-tectonic) version;

  # manually construct `name` for `symlinkJoin`
  name = "${pname}-${version}";

  meta = tectonic.meta // {
    inherit name;
    description = "Tectonic, wrapped with the correct biber version";
    longDescription = ''
      This package wraps tectonic with biber without triggering rebuilds.
      The biber executable is exposed with a version suffix, such as
      `biber-${version}`, to prevent conflict with the `biber` bundled with
      texlive in nixpkgs.

      This serves as a downstream fix for:
      - https://github.com/tectonic-typesetting/tectonic/issues/893
    '';
    maintainers = with lib.maintainers; [ bryango ];
  };

in

symlinkJoin {

  inherit pname version name meta;

  paths = [ tectonic ];
  nativeBuildInputs = [ makeBinaryWrapper ];
  passthru = { inherit biber; };

  # tectonic runs biber when it detects it needs to run it, see:
  # https://github.com/tectonic-typesetting/tectonic/releases/tag/tectonic%400.7.0
  postBuild = ''
    wrapProgram $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber-for-tectonic}/bin"
    makeBinaryWrapper "${lib.getBin biber-for-tectonic}/bin/biber" \
      $out/bin/biber-${biber-for-tectonic.version}
  '';
  # the biber executable is exposed as `biber-${biber.version}`

}
