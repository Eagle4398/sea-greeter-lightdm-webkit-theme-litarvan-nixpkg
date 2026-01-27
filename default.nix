# default.nix
let
  pkgs = import <nixpkgs> { };
  # litarvan-theme = pkgs.callPackage ./litarvan-theme.nix {};
  litarvan-theme = pkgs.stdenv.mkDerivation {
    pname =
      "lightdm-webkit-theme-litarvan"; 
    version = "3.3.0";
    src = ../litarvan-theme-update/dist;

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };
  nature-images = pkgs.stdenvNoCC.mkDerivation {
    name = "nature-images";
    src = pkgs.fetchurl {
      url =
        "https://www.dropbox.com/scl/fi/t6gnddx3lgrov56nj30de/nature-images.zip?rlkey=0t2jo103z63udj6emaiewgsth&st=y3poqskl&dl=1";
      sha256 = "sha256-XF3pPcVRE84wnesxO8aDFpsL81NK2YBWfnDr6ge2+SY=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;
    buildPhase = ''
      unzip $src
    '';
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in pkgs.callPackage ./sea-greeter2.nix {
  theme = litarvan-theme;
  backgrounds = nature-images;
  enableHWAcceleration = false;
}

