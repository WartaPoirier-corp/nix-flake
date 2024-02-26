{
  description = "WartID: the WartaPoirier authentication and authorization service";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.fenix.url = "github:figsoda/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rust = pkgs.makeRustPlatform {
          inherit (fenix.packages.${system}.minimal) cargo rustc;
        };
        # Nixos 23.11 packages Rust 1.73 but we need more recent versions
        # (at least for milpertuis)
        rustStable = pkgs.makeRustPlatform {
          inherit (fenix.packages.${system}.stable) cargo rustc;
        };
      in {
        packages = (import ./packages/milpertuis.nix { inherit pkgs; rust = rustStable; }) //
          (import ./packages/wartid.nix { inherit pkgs rust; }) //
          (import ./packages/wartapuretai.nix { inherit pkgs rust; }) //
          (import ./packages/wjtp.nix { inherit pkgs rust; });
      })
    //
    {
      nixosModules.default = { config, pkgs, lib, ... }:
      {
        imports = [
          (import ./services/milpertuis.nix { inherit config pkgs lib self; })
          (import ./services/wartid.nix { inherit config pkgs lib self; })
          (import ./services/wartapuretai.nix { inherit config pkgs lib self; })
          (import ./services/wjtp.nix { inherit config pkgs lib self; })
        ];
      };
    };
}
