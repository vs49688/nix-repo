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
    rev    = "92173afd79037c4e1292ed1686b46d08d205214b";
    hash   = "sha256-5tcXS+CQfHvhMZEgdJgSwP0hXyZCT0zPOV2+m29xcKo=";
  };

  mkScriptDerivation = args@{ pname, script ? "${pname}.sh", buildInputs ? [], ... }: stdenv.mkDerivation {
    inherit src;
    inherit pname;

    version = "unstable-2023-06-03";

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

  gocheck = mkScriptDerivation {
    pname = "gocheck";
    script = "gocheck.sh";
    # NB: Deliberately not including the go tools here
    # because this may be used with different versions.
    buildInputs = [ ];
  };
}
