{ buildGoModule, lib, fetchFromForgejo }:
buildGoModule(finalAttrs: {
  pname = "mailpump";
  version = "0-unstable-2026-07-26";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "mailpump";
    rev = "eeb26a9d6efb0e8d90f435f46cb9fcd6c94b8588";
    hash = "sha256-UidANkxcc+h9GSKCKKKdpyl4au3ouso18bBEudjZhu0=";
  };

  vendorHash = null;

  meta = with lib; {
    mainProgram = "mailpump";
    description = "A service that monitors a mailbox for messages and will automatically move them to another, usually on a different server";
    homepage = "https://git.vs49688.net/zane/mailpump";
    license = licenses.gpl2Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
})
