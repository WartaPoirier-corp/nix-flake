{ pkgs, rust }:

let
  milpertuisSrc = fetchTarball {
    url = "https://wp-corp.eu.org/milpertuis-0.1.0-beta7.tar.gz";
    sha256 = "11asrvqnpw88527hmasg4j03vgp0jhikhmjx2d8qr00f7i1rygyp";
  };
in {
  milpertuis = rust.buildRustPackage {
    nativeBuildInputs = with pkgs; [ perl ];
    pname = "milpertuis";
    version = "0.1.0-beta7";
    src = milpertuisSrc;
    cargoSha256 = "sha256-UR+3dgACODZz1jyrqIPRkCLzNcmVbrC0WEL57QZbg0Q=";
    doCheck = false;
    dontStrip = true;
    buildType = "debug";
    meta = with pkgs.lib; {
      description = "Pijul-based software forge";
      homepage = "https://m.wp-corp.eu.org/";
      license = licenses.agpl3; # actually: TBD
    };
  };

  milpertuis-front = pkgs.buildNpmPackage {
    pname = "milpertuis-front";
    version = "0.1.0-beta7";
    src = milpertuisSrc;
    buildPhase = "npm exec parcel build assets/styles/style.scss";
    npmDepsHash = "sha256-WUsK+90mTJG/p75mhbEf8pnAwZ2l9o1tHDvzjgVklok=";
    meta = with pkgs.lib; {
      description = "Pijul-based software forge - front-end";
      homepage = "https://m.wp-corp.eu.org/";
      license = licenses.agpl3; # actually: TBD
    };
  };
}
