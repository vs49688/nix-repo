{ buildGo118Module, lib, fetchFromGitHub }:
buildGo118Module rec {
  pname = "mailpump";
  version = "unstable-2022-07-31";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = pname;
    rev = "c68bab6f603065261ca69c9a3c9196c194c42936";
    sha256 = "sha256-ST1bKDr5CGDICHeWnsGZWlB/breA2rQP2jD8vFCP7do=";
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
