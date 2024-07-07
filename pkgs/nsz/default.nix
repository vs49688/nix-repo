{ buildPythonApplication
, lib
, fetchFromGitHub
, enlighten
, pycryptodome
, zstandard
}:
let
  finalAttrs = {
    pname = "nsz";
    version = "4.6.1";

    src = fetchFromGitHub {
      owner = "nicoboss";
      repo = finalAttrs.pname;
      rev = finalAttrs.version;
      hash = "sha256-ch4HzQFa95o3HMsi7R0LpPWmhN/Z9EYfrmCdUZLwPSE=";
    };

    propagatedBuildInputs = [
      enlighten
      pycryptodome
      zstandard
    ];

    doCheck = false;

    meta = with lib; {
      description = "NSZ - Homebrew compatible NSP/XCI compressor/decompressor";
      homepage = "https://github.com/nicoboss/nsz";
      license = licenses.mit;
      maintainers = with maintainers; [ zane ];
      mainProgram = "nsz";
    };
  };
in buildPythonApplication finalAttrs
