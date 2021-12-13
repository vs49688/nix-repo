{ stdenv, lib, fetchFromGitHub, autoreconfHook, alsa-lib }:
stdenv.mkDerivation rec {
  pname = "awesfx";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "tiwai";
    repo = "awesfx";
    rev = "0581458acc5f28ef50742805cf37278d979b1c12"; # 3 commits ahead of 0.5.2
    sha256 = "171nngdzwq634iaxiq13aca6qlkixa5xz5wmv56hdr49f5whysd5";
  };

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = [ alsa-lib ];

  meta = with lib; {
    homepage    = "https://github.com/tiwai/awesfx";
    description = "An old and good AWE32-compatible SoundFont utility";
    platforms   = platforms.linux;
    license     = licenses.gpl2Plus;
    maintainers = with maintainers; [ zane ];
  };
}
