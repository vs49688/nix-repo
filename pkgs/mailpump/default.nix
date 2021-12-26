{ buildGoModule, lib, fetchFromGitHub }:
buildGoModule rec {
  pname = "mailpump";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = pname;
    rev = "v${version}";
    sha256 = "13k0dgpivb8lsgmvcdf0plif90v873xy8vp78fx2589awris55xx";
  };

  vendorSha256 = null;

  meta = with lib; {
    description = "A service that monitors a mailbox for messages and will automatically move them to another, usually on a different server";
    homepage = "https://github.com/vs49688/mailpump";
    license = licenses.gpl2Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
