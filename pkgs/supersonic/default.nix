{ lib
, buildGoModule
, fetchFromGitHub
, makeDesktopItem
, copyDesktopItems
, pkg-config
, xorg
, libglvnd
, mpv
, glfw3
, waylandSupport ? false
}:

buildGoModule rec {
  pname = "supersonic";
  version = "unstable-2023-08-29";

  src = fetchFromGitHub {
    owner = "dweymouth";
    repo = "supersonic";
    rev = "ce685933be4ea7632fc9087269246e40c0d0a284";
    hash = "sha256-AEcPrvVbtDG63s9M/+bwbAC/2SWeUnPqdi3gE4AaTlc=";
  };

  vendorHash = "sha256-Pm3xuEWECBsga8oT+IYJpL4gAI7WcTizCd8twKBQ284=";

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ];

  buildInputs = [
    libglvnd
    mpv
    xorg.libXxf86vm
  ] ++ (glfw3.override { inherit waylandSupport; }).buildInputs;

  postInstall = ''
    mkdir -p $out/share/icons/hicolor/{128x128,256x256,512x512}/apps

    for i in 128 256 512; do
      install -D $src/res/appicon-$i.png $out/share/icons/hicolor/''${i}x''${i}/apps/${meta.mainProgram}.png
    done
  '';

  tags = lib.optionals waylandSupport [ "wayland" ];

  desktopItems = [
    (makeDesktopItem {
      name = meta.mainProgram;
      exec = meta.mainProgram;
      icon = meta.mainProgram;
      desktopName = "Supersonic";
      genericName = "Subsonic Client";
      comment = meta.description;
      type = "Application";
      categories = [ "Audio" "AudioVideo" ];
    })
  ];

  meta = with lib; {
    mainProgram = "supersonic";
    description = "A lightweight cross-platform desktop client for Subsonic music servers";
    homepage = "https://github.com/dweymouth/supersonic";
    platforms = platforms.linux;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zane ];
  };
}
