{
  description = "Kiro CLI - AI-powered command line interface";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          
          archInfo = {
            x86_64-linux = { variant = "x86_64"; hash = "sha256-p3C9Etsy4An4EBVQjhyM7QBkO+MuPgOxXRm4itz+59E="; };
            aarch64-linux = { variant = "aarch64"; hash = "sha256-POm4q1Zqe3a+Tq2lccSYNwUlU5G/sN8fXOvTOauh6rg="; };
          }.${system};
          
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "2.10.0";

            src = pkgs.fetchzip {
              url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-${archInfo.variant}-linux.zip";
              stripRoot = false;
              hash = archInfo.hash;
            };

            nativeBuildInputs = [ pkgs.autoPatchelfHook ];

            buildInputs = with pkgs; [
              stdenv.cc.cc.lib
              xz
            ];

            installPhase = ''
              runHook preInstall
              
              mkdir -p $out/bin
              cp kirocli/bin/* $out/bin/
              chmod +x $out/bin/*
              
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Kiro CLI - AI-powered command line interface by AWS";
              homepage = "https://kiro.dev";
              license = licenses.unfree;
              platforms = [ "x86_64-linux" "aarch64-linux" ];
            };
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/kiro-cli";
        };
      });
    };
}
