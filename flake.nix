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
        wrapScript = name: ''
          chmod u+x $out/bin/${name}

          # Wrap the script to ensure Ruby and gems are available
          wrapProgram $out/bin/${name} \
            --set PATH ${gems.wrappedRuby}/bin
        '';
        pkgs = nixpkgs.legacyPackages.${system};
        gems = pkgs.bundlerEnv {
          name = "gemset";
          gemdir = ./.;
        };
        bin = pkgs.stdenv.mkDerivation {
          pname = "ruby-bin";
          version = "1.0.0";
          src = ./.;
          buildInputs = [
            gems
            gems.wrappedRuby
          ];
          installPhase = ''
            mkdir -p $out/bin
            cp -r ${./bin}/* $out/bin/

            ${wrapScript "manners"}
          '';
          nativeBuildInputs = [ pkgs.makeWrapper ];
        };
      in
      {
        packages.default = bin;

        devShells.default =
          with pkgs;
          mkShell {
            buildInputs = [
              gems
              gems.wrappedRuby
            ];
          };
      }
    );
}
