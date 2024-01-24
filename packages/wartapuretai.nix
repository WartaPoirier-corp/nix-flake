{ pkgs, rust }:

{
  wartapuretai = rust.buildRustPackage {
    crateName = "warta-quiz";
    pname = "wartapuretai";
    version = "0.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "WartaPoirier-corp";
      repo = "Wartapuretai";
      rev = "3b630e792793b2116b9d1bc371cbfcce0e6bfc27";
      sha256 = "sha256-LvBvTHezK7BHkyg479Ry+uZ+4PteTP1aAt7KFELCeb0=";
    };
    cargoSha256 = "sha256-4mfkm/HJPFi0flyfSf9qfyhqStVjaNGUBOp20piGeYA=";
    postInstall = ''
      cp -r $src/static/ $out/
      cp -r $src/templates/ $out/
      cp questions.json $out/
    '';
    meta = with pkgs.lib; {
      description = "Purity test";
      homepage = "https://github.com/WartaPoirier-corp/WartaPuretai/";
      license = licenses.agpl3;
    };
  };
}