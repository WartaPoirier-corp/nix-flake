{ pkgs, rust }:

let
  milpertuisSrc = fetchTarball {
    url = "https://wp-corp.eu.org/milpertuis-0.1.0-beta5.tar.gz";
    sha256 = "128whi9fg1v0bks840f9pajdr67a5sq6m14lb0zag6y5h0crkw82";
  };
in {
  milpertuis = rust.buildRustPackage {
    nativeBuildInputs = with pkgs; [ perl ];
    pname = "milpertuis";
    version = "0.1.0-beta5";
    src = milpertuisSrc;
    cargoSha256 = "sha256-w5jbBSX3aEJ51nMXfAu+rILRNXXNpH1Mz2YsbnmRro8=";
    doCheck = false;
    meta = with pkgs.lib; {
      description = "Pijul-based software forge";
      homepage = "https://m.wp-corp.eu.org/";
      license = licenses.agpl3; # actually: TBD
    };
  };

  milpertuis-front = pkgs.buildNpmPackage {
    pname = "milpertuis-front";
    version = "0.1.0-beta5";
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
