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
            x86_64-linux = { variant = "x86_64"; hash = "sha256-Dq7WSGDg8+cRFwkKw2OYCV0Y5eW9GFChPz7zCn6EnhM="; };
            aarch64-linux = { variant = "aarch64"; hash = "sha256-ZN2UM0sphpUeFuuH6KyRC0sFwTnTgF/059WLIV3vSmQ="; };
          }.${system};
          
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "2.21.1";

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

              # The release archive extracts to a "kirocli/" directory containing
              # bin/{kiro-cli,kiro-cli-chat,kiro-cli-term} plus "q"/"qchat" wrapper
              # scripts that hardcode $HOME/.local/bin paths. Install only the real
              # ELF binaries; autoPatchelfHook will fix up their interpreter/rpath.
              install -m 755 kirocli/bin/kiro-cli      $out/bin/kiro-cli
              install -m 755 kirocli/bin/kiro-cli-chat $out/bin/kiro-cli-chat
              install -m 755 kirocli/bin/kiro-cli-term $out/bin/kiro-cli-term

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
