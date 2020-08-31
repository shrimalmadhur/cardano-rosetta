{ stdenv
, nix-inclusive
, nodejs
, nodePackages
, runtimeShell
, sources
, yarn
}:

let
  packageJSON = builtins.fromJSON (builtins.readFile ../cardano-rosetta-server/package.json);

  src = stdenv.mkDerivation {
    pname = "${packageJSON.name}-src";
    version = packageJSON.version;
    buildInputs = [ yarn nodejs ];
    src = nix-inclusive ./../cardano-rosetta-server [
      ../cardano-rosetta-server/yarn.lock
      ../cardano-rosetta-server/.yarnrc
      ../cardano-rosetta-server/package.json
      ../cardano-rosetta-server/packages-cache
      ../cardano-rosetta-server/tsconfig.json
      ../cardano-rosetta-server/tsconfig-dist.json
    ];
    buildCommand = ''
      mkdir -p $out
      cp -r $src/. $out/
      cd $out
      chmod -R u+w .
      yarn --offline --frozen-lockfile --non-interactive
    '';
  };

in stdenv.mkDerivation {
  pname = packageJSON.name;
  version = packageJSON.version;
  inherit src;
  buildInputs = [ nodejs yarn ];
  buildCommand = ''
    mkdir -p $out
    cp -r $src/. $out/
    chmod -R u+w $out
    patchShebangs $out

    cd $out

    yarn build
    find . -name node_modules -type d -print0 | xargs -0 rm -rf
    yarn --production --offline --frozen-lockfile --non-interactive

    mkdir -p $out/bin
    cat <<EOF > $out/bin/${packageJSON.name}
    #!${runtimeShell}
    exec ${nodejs}/bin/node $out/dist/src/server/index.js
    EOF
    chmod +x $out/bin/${packageJSON.name}
  '';
}