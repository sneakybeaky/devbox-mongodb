{
  description = "MongoDB prebuilt binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }: let
    mongoVersion = "7.0.11";
    mongoBinaries = {
      "aarch64-darwin" = { #https://fastdl.mongodb.org/osx/mongodb-macos-arm64-7.0.11.tgz
        fileName = "mongodb-macos-arm64";
        sha256 = "1ysdrdsam36migchcmvqy45shj3r3lwc2nbidykil2qg27gkqflh";
      };
      "x86_64-darwin" = { # https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-7.0.11.tgz
        fileName = "mongodb-macos-x86_64";
        sha256 = "18nx1j89pfhdi2dydisfvjax6939grsbhk5va9pp91mn9palvf62";
      };
    };
    supportedSystems = builtins.attrNames mongoBinaries;
  in
    utils.lib.eachSystem supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mongoBinary = mongoBinaries.${system};
    in rec {
      packages.mongodb = pkgs.stdenv.mkDerivation {
        pname = "mongodb";
        version = mongoVersion;

        src = pkgs.fetchzip {
          url = "https://fastdl.mongodb.org/osx/${mongoBinary.fileName}-${mongoVersion}.tgz";
          sha256 = mongoBinary.sha256;
        };

        dontBuild = true;
        phases = ["installPhase"];
        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp $src/bin/mongod $out/bin/mongod
          cp $src/bin/mongos $out/bin/mongos


          runHook postInstall
        '';
      };
      packages.default = packages.mongodb;

      apps.mongodb = utils.lib.mkApp {
        drv = packages.mongodb;
      };
      apps.default = apps.mongodb;

    });
}