# default.nix
let
  pkgs = import <nixpkgs> {};
  litarvan-theme = pkgs.callPackage ./litarvan-theme.nix {};
in
  pkgs.callPackage ./sea-greeter.nix {
        theme = litarvan-theme;
  }
