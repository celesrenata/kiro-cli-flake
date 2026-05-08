{
  description = "Kiro CLI - AI-powered command line interface";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
            x86_64-linux = { variant = "x86_64"; hash = "sha256-HrWsMh2MxzWO9BL8045UYVcLvWg+3ySgKXVR31yLSJs="; };
            aarch64-linux = { variant = "aarch64"; hash = "sha256-zXZPCbAJp441wf0SRe/R0CxHC8p7wBK9Ako1xf5FkCk="; };
          }.${system};
          
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "latest";

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
              cp bin/* $out/bin/
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
