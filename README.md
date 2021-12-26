# Personal Nix Packages Repository

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

Copyright &copy; 2021 [Zane van Iperen](https://zanevaniperen.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.