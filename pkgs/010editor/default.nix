{ lib
, stdenv
, buildFHSUserEnv
, makeWrapper
, autoPatchelfHook
, fetchurl
, makeDesktopItem
, copyDesktopItems
, xorg
, zlib
, freetype
, fontconfig
, libX11
, libxkbcommon
, dbus
, cups
, writeText
}:
let
  description = "Professional Text Editor + World's Best Hex Editor";

  unpacker = buildFHSUserEnv { name = "010editor-unpacker"; };

  responseFile = writeText "responses.txt" ''
    CreateDesktopShortcut: No
    CreateQuickLaunchShortcut: No
    InstallDir: ./010editor
    InstallMode: Silent
    InstallType: Typical
    LaunchApplication: No
    ProgramFolderName: 010 Editor
    SelectedComponents: Default Component
    ViewReadme: No
  '';
in
stdenv.mkDerivation rec {
  pname = "010editor";
  version = "12.0.1";

  src = fetchurl {
    url = "https://www.sweetscape.com/download/010EditorLinux64Installer.tar.gz";
    sha256 = "0ln8qxy1mij8qnnn8dxwnvmkx69l0f0w6xnb615ihx8wyhvlmfzh";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.libc
    stdenv.cc.cc.lib
    zlib
    xorg.libxcb
    freetype
    fontconfig
    libxkbcommon
    dbus
    cups
  ];

  unpackPhase = ''
    runHook preUnpack

    tar -xf ${src} 010EditorLinux64Installer
    ${unpacker}/bin/010editor-unpacker <<EOF
      ./010EditorLinux64Installer --response-file ${responseFile}
    EOF
    rm 010EditorLinux64Installer

    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,opt,share/pixmaps}
    rm -f 010editor/uninstall
    mv 010editor $out/opt

    makeWrapper "$out/opt/010editor/010editor" $out/bin/010editor

    install -D \
      $out/opt/010editor/010_icon_128x128.png \
      $out/share/pixmaps/010editor.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "010editor";
      exec = "010editor";
      icon = "010editor";
      comment = description;
      desktopName = "010 Editor";
      categories = "Utility;TextEditor;Development;IDE;";
    })
  ];

  meta = with lib; {
    homepage = https://www.sweetscape.com/010editor/;
    description = description;
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
