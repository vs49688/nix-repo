{ stdenv, lib, requireFile, makeDesktopItem, copyDesktopItems
, icoutils, imagemagick_light
, autoPatchelfHook, glfw3, openalSoft
}:
stdenv.mkDerivation rec {
  pname = "croc64";
  version = "1.3.0";

  src = (requireFile {
    name = "croc64-1.3.0.tar.xz";
    message = "Please prefetch croc64-1.3.0.tar.xz into the Nix store";
    sha256 = "sha256-USdhKi4iMXChfKd9qFT0YZicj0elOVilWgnp9vNskrI=";
  }).overrideAttrs(old: { allowSubstitutes = true; });

  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook copyDesktopItems icoutils imagemagick_light ];
  buildInputs = [ glfw3 openalSoft ];

  desktopItems = [
    (makeDesktopItem {
      name = "croc64";
      exec = "Croc64";
      icon = pname;
      comment = "Croc! Legend of the Gobbos Definitive Edition";
      desktopName = "Croc! Legend of the Gobbos";
      categories = [ "Game" ];
    })
    (makeDesktopItem {
      name = "crocdemo64";
      exec = "CrocDemo64";
      icon = pname;
      comment = "Croc! Legend of the Gobbos Definitive Edition Demo";
      desktopName = "Croc! Legend of the Gobbos Demo";
      categories = [ "Game" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{croc64-${version},bin} $out/share/pixmaps
    wrestool -x -t 14 -n 101 Croc64.exe | convert ico:- $out/share/pixmaps/${pname}.png
    mv * $out/croc64-${version}
    rm -rf $out/croc64-${version}/{config,Croc{,Demo}64.exe,{OpenAL64,SDL2}.dll}

    ln -s $out/croc64-${version}/Croc64 $out/bin/Croc64
    ln -s $out/croc64-${version}/CrocDemo64 $out/bin/CrocDemo64

    runHook postInstall
  '';

  meta = with lib; {
    description = "Croc! Legend of the Gobbos Definitive Edition";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
}
