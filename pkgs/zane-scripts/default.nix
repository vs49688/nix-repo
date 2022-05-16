{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, shntool
, cuetools
, ghostscript
, python3
, ffmpeg
, parallel
}:
let
  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = "scripts";
    rev    = "b9f30525a8ea4488e5cc5b773b181ba5c03f8a2f";
    sha256 = "sha256-H0KXZL2i8pu995RbEHCW/OX1ACxKy+4GnNO0iXeZeJo=";
  };

  mkScriptDerivation = args@{ pname, script ? "${pname}.sh", buildInputs ? [], ... }: stdenv.mkDerivation {
    inherit src;
    inherit pname;

    version = "unstable-2022-05-14";

    nativeBuildInputs = [ makeWrapper ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      makeWrapper $src/${script} $out/bin/${pname} \
        --prefix PATH : ${lib.makeBinPath buildInputs}

      runHook postInstall
    '';
  };
in
{
  fuckcue = mkScriptDerivation {
    pname       = "fuckcue";
    buildInputs = [ shntool cuetools ];
  };

  pdfreduce = mkScriptDerivation {
    pname       = "pdfreduce";
    buildInputs = [ ghostscript ];
  };

  startgame = mkScriptDerivation {
    pname       = "startgame";
  };

  rarfix = mkScriptDerivation {
    pname       = "rarfix";
    script      = "rarfix.py";
    buildInputs = [ python3 ffmpeg ];
  };

  ofxfix = mkScriptDerivation {
    pname       = "ofxfix";
    script      = "ofxfix.py";
    buildInputs = [ python3 ];
  };

  flalac = mkScriptDerivation {
    pname       = "flalac";
    buildInputs = [ ffmpeg parallel ];
  };

  alflac = mkScriptDerivation {
    pname       = "alflac";
    buildInputs = [ ffmpeg parallel ];
  };

  stuntxtract = mkScriptDerivation {
    pname       = "stuntxtract";
    script      = "stuntxtract.py";
    buildInputs = [ python3 ];
  };
}
