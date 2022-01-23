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
    rev    = "39ddecc9aabfcc8a8f115b376d3fd71709553b41";
    sha256 = "088r6gh6xcp5alxf7l6m9k8g77nnfcxnfkccc0i37795zn1953pf";
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
