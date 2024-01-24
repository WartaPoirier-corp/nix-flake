{ pkgs, rust }:

{
  wjtp = rust.buildRustPackage {
    crateName = "warta-juge-tes-potes";
    pname = "wjtp";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "WartaPoirier-corp";
      repo = "warta-juge-tes-potes";
      rev = "5eaed030a839011b85e273251edecaa693070432";
      sha256 = "sha256-/tBGXAAKUhC5RhU4mFn+qiXOF0J1ml3ORLsCcfIZrbw=";
    };
    cargoSha256 = "sha256-oC78EoVu9NvCJxIhqhTtEhXJJZ77Dt8O9zao39dsfKI=";
    postInstall = ''
      cp -r $src/static/ $out/
      cp questions.ron $out/
      cp funny_words.txt $out/
    '';
    meta = with pkgs.lib; {
      description = "Fun online game";
      homepage = "https://github.com/WartaPoirier-corp/warta-juge-tes-potes/";
      license = licenses.agpl3;
    };
  };
}