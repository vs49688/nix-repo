{ stdenv, lib, fetchurl, pkg-config, yasm
, lame, libvorbis, libopus, fdk_aac
}:
stdenv.mkDerivation rec {
  pname = "ffmpeg";
  version = "5.1";

  src = fetchurl {
    url = "https://ffmpeg.org/releases/ffmpeg-${version}.tar.gz";
    sha256 = "sha256-wLLsKQq9WtMbXgqMRVw0+QMG7NLt5qzl21yjoH87hC8=";
  };

  nativeBuildInputs = [ pkg-config yasm ];

  buildInputs = [ lame libvorbis libopus fdk_aac ];

  configureFlags = [
    # Not redistributing it, built it yourself...
    "--enable-gpl"
    "--enable-version3"
    "--enable-nonfree"

    "--enable-shared"
    "--disable-ffplay"
    "--disable-ffprobe"
    "--disable-autodetect"

    "--disable-doc"
    "--disable-devices"
    "--disable-avdevice"

    "--disable-protocols"
    "--enable-protocol=file"
    "--enable-protocol=pipe"

    "--enable-libmp3lame"
    "--enable-libvorbis"
    "--enable-libopus"
    "--enable-libfdk-aac"
  ];

  enableParallelBuilding = true;
}
