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
        packages = ({
          # WartaJugeTesPotes
          wjtp = rust.buildRustPackage {
            crateName = "warta-juge-tes-potes";
            pname = "wjtp";
            version = "0.1.0";
            src = pkgs.fetchFromGitHub {
              owner = "WartaPoirier-corp";
              repo = "warta-juge-tes-potes";
              rev = "5eaed030a839011b85e273251edecaa693070432";
              sha256 = "sha256-/tBGXAAKUhC5RhU4mFn+qiXOF0J1ml3ORLsCcfIZrbw=";
            };
            cargoSha256 = "sha256-oC78EoVu9NvCJxIhqhTtEhXJJZ77Dt8O9zao39dsfKI=";
            postInstall = ''
              cp -r $src/static/ $out/
              cp questions.ron $out/
              cp funny_words.txt $out/
            '';
            meta = with pkgs.lib; {
              description = "Fun online game";
              homepage = "https://github.com/WartaPoirier-corp/warta-juge-tes-potes/";
              license = licenses.agpl3;
            };
          };
        })
        // (import ./packages/milpertuis.nix { inherit pkgs; })
        // (import ./packages/wartid.nix { inherit pkgs rust; })
        // (import ./packages/wartapuretai.nix { inherit pkgs rust; });

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
          let
            wjtpCfg = config.services.wjtp;
          in
          with lib;
          ({
            options.services.wjtp = {
              enable = mkEnableOption "WartaJugeTesPotes";
              domain = mkOption {
                type = types.str;
                description = "The domain name on which the app is hosted";
              };
              enableNginx = mkOption {
                type = types.bool;
                default = true;
                description = "Wheter or not to add a nginx config for WartaJugeTesPotes";
              };
            };
            
            config.systemd.services.wjtp = mkIf wjtpCfg.enable {
              description = "WartaJugeTesPotes";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                ROCKET_PORT = "8089";
              };
              serviceConfig = {
                WorkingDirectory = "${self.packages.${pkgs.system}.wjtp}/";
                ExecStart = "${self.packages.${pkgs.system}.wjtp}/bin/warta-juge-tes-potes";
                Type = "simple";
              };
            };

            config.services.nginx.virtualHosts."${wjtpCfg.domain}" = mkIf wjtpCfg.enableNginx {
              enableACME = true;
              forceSSL = true;
              root = "${self.packages.${pkgs.system}.wjtp}";
              locations = {
                "/static/" = {
                  alias = "${self.packages.${pkgs.system}.wjtp}/static/";
                };
                "/" = {
                  proxyPass = "http://localhost:8089";
                };
                "/ws" = {
                  proxyPass = "http://localhost:8008";
                  proxyWebsockets = true;
                };
              };
            };
      })
      // (import ./services/milpertuis.nix { inherit config pkgs lib; })
      // (import ./services/wartid.nix { inherit config pkgs lib; })
      // (import ./services/wartapuretai.nix { inherit config pkgs lib; });
  };
}
