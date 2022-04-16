{ stdenv, lib, cmake, fetchFromGitHub, alsaLib, libudev }:
stdenv.mkDerivation rec {
  pname   = "pimidid";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = pname;
    rev    = "173b0993a2739ed9434ac9e7d24459876990dc5e";
    sha256 = "0a6qflp0fy819i5a05q26rpaljqjkzi8jxri3i7qwx5lgppjblb8";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ alsaLib libudev ];

  installPhase = ''
    mkdir -p $out/bin
    cp pimidid $out/bin
  '';

  meta = with lib; {
    description = "Small daemon to automatically connect MIDI devices to FluidSynth";
    homepage    = "https://github.com/vs49688/pimidid";
    platforms   = platforms.all;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ zane ];
  };
}
