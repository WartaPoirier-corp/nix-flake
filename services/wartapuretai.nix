{ config, pkgs, lib, ... }:

let
  cfg = config.services.wartapuretai;
in
with lib;
{
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
  
  config.systemd.services.wartapuretai = mkIf cfg.enable {
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

  config.services.nginx.virtualHosts."${cfg.domain}" = mkIf cfg.enableNginx {
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
}