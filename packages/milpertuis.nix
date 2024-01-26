{ pkgs }:

let
  milpertuisSrc = fetchTarball {
    url = "https://wp-corp.eu.org/milpertuis-0.1.0-beta3.tar.gz";
    sha256 = "1ib9wwf81ijgsc10cn5ml38zq925ah15zdpy611bw3mjx7xgdcyw";
  };
in {
  milpertuis = pkgs.rustPlatform.buildRustPackage {
    pname = "milpertuis";
    version = "0.1.0-beta3";
    src = milpertuisSrc;
    cargoSha256 = "sha256-6Lh/aP+ZlUyTVDGZ4WCLzilimFHHql8CcDjBtXu7n+0=";
    doCheck = false;
    meta = with pkgs.lib; {
      description = "Pijul-based software forge";
      homepage = "https://m.wp-corp.eu.org/";
      license = licenses.agpl3; # actually: TBD
    };
  };

  milpertuis-front = pkgs.buildNpmPackage {
    pname = "milpertuis-front";
    version = "0.1.0";
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
