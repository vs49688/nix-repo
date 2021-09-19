{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, shntool
, cuetools
, ghostscript
, python3
, ffmpeg
}:
let
  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = "scripts";
    rev    = "6c27edd25f63944d64786452ebf3e6098c34d078";
    sha256 = "0vj2hy6j5q7scf6x5is3z8bprfn02hc25kc1s7xxy7pd35lzsrqn";
  };

  mkScriptDerivation = args@{ pname, script ? "${pname}.sh", buildInputs ? [], ... }: stdenv.mkDerivation {
    inherit src;
    inherit pname;

    version = "0.0.0";

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
}
