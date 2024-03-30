{ stdenv
, lib
, fetchurl
, pkg-config
, yasm
, lame
, libvorbis
, libopus
, fdk_aac
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "ffmpeg";
  version = "6.1";

  src = fetchurl {
    url = "https://ffmpeg.org/releases/ffmpeg-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-k43XeLqgTTUxY8pcsGyQnJGIUAVfVJIFspsSJORaUxY=";
  };

  nativeBuildInputs = [
    pkg-config
    yasm
  ];

  buildInputs = [
    lame
    libvorbis
    libopus
    fdk_aac
  ];

  configureFlags = [
    # Not redistributing it, build it yourself...
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
})
