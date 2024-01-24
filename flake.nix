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

        defaultPackage = self.packages.${system}.wartid-server;
        devShell = pkgs.mkShell {
          name = "wartid";
          buildInputs = with pkgs; [ fenix.packages.${system}.minimal.cargo fenix.packages.${system}.minimal.rustc diesel-cli postgresql ];
          shellHook = ''
            export PGDATA=$PWD/postgres_data
            export PGHOST=$PWD/postgres
            export LOG_PATH=$PWD/postgres/LOG
            export PGDATABASE=wartid
            export DATABASE_URL="postgresql:///wartid?host=$PGHOST"
            if [ ! -d $PGHOST ]; then
              mkdir -p $PGHOST
            fi
            if [ ! -d $PGDATA ]; then
              echo 'Initializing postgresql database...'
              initdb $PGDATA --auth=trust >/dev/null
              pg_ctl start -l $LOG_PATH -o "-c listen_addresses= -k $PGHOST"
              createuser -d wartid
              createdb -O wartid wartid
            else
              pg_ctl start -l $LOG_PATH -o "-c listen_addresses= -k $PGHOST"
            fi
          '';
        };
      }) // {
        nixosModule = { config, pkgs, lib, ... }:
          (import ./services/milpertuis.nix { inherit config pkgs lib; }) //
          (import ./services/wartid.nix { inherit config pkgs lib; }) // 
          (import ./services/wartapuretai.nix { inherit config pkgs lib; }) //
          (import ./services/wjtp.nix { inherit config pkgs lib; });
  };
}
