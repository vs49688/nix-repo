{ buildGoModule, lib, fetchFromGitHub }:
buildGoModule rec {
  pname = "mailpump";
  version = "unstable-2023-11-05";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = pname;
    rev = "47e74d44bdc846776c726f368e9151083c99dd3b";
    hash = "sha256-Bt8UR9gmL+CiN7HUAcm1VBAVBnOwGmx+1sN0JrMle48";
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
