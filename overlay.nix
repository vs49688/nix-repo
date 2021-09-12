self: super: {
  crocutils = super.callPackage ./pkgs/crocutils { };

  extract-drs = super.callPackage ./pkgs/extract-drs { };

  extract-glb = super.callPackage ./pkgs/extract-glb { };

  pimidid = super.callPackage ./pkgs/pimidid { };

  jdownloader = super.callPackage ./pkgs/jdownloader { };

  mangostwo-server = super.callPackage ./pkgs/mangostwo-server { };

  mangostwo-database = super.callPackage ./pkgs/mangostwo-database { };

  ancestris = super.callPackage ./pkgs/ancestris { };

  k0sctl = super.callPackage ./pkgs/k0sctl { };

  zane-scripts = super.callPackages ./pkgs/zane-scripts { };

  terraform-bin_1_0 = super.callPackage ./pkgs/terraform-bin_1_0 {};

  terraform-bin = self.terraform-bin_1_0;

  containers = super.callPackages ./containers { };
}
