with import <nixpkgs> {};

runCommand "epi" {} ''
  mkdir -p $out/bin
  echo "#!/usr/bin/env bash
  episteme -repo ~/src/apoptosis/episteme" > $out/bin/epi
  chmod +x $out/bin/epi
''
