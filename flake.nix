{
  description = "WartID: the WartaPoirier authentication and authorization service";

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
        wartid-rev = "5bd5d50ddb4e898e9cd44cd45ba711cd6a8ac974";
        wartid-src = pkgs.fetchFromGitHub {
          owner = "WartaPoirier-corp";
          repo = "WartID";
          rev = wartid-rev;
          sha256 = "sha256-uUC3+EEf/wti18u8R4quSpnaFZSccW1NVqZbIJ4ePrM=";
       };
      in {
        packages = {
          # Discord bot
          wartid-server-discord-bot = rust.buildRustPackage {
            crateName = "wartid-server-discord-bot";
            pname = "wartid-server-discord-bot";
            version = "0.2.0";
            src = wartid-src;
            workspace_member = "wartid-server-discord-bot";
            cargoSha256 = "sha256-/tWcMzWyiGKv/A30/QOoN7kWYtK9cb9gG2+WDwk4YFw=";
            buildInputs = with pkgs; [ postgresql ];
            meta = with pkgs.lib; {
              description = "Discord bot WartID authentication";
              homepage = "https://github.com/WartaPoirier-corp/WartID/";
              license = licenses.agpl3;
            };
          };

          # Server
          wartid-server = rust.buildRustPackage {
            GIT_REV = wartid-rev;
            crateName = "wartid-server";
            pname = "wartid-server";
            version = "0.2.0";
            src = wartid-src;
            workspace_member = "wartid-server";
            cargoSha256 = "sha256-/iw577H3I0Z2IK69qDa0WTKQ+ocGtqHSR2DM+iWZNag=";
            cargoBuildFlags = [ "--features" "discord_bot" ];
            buildInputs = with pkgs; [ postgresql ];
            postInstall = ''
              cp -r $src/wartid-server/static/ $out/
              cp -r $src/wartid-server/migrations/ $out/
            '';
            meta = with pkgs.lib; {
              description = "Discord bot WartID authentication";
              homepage = "https://github.com/WartaPoirier-corp/WartID/";
              license = licenses.agpl3;
            };
          };

          # WartaPuretai
          wartapuretai = rust.buildRustPackage {
            crateName = "warta-quiz";
            pname = "wartapuretai";
            version = "0.1.1";
            src = pkgs.fetchFromGitHub {
              owner = "WartaPoirier-corp";
              repo = "Wartapuretai";
              rev = "3b630e792793b2116b9d1bc371cbfcce0e6bfc27";
              sha256 = "sha256-LvBvTHezK7BHkyg479Ry+uZ+4PteTP1aAt7KFELCeb0=";
            };
            cargoSha256 = "sha256-4mfkm/HJPFi0flyfSf9qfyhqStVjaNGUBOp20piGeYA=";
            postInstall = ''
              cp -r $src/static/ $out/
              cp -r $src/templates/ $out/
              cp questions.json $out/
            '';
            meta = with pkgs.lib; {
              description = "Purity test";
              homepage = "https://github.com/WartaPoirier-corp/WartaPuretai/";
              license = licenses.agpl3;
            };
          };
          
          # WartaJugeTesPotes
          wjtp = rust.buildRustPackage {
            crateName = "warta-juge-tes-potes";
            pname = "wjtp";
            version = "0.1.0";
            src = pkgs.fetchFromGitHub {
              owner = "WartaPoirier-corp";
              repo = "warta-juge-tes-potes";
              rev = "ab6c3e7a6608352492e401a4e601f093ee3a3b8b";
              sha256 = "sha256-l3G4ocuV6spU0NReZlhAzj2EXurrDoubZJpJYFnwi84=";
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
        };

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
            cfg = config.services.wartid;
            puretaiCfg = config.services.wartapuretai;
            wjtpCfg = config.services.wjtp;
          in
          with lib;
          {
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
            options.services.wartapuretai = {
              enable = mkEnableOption "WartaPuretai";
              domain = mkOption {
                type = types.str;
                description = "The domain name on which the app is hosted";
              };
              enableNginx = mkOption {
                type = types.bool;
                default = true;
                description = "Wheter or not to add a nginx config for WartaPuretai";
              };
            };
            options.services.wartid = {
              enable = mkEnableOption "WartID server";
              enableDiscordBot = mkEnableOption "WartID Discord bot";
              db = {
                autoCreate = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    true if you want NixOS to handle the creation of the database for you, false if you want to do it manually.
                    In either case, you will need to enable services.postgres
                  '';
                };
                user = mkOption {
                  type = types.str;
                  default = "wartid";
                  description = "The database user";
                };
                password = mkOption {
                  type = types.str;
                  description = "The database password";
                };
                name = mkOption {
                  type = types.str;
                  default = "wartid";
                  description = "The database name";
                };
              };
              discordToken = mkOption {
                type = types.str;
                description = "The Discord token for the bot.";
              };
              discordAllowedGuilds = mkOption {
                type = types.listOf types.int;
                description = "Snowflake IDs of Guilds the bot accepts people from.";
              };
              domain = mkOption {
                type = types.str;
                description = "The domain name on which the app is hosted";
              };
              enableNginx = mkOption {
                type = types.bool;
                default = true;
                description = "Wheter or not to add a nginx config for WartID";
              };
            };

            config.systemd.tmpfiles.rules = mkIf cfg.enable [
              "d /tmp/wartid/ - wartid wartid - -"
            ];
            config.users.users.wartid = mkIf cfg.enable {
              group = "wartid";
            };
            config.users.groups.wartid = mkIf cfg.enable {};
            config.systemd.services.wartid-server = mkIf cfg.enable {
              description = "WartID server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                DISCORD_KEY_FILE = "/tmp/wartid/discord_jwt.key";
                DATABASE_URL = "postgres://${cfg.db.user}:${cfg.db.password}@localhost/${cfg.db.name}";
                HTTP_BASE_URL = "https://${cfg.domain}";
              };
              serviceConfig = {
                PreStart = "${pkgs.diesel-cli}/bin/diesel migration run --migration-dir ${self.packages.${pkgs.system}.wartid-server}/migrations";
                ExecStart = "${self.packages.${pkgs.system}.wartid-server}/bin/wartid-server";
                Type = "simple";
                User = "wartid";
                Group = "wartid";
              };
            };
            config.systemd.services.wartid-server-discord-bot = mkIf cfg.enableDiscordBot {
              description = "WartID server: Discord bot";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                DISCORD_KEY_FILE = "/tmp/wartid/discord_jwt.key";
                DISCORD_TOKEN = cfg.discordToken;
                DISCORD_ALLOWED_GUILDS = concatStringsSep "," (builtins.map builtins.toString cfg.discordAllowedGuilds);
                HTTP_BASE_URL = "https://${cfg.domain}";
              };
              serviceConfig = {
                ExecStart = "/${self.packages.${pkgs.system}.wartid-server-discord-bot}/bin/wartid-server-discord-bot";
                Type = "simple";
                User = "wartid";
                Group = "wartid";
              };
            };

            config.services.nginx.virtualHosts."${cfg.domain}" = mkIf cfg.enableNginx {
              enableACME = true;
              forceSSL = true;
              root = "${self.packages.${pkgs.system}.wartid-server}";
              locations = {
                "/static/" = {
                  alias = "${self.packages.${pkgs.system}.wartid-server}/static/";
                };
                "/" = {
                  proxyPass = "http://localhost:8000";
                };
              };
            };

            config.systemd.services.wartapuretai = mkIf puretaiCfg.enable {
              description = "WartaPuretai";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                ROCKET_PORT = "8088";
              };
              serviceConfig = {
                WorkingDirectory = "${self.packages.${pkgs.system}.wartapuretai}/";
                ExecStart = "${self.packages.${pkgs.system}.wartapuretai}/bin/warta-quiz";
                Type = "simple";
              };
            };

            config.services.nginx.virtualHosts."${puretaiCfg.domain}" = mkIf puretaiCfg.enableNginx {
              enableACME = true;
              forceSSL = true;
              root = "${self.packages.${pkgs.system}.wartapuretai}";
              locations = {
                "/static/" = {
                  alias = "${self.packages.${pkgs.system}.wartapuretai}/static/";
                };
                "/" = {
                  proxyPass = "http://localhost:8088";
                };
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
          };
      };
}
