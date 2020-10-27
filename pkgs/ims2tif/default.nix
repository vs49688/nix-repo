{ stdenv, cmake, fetchFromGitHub, libtiff, hdf5, makeWrapper }:
stdenv.mkDerivation rec {
  name    = "ims2tif";
  version = "2.0.3";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = name;
    rev    = version;
    sha256 = "0fmlb8kcdqf2h9x2gif4lfwf1acwx2kci2lky00p4b5hfxrv2239";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ libtiff.dev hdf5.dev makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp ims2tif $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Dragonfly IMS to TIFF converter";
    homepage    = "https://github.com/UQ-RCC/ims2tif";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
