args@{ ... }: [
  ./postgresql.nix
  ./unifi.nix
  ./nextcloud.nix
  ./frigate.nix
  ./torrent.nix
  ./navidrome.nix
  ./immich.nix
  ./vaultwarden.nix
  ./ai.nix
  ./backup.nix
  ((import ./docspell.nix) args)
]
