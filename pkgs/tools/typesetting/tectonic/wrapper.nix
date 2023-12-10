{ lib
, makeBinaryWrapper
, symlinkJoin
, tectonic
, biberVersions
}:

let

  pname = "tectonic-with-biber";
  biber = biberVersions.biber-for-tectonic;
  inherit (biber) version;

  ## manually construct `name` for `symlinkJoin`
  name = "${pname}-${version}";

  meta = tectonic.meta // {
    inherit name;
    description = "Modernized TeX/LaTeX engine, with biber for bibliography";
    longDescription = ''
      This package wraps tectonic with biber without triggering rebuilds.
      The biber executable is exposed with a version suffix, such as
      `biber-${version}`, to prevent conflict with the `biber` bundled with
      texlive in nixpkgs. Example use:

          let
            pkgs = <...>; # import nixpkgs here
          in pkgs.tectonic-with-biber.override {
            biber = pkgs.biberVersions.biber_2_17;
          }

      This serves as a fix for:
      - https://github.com/tectonic-typesetting/tectonic/issues/893
    '';
    maintainers = with lib.maintainers; [ bryango ];
  };

  ## produce the correct `meta.position` for `symlinkJoin`
  pos = builtins.unsafeGetAttrPos "description" meta;

in

symlinkJoin {

  inherit pname version name meta pos;

  paths = [ tectonic ];
  nativeBuildInputs = [ makeBinaryWrapper ];
  passthru = { biber = biber; };

  ## tectonic runs biber when it detects it needs to run it, see:
  ## https://github.com/tectonic-typesetting/tectonic/releases/tag/tectonic%400.7.0
  postBuild = ''
    wrapProgram $out/bin/tectonic \
      --prefix PATH : "${lib.getBin biber}/bin"
    makeBinaryWrapper "${lib.getBin biber}/bin/biber" \
      $out/bin/biber-${biber.version}
  '';
  ## the biber executable is exposed as `biber-${biber.version}`

}
