{ config, pkgs, lib }:

let
  cfg = config.services.milpertuis;
  configFile = cfg: pkgs.writeText "config.toml"
    ''
      base_url = 'https://${cfg.domain}'
      database_url = '${cfg.databaseUrl}'
      cookies_key = '${cfg.cookiesKey}'
      listen_on = '127.0.0.1:3838'
      state_directory = '/var/lib/milpertuis'

      [mail]
      address = '${cfg.mail.address}'
      username = '${cfg.mail.user}'
      password = '${cfg.mail.password}'
    '';
in
with lib;
{
  options.services.milpertuis = {
    enable = mkEnableOption "Milpertuis";
    domain = mkOption {
      type = types.str;
      description = "The domain name";
    };
    enableNginx = mkOption {
      type = types.bool;
      default = true;
      description = "Wheter or not to add a nginx config";
    };
    databaseUrl = mkOption {
      type = types.str;
      description = "PostgreSQL database URL";
    };
    # TODO: init it automatically if needed with a script
    # See https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/web-apps/mastodon.nix#L667
    cookiesKey = mkOption {
      type = types.str;
      description = "Key to encrypt secret cookies. Can be generated with `openssl rand -base64 32`";
    };
    mail = {
      user = mkOption {
        type = types.str;
        description = "Mail user name";
      };
      password = mkOption {
        type = types.str;
        description = "Mail password";
      };
      address = mkOption {
        type = types.str;
        description = "Mail server address";
      };
    };
    user = mkOption {
      type = types.str;
      description = "System user. If set to `milpertuis`, it will be created.";
    };
    group = mkOption {
      type = types.str;
      description = "System group. If set to `milpertuis`, it will be created.";
    };
  };

  config.systemd.services.milpertuis = mkIf cfg.enable {
    description = "Milpertuis";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = self.packages.${pkgs.system}.milpertuis;
      StateDirectory = "milpertuis";
      ExecStart = "${self.packages.${pkgs.system}.milpertuis}/bin/milpertuis ${configFile cfg}";
      Type = "simple";
    };
  };

  config.services.nginx.virtualHosts."${cfg.domain}" = mkIf cfg.enableNginx {
    enableACME = true;
    forceSSL = true;
    root = "${self.packages.${pkgs.system}.milpertuis}";
    locations = {
      "/static/" = {
        alias = "${self.packages.${pkgs.system}.milpertuis-front}/lib/node_modules/milpertuis/dist/";
      };
      "/" = {
        proxyPass = "http://localhost:3838";
      };
    };
  };

  config.users.users.milpertuis = lib.mkIf (cfg.user == "milpertuis") {
    isSystemUser = true;
    home = self.packages.${pkgs.system}.milpertuis;
    inherit (cfg) group;
  };

  config.users.groups.${cfg.group}.members = lib.optional cfg.enableNginx config.services.nginx.user;
}
