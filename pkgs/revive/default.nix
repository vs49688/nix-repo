{ lib, buildGoModule, fetchFromGitHub, fetchpatch }:
buildGoModule rec {
  pname = "revive";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "mgechev";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-V0YWp4zQduW+cnuiVoEAPxDnsA4OR0TnJdoOF9TdRjw=";
  };

  vendorSha256 = "sha256-Fpl5i+qMvJ/CDh8X0gps9C/BxF7/Uvln+3DpVOXE0WQ=";

  # Some screwy "don't use unit-specific suffix" errors happening
  doCheck = false;

  meta = with lib; {
    description = "~6x faster, stricter, configurable, extensible, and beautiful drop-in replacement for golint";
    homepage = "https://revive.run/";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
