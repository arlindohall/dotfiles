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
        wrapScript = (
          name:
          let
            path = ./. + "/bin/${name}";
            output = "$out/bin/${name}";
            makeBinPath = nixpkgs.lib.strings.makeBinPath;
          in
          ''
            cp ${path} ${output}
            chmod u+x  ${output}
            # Wrap the script to ensure Ruby and gems are available
            wrapProgram ${output} \
              --set PATH ${
                makeBinPath [
                  gems.wrappedRuby
                  pkgs.ripgrep
                  "$out"
                ]
              }
          ''
        );
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
            cp -r ${./bin/lib} $out/bin/lib
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
              ripgrep
            ];
          };
      }
    );
}
