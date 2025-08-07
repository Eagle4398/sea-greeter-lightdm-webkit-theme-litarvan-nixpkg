# default.nix
let
  pkgs = import <nixpkgs> {};
  litarvan-theme = pkgs.callPackage ./litarvan-theme.nix {};
  nature-images = pkgs.callPackage ./nature-images.nix {};
in
  pkgs.callPackage ./sea-greeter.nix {
        theme = litarvan-theme;
        backgrounds = nature-images;
  }

