{ stdenv, lib, fetchFromGitHub, wrapQtAppsHook, cmake
, fluidsynth, minizip, qtbase }:
stdenv.mkDerivation {
  pname = "vgmtrans";
  version = "2021-12-06";

  src = fetchFromGitHub {
    owner = "vgmtrans";
    repo = "vgmtrans";
    rev = "9b4362638ad4790db60c1db436aa3395aee0d883";
    sha256 = "0wp07dyf40sl715clv262srbcydmpw9a9rj00f4b4r24hxg2jhab";
  };

  nativeBuildInputs = [ cmake wrapQtAppsHook ];
  buildInputs = [ fluidsynth minizip qtbase ];

  postInstall = ''
    mkdir -p $out/bin
    mv $out/vgmtrans $out/bin
  '';

  meta = with lib; {
    description = "A tool to convert proprietary, sequenced videogame music to industry-standard formats";
    homepage = "https://github.com/vgmtrans/vgmtrans";
    license = licenses.zlib;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
