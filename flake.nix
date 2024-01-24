{
  description = "WartID: the WartaPoirier authentication and authorization service";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.fenix.url = "github:figsoda/fenix?rev=f2ede107c26645dc1e96d3c0d9fdeefbdcc9eadb";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rust = pkgs.makeRustPlatform {
          inherit (fenix.packages.${system}.minimal) cargo rustc;
        };
      in {
        packages = (import ./packages/milpertuis.nix { inherit pkgs; }) //
          (import ./packages/wartid.nix { inherit pkgs rust; }) //
          (import ./packages/wartapuretai.nix { inherit pkgs rust; }) //
          (import ./packages/wjtp.nix { inherit pkgs rust; });
      })
    //
    {
      nixosModules.default = { config, pkgs, lib, ... }:
        (import ./services/milpertuis.nix { inherit config pkgs lib; }) //
        (import ./services/wartid.nix { inherit config pkgs lib; }) // 
        (import ./services/wartapuretai.nix { inherit config pkgs lib; }) //
        (import ./services/wjtp.nix { inherit config pkgs lib; });
    };
}
