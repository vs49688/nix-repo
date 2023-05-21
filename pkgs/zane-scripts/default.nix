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
    rev    = "60acaa733e16f5f4205ed321c26dea5c4e529633";
    hash   = "sha256-wY0BNI8E9VkZTsIeertbGG5QgvNCj99nBaty24qge+k=";
  };

  mkScriptDerivation = args@{ pname, script ? "${pname}.sh", buildInputs ? [], ... }: stdenv.mkDerivation {
    inherit src;
    inherit pname;

    version = "unstable-2023-05-16";

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
