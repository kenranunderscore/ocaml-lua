{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      perSystem = { config, pkgs, ... }: {
        packages.default = pkgs.ocaml-ng.ocamlPackages.buildDunePackage rec {
          pname = "ocaml-lua";
          version = "xyz";
          src = ./.;
          buildInputs = [ pkgs.lua5_1 ];
        };
        devShells.default =
          pkgs.mkShell { packages = [ pkgs.lua5_1 pkgs.pkg-config ]; };
      };
    };
}
