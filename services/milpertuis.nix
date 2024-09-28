{ config, pkgs, lib, self, ... }:

let
  cfg = config.services.milpertuis;
  configFile = cfg: pkgs.writeText "config.toml"
    ''
      base_url = 'https://${cfg.domain}'
      ssh_host = '${cfg.domain}'
      database_url = '${cfg.databaseUrl}'
      cookies_key = '${cfg.cookiesKey}'
      listen_on = '127.0.0.1:3838'
      state_directory = '/var/lib/milpertuis'

      [mailer]
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
      default = "milpertuis";
    };
    group = mkOption {
      type = types.str;
      description = "System group. If set to `milpertuis`, it will be created.";
      default = "milpertuis";
    };
    package = mkPackageOption self.packages.${pkgs.system} "Milpertuis" {
      default = [ "milpertuis" ];
    };
    front-package = mkPackageOption self.packages.${pkgs.system} "Milpertuis" {
      default = [ "milpertuis-front" ];
    };
  };

  config.systemd.services.milpertuis = mkIf cfg.enable {
    description = "Milpertuis";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.package;
      StateDirectory = "milpertuis";
      ExecStart = "${cfg.package}/bin/milpertuis ${configFile cfg}";
      # This script is here and not in the milpertuis-shell service
      # because the later needs to start fast and this script should normally
      # ever run once
      ExecStartPre = pkgs.writeShellScript "milpertuis-generate-ssh-private-key"
        ''
        cd $STATE_DIRECTORY
        if [ ! -f ssh_host_ed25519_key ]; then
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N ""
        fi
        '';
      Type = "simple";
    };
  };

  # Template service, activated by socket (see the next section)
  # See `man 5 systemd.socket` for more information
  config.systemd.services.milpertuis-shell = mkIf cfg.enable {
    description = "Milpertuis SSH shell";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.package;
      StateDirectory = "milpertuis";
      ExecStart = "${cfg.package}/bin/milpertuis-shell-standalone --database-url ${cfg.databaseUrl} --projects-dir /var/lib/milpertuis/projects --key-file /var/lib/milpertuis/ssh_host_ed25519_key";
      Type = "simple";
    };
  };

  config.systemd.sockets.milpertuis-shell = mkIf cfg.enable {
    description = "Milpertuis SSH shell - activation socket";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "0.0.0.0:22" ]; # TODO: make it configurable?
  };

  config.networking.firewall.allowedTCPPorts = mkIf cfg.enable [ 22 ];

  config.services.nginx.virtualHosts."${cfg.domain}" = mkIf cfg.enableNginx {
    enableACME = true;
    forceSSL = true;
    root = "${cfg.package}";
    locations = {
      "/static/" = {
        alias = "${cfg.front-package}/lib/node_modules/milpertuis/dist/";
      };
      "/" = {
        proxyPass = "http://localhost:3838";
      };
    };
  };

  config.users.users.milpertuis = lib.mkIf (cfg.user == "milpertuis") {
    isSystemUser = true;
    home = cfg.package;
    inherit (cfg) group;
  };

  config.users.groups.${cfg.group}.members = lib.optional cfg.enableNginx config.services.nginx.user;
}
