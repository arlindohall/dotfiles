{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        hashes = import ./hashes.nix;

        # Fetch a pre-built binary from GitHub Releases and install it.
        # The binary is named "<name>-<nix_system>" in the release assets.
        fetchBinary =
          name:
          let
            info = hashes.${system};
          in
          pkgs.stdenv.mkDerivation {
            pname = name;
            # Read version from the Cargo.toml of the crate.
            version =
              let
                raw = builtins.readFile ./rust/${name}/Cargo.toml;
                match = builtins.match ''.*\nversion = "([^"]+)".*'' raw;
              in
              builtins.elemAt match 0;
            src = pkgs.fetchurl {
              url = info.url;
              inherit (info) sha256;
            };
            dontUnpack = true;
            installPhase = ''
              mkdir -p $out/bin
              cp $src $out/bin/${name}
              chmod +x $out/bin/${name}
            '';
          };

        manners = fetchBinary "manners";
      in
      {
        packages.manners = manners;
        packages.default = manners;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.rustup
            pkgs.ripgrep
          ];
        };
      }
    );
}
