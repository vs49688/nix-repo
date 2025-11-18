{ stdenv
, lib
, requireFile
, fetchzip
, autoPatchelfHook
, makeBinaryWrapper
, gtk2-x11
, atk
, gdk-pixbuf
, pango
, SDL2
, alsa-lib
, libjack2
, libpulseaudio
, bubblewrap
}:
let
  actualSrc = (requireFile {
    name = "helltaker_lnx.zip";
    message = "Please prefetch helltaker_lnx.zip from https://vanripper.itch.io/helltaker";
    sha256 = "sha256-BPXhdLGjKChthoVLIRN/C4wNAR+dEakQTlnMC1V92/s=";
  }).overrideAttrs(old: { allowSubstitutes = true; });
in
stdenv.mkDerivation(finalAttrs: {
  pname = "helltaker";
  version = "1.0.0";

  src = fetchzip {
    url = "file://${actualSrc}";
    stripRoot = false;
    hash = "sha256-szzVAxbfrWzftZ1P2ERgv+4GHK3CfNiN2GtUhn+7VJ8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];

  buildInputs = [
    stdenv.cc.libc
    stdenv.cc.cc.lib
    gtk2-x11
    atk
    gdk-pixbuf
    pango
  ];

  dontBuild = true;

  ##
  # To Note:
  # 1. Unity statically links SDL2. Use the SDL_DYNAMIC_API to force it to use ours.
  # 2. This requires alsa-lib and friends.
  # 3. Unity is notorious for being chatty. Block it's network access.
  ##
  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helltaker $out/bin
    mv * $out/opt/helltaker

    chmod +x "$out/opt/helltaker/helltaker_lnx.x86_64"

    wrapProgram "$out/opt/helltaker/helltaker_lnx.x86_64" \
      --set SDL_DYNAMIC_API "${SDL2}/lib/libSDL2.so" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ alsa-lib libjack2 libpulseaudio ]}" \
      --chdir "$out/opt/helltaker"

    makeWrapper ${bubblewrap}/bin/bwrap "$out/bin/helltaker.x86_64" \
      --add-flags "--bind / /" \
      --add-flags "--dev-bind /dev /dev" \
      --add-flag --unshare-net \
      --add-flag -- \
      --add-flag "$out/opt/helltaker/helltaker_lnx.x86_64"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Helltaker";
    homepage = "https://vanripper.itch.io/helltaker";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
})
