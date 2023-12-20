# This package provides `tectonic.passthru.tests`.

{ lib
, fetchurl
, linkFarmFromDrvs
}:

let
  /*
    Currently, the test files are only fully available from the `dev` branch of
    `biber`. If https://github.com/plk/biber/pull/467 is merged and released,
    we can obtain the test files from `texlive.pkgs.biber.texsource`. For now,
    we fetch the individual test files directly from GitHub.
  */
  fetchTestfile = { filename, hash }:
    let
      # HEAD of the `dev` branch: https://api.github.com/repos/plk/biber/commits/dev
      commit = "729d0b44360dc1f5bc056e714ae3e1a5b5f69d83";
    in
    fetchurl {
      url = "https://raw.githubusercontent.com/plk/biber/${commit}/testfiles/${filename}";
      inherit hash;
    };
  testfilesSpec = [
    { filename = "test.tex"; hash = "sha256-PvO3sBdAwXfXlgKPDVpNTeqdj86JEEh9NZfQoVyfUwU="; }
    { filename = "test.bib"; hash = "sha256-m8h1zdoAk9sn9IkNxYAfZncReklbr9FvpBYlRB8Jk2g="; }
  ];
  testfiles = linkFarmFromDrvs "testfiles" (map fetchTestfile testfilesSpec);

in
testfiles
