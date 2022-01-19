{ lib, buildGoModule, fetchFromGitHub, fetchpatch }:
buildGoModule rec {
  pname = "revive";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "mgechev";
    repo = pname;
    rev = "v${version}";
    sha256 = "1n4ivw04c9yccaxjalm7rb7gmrks2dkh6rrhfl7ia50pq34632cx";
  };

  vendorSha256 = "0i28zahy1nby788j150vvzmvl49x0gq75y9fhxicsmlbq1z3vfcd";

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
