{ config, lib, pkgs }:

let
  cfg = config.services.wjtp;
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
  
  config.systemd.services.wjtp = mkIf cfg.enable {
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

  config.services.nginx.virtualHosts."${cfg.domain}" = mkIf cfg.enableNginx {
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
}