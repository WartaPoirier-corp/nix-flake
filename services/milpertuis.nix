{ config, pkgs, lib }:
let
  mpt = config.services.milpertuis;
  milpertuisDir = cfg: pkgs.writeText "config.toml"
    ''
      base_url = 'https://${cfg.domain}'
      database_url = '${cfg.databaseUrl}'
      cookies_key = '${cfg.cookiesKey}'
      listen_on = '127.0.0.1:3838'

      [mail]
      address = '${cfg.mailServer}'
      username = '${cfg.mailUser}'
      password = '${cfg.mailPassword}'
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
    cookiesKey = mkOption {
      type = types.str;
      description = "Key to encrypt secret cookies. Can be generated with `openssl rand -base64 32`";
    };
    mailUser = mkOption {
      type = types.str;
      description = "Mail user name";
    };
    mailPassword = mkOption {
      type = types.str;
      description = "Mail password";
    };
    mailServer = mkOption {
      type = types.str;
      description = "Mail server";
    };
  };

  config.systemd.services.milpertuis = mkIf mpt.enable {
    description = "Milpertuis";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      WorkingDirectory = milpertuisDir mpt;
      ExecStart = "${self.packages.${pkgs.system}.milpertuis}/bin/milpertuis";
      Type = "simple";
    };
  };

  config.services.nginx.virtualHosts."${mpt.domain}" = mkIf mpt.enableNginx {
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
}