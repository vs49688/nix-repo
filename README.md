# Personal Nix Packages Repository

## Contents

### Applications 🖥️

| Package         |    | Description                                                 | Link |
|-----------------|----|-------------------------------------------------------------|------|
| _010editor      |🐧  | 010 Editor v12.0.1[^1]                                      | [Link](https://www.sweetscape.com/010editor/) |
| hammerspoon     |🍎  | Staggeringly powerful macOS desktop automation with Lua     | [Link](https://www.hammerspoon.org/) |
| jdownloader     |🐧  | JDownloader is a free, open-source download management tool | [Link](https://jdownloader.org/) |
| linearmouse     |🍎  | The mouse and trackpad utility for Mac                      | [Link](https://linearmouse.app/) |
| navidrome-mbz   |🐧🍎| Navidrome, with MusicBrainz patches.                        | [Link](https://github.com/vs49688/navidrome) |
| raftools        |🐧🍎| League of Legends Legacy extraction utility                 | [Link](https://github.com/vs49688/RAFTools) |
| scroll-reverser |🍎  | Per-device scrolling prefs on macOS                         | [Link](https://pilotmoon.com/scrollreverser/) |
| vgmtrans        |🐧  | A tool to convert proprietary, sequenced videogame music to industry-standard formats | [Link](https://github.com/vgmtrans/vgmtrans) |
| mongodb_3_6-bin |🐧  | MongoDB 3.6, binary version                                 | [Link](https://www.mongodb.com/) |

### Games 🎮

| Package      |  | Description                                           | Link |
|--------------|--|-------------------------------------------------------|-----------------------------------------------------------|
| croc-lotg    |🐧| Croc! Legend of the Gobbos Definitive Edition[^1]     | [Link](#not-touching-that)                                |
| solar2       |🐧| Solar 2, Humble Bundle Linux version[^1]              | [Link](https://www.humblebundle.com/store/solar-2)        |   
| supermeatboy |🐧| Super Meat Boy, Humble Bundle Linux version[^1]       | [Link](https://www.humblebundle.com/store/super-meat-boy) |
| xash3d-fwgs  |🐧| xash3d-fwgs and games[^1]                             | [Link](https://github.com/FWGS/xash3d-fwgs)               |

### Utilities 🔨

| Package              |    | Description                                                      | Link                                                       |
|----------------------|----|------------------------------------------------------------------|------------------------------------------------------------|
| awesfx               |🐧  |An old and good AWE32-compatible SoundFont utility                | [Link](https://github.com/tiwai/awesfx)                    |
| crocutils            |🐧🍎| A small collection of utilities for Croc                         | [Link](https://github.com/vs49688/CrocUtils)               |
| extract-drs          |🐧🍎| AoE1 DRS extractor                                               | [Link](https://github.com/vs49688/extract-drs)             |
| extract-glb          |🐧🍎| DemonStar GLB extractor                                          | [Link](https://github.com/vs49688/extract-glb)             |
| hg659-voip-password  |🐧🍎| Huawei HG659 config decryption utility                           | [Link](https://github.com/Serivy/HG659-VOIP-Password)      |
| mailpump             |🐧🍎| A service that monitors a mailbox for messages and will automatically move them to another, usually on a different server     |
| offzip               |🐧🍎| Offset file unzipper                                             | [Link](https://aluigi.altervista.org/mytoolz.htm)          |
| pimidid              |🐧  | Small daemon to automatically connect MIDI devices to FluidSynth | [Link](https://github.com/vs49688/pimidid)                 |
| rom-parser           |🐧  | ROM Parser                                                       | [Link](https://github.com/awilliam/rom-parser)             |
| unifi-backup-decrypt |🐧🍎| UniFi backup decryption utility                                  | [Link](https://github.com/zhangyoufu/unifi-backup-decrypt) |

### Misc

| Package             |    | Description                                              | Link                                                     |
|---------------------|----|----------------------------------------------------------|----------------------------------------------------------|
| mangostwo-database  |🐧  | MangosTwo Database. Use `containers.mangostwo-*`         | [Link](https://www.getmangos.eu/bug-tracker/mangos-two/) |
| mangostwo-server    |🐧  | MangosTwo Server Binaries.  Use `containers.mangostwo-*` | [Link](https://www.getmangos.eu/bug-tracker/mangos-two/) |
| xboomer             |🐧  | Windows XP window decorations for KDE Plasma             | [Link](https://github.com/efskap/XBoomer)                |
| zane-scripts.*      |🐧🍎| Personal scripts. Useless to you.                        | [Link](https://github.com/vs49688/scripts)               |

### MongoDB Versions

Ever since the switch to SSPL, the nixpkgs source builds aren't cached anymore at `cache.nixos.org`.
Here are MongoDB derivations based off the pre-built Ubuntu binaries. Note that most of these are insecure and
shouldn't be used in production. These are intended to be used for migration purposes only.

| Package             |    | Description | Link                                                               |
|---------------------|----|-------------|--------------------------------------------------------------------|
| mongodb_3_6-bin     |🐧  | MongoDB 3.6 | [Link](https://www.mongodb.com/download-center/community/releases) |
| mongodb_4_0-bin     |🐧  | MongoDB 4.0 | [Link](https://www.mongodb.com/download-center/community/releases) |
| mongodb_4_2-bin     |🐧  | MongoDB 4.2 | [Link](https://www.mongodb.com/download-center/community/releases) |
| mongodb_4_4-bin     |🐧  | MongoDB 4.4 | [Link](https://www.mongodb.com/download-center/community/releases) |
| mongodb_5_0-bin     |🐧  | MongoDB 5.0 | [Link](https://www.mongodb.com/download-center/community/releases) |
| mongodb_6_0-bin     |🐧  | MongoDB 6.0 | [Link](https://www.mongodb.com/download-center/community/releases) |


[^1]: Most likely useless to you. Requires private sources.

## Usage

### Nix

```
nix-build -A <packagename>
```

### NixOS, system-wide

Assuming this is in a git submodule called `nix-repo`, add this to
your `configuration.nix`:

```nix
imports = [
  /* your imports */
] ++ (import ./nix-repo/modules);

nixpkgs.overlays = [
  /* your overlays */
  (import ./nix-repo/overlay.nix)
];
```

## License
This project is licensed under the [Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0):

Copyright &copy; 2024 [Zane van Iperen](https://zanevaniperen.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.