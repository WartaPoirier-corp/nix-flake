{ pkgs, rust }:

let
  wartid-rev = "5bd5d50ddb4e898e9cd44cd45ba711cd6a8ac974";
  wartid-src = pkgs.fetchFromGitHub {
    owner = "WartaPoirier-corp";
    repo = "WartID";
    rev = wartid-rev;
    sha256 = "sha256-uUC3+EEf/wti18u8R4quSpnaFZSccW1NVqZbIJ4ePrM=";
  };
in
{
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
}