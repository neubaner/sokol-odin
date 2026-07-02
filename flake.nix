{
  description = "Sokol Odin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # To support other platforms ./nix/build_sokol.nix has to change
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      sokolVersion = "0-unstable-2026-01-07";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          sokolPackages = pkgs.callPackage ./nix/build_sokol.nix { inherit sokolVersion; };
          sokolDerivations = nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) sokolPackages;
        in
        sokolDerivations
        // {
          sokol-all = pkgs.symlinkJoin {
            name = "sokol-all";
            paths = builtins.attrValues sokolDerivations;
          };
        }
      );
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          sokolAll = self.packages.${system}.sokol-all;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              odin
              libGL
              libx11
              libxi
              libxcursor
              alsa-lib
            ];

            shellHook = # bash
              ''
                export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
                  pkgs.lib.makeLibraryPath [
                    pkgs.libGL
                    pkgs.libxi
                    pkgs.libxcursor
                  ]
                }"

                for f in ${sokolAll}/lib/*; do
                  base="$(basename "$f")"
                  module="$(echo "$base" | sed -E 's/^sokol_([a-z]+)_.*/\1/')"
                  ln -sf "$f" "sokol/$module/$base"
                done
              '';
          };
        }
      );
    };
}
