# default.nix
let
  pkgs = import <nixpkgs> {};
in
  pkgs.callPackage ./sea-greeter-litarvan.nix {}
