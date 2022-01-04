{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "episteme" {} ''
  mkdir -p $out/bin
  cp ${./episteme} $out/bin/episteme
  chmod +x $out/bin/episteme
''