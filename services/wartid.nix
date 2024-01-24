{ config, pkgs, lib }:
let
  cfg = config.wartid;
in
with lib;
{
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
}