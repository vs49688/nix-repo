{ stdenv
, lib
#, fetchurl
}:
let
  mkCmdPackDerivation = args@{ pname, ... }: stdenv.mkDerivation ({
    version = "1.03";

    # src = fetchurl {
    #   url    = "https://web.archive.org/web/20140330233023/http://www.neillcorlett.com/downloads/cmdpack-1.03-src.tar.gz";
    #   sha256 = "0v0a9rpv59w8lsp1cs8f65568qj65kd9qp7854z1ivfxfpq0da2n";
    # };

    # It's 78kb, small enough to store in the repo.
    src = ./cmdpack-1.03-src.tar.gz;

    buildPhase = ''
      runHook preBuild

      gcc -o ${pname} src/${pname}.c

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp ${pname} $out/bin

      runHook postInstall
    '';

    meta = with lib; {
      homepage    = "https://web.archive.org/web/20140330233023/http://www.neillcorlett.com/cmdpack/";
      platforms   = platforms.all;
      license     = licenses.gpl3Plus;
      maintainers = with maintainers; [ zane ];
    };
  } // args);
in {
  bin2iso  = mkCmdPackDerivation { pname = "bin2iso"; };
  bincomp  = mkCmdPackDerivation { pname = "bincomp"; };
  brrrip   = mkCmdPackDerivation { pname = "brrrip"; };
  byteshuf = mkCmdPackDerivation { pname = "byteshuf"; };
  byteswap = mkCmdPackDerivation { pname = "byteswap"; };
  cdpatch  = mkCmdPackDerivation { pname = "cdpatch"; };
  ecm      = mkCmdPackDerivation {
    pname = "ecm";
    postInstall = "ln $out/bin/ecm $out/bin/unecm";
  };
  fakecrc  = mkCmdPackDerivation { pname = "fakecrc"; };
  hax65816 = mkCmdPackDerivation { pname = "hax65816"; };
  id3point = mkCmdPackDerivation { pname = "id3point"; };
  pecompat = mkCmdPackDerivation { pname = "pecompat"; };
  rels     = mkCmdPackDerivation { pname = "rels"; };
  screamf  = mkCmdPackDerivation { pname = "screamf"; };
  subfile  = mkCmdPackDerivation { pname = "subfile"; };
  uips     = mkCmdPackDerivation { pname = "uips"; };
  usfv     = mkCmdPackDerivation { pname = "usfv"; };
  vb2rip   = mkCmdPackDerivation { pname = "vb2rip"; };
  wordadd  = mkCmdPackDerivation { pname = "wordadd"; };
  zerofill = mkCmdPackDerivation { pname = "zerofill"; };
}
