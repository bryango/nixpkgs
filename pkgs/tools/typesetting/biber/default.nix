{ lib, stdenv, perlPackages, shortenPerlShebang
, texlive
, biberSource ? let inherit (texlive.pkgs.biber) texsource; in {
    inherit (texsource) pname version meta;
    src = "${texsource}/source/bibtex/biber/biblatex-biber.tar.gz";
  }
}:

perlPackages.buildPerlModule {
  inherit (biberSource) pname version src;

  buildInputs = with perlPackages; [
    autovivification BusinessISBN BusinessISMN BusinessISSN ConfigAutoConf
    DataCompare DataDump DateSimple EncodeEUCJPASCII EncodeHanExtra EncodeJIS2K
    DateTime DateTimeFormatBuilder DateTimeCalendarJulian
    ExtUtilsLibBuilder FileSlurper FileWhich IPCRun3 LogLog4perl LWPProtocolHttps ListAllUtils
    ListMoreUtils MozillaCA ParseRecDescent IOString ReadonlyXS RegexpCommon TextBibTeX
    UnicodeLineBreak URI XMLLibXMLSimple XMLLibXSLT XMLWriter
    ClassAccessor TextCSV TextCSV_XS TextRoman DataUniqid LinguaTranslit SortKey
    TestDifferences
    PerlIOutf8_strict
  ];
  nativeBuildInputs = lib.optional stdenv.isDarwin shortenPerlShebang;

  postInstall = lib.optionalString stdenv.isDarwin ''
    shortenPerlShebang $out/bin/biber
  '';

  patches = biberSource.patches or [ ];

  meta = with lib; {
    description = "Backend for BibLaTeX";
    license = biberSource.meta.license;
    platforms = platforms.unix;
    maintainers = biberSource.meta.maintainers or [ maintainers.ttuegel ];
    mainProgram = "biber";
  };
}
