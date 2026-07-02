{ buildGoModule, lib, fetchFromGitHub }:
buildGoModule rec {
  pname = "mailpump";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = pname;
    rev = "d1ca3590f2c8fdeff19815b4e47a06bd91f03535";
    hash = "sha256-wK9xEDbF683DIFbOPmsXVO7xmnDGiIPEUy7UZ77zQh0=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "A service that monitors a mailbox for messages and will automatically move them to another, usually on a different server";
    homepage = "https://github.com/vs49688/mailpump";
    license = licenses.gpl2Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
