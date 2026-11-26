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
            x86_64-linux = { variant = "x86_64"; hash = "sha256-5DBlIxGMExjbpTIxatNfKtzBGXLRQtkMOLLZAj7xmq8="; };
            aarch64-linux = { variant = "aarch64"; hash = "sha256-XmqfrdgIGS2D08K3AM117hKYQ8WitdNlMRMenVDTl94"; };
          }.${system};
          
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "2.21.4";

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

              # As of kiro-cli 2.21.4 the release archive extracts to a
              # "kirocli/" directory containing a SINGLE ELF binary,
              # bin/kiro-cli (upstream consolidated the former
              # kiro-cli-chat / kiro-cli-term entrypoints into subcommands of
              # kiro-cli, and its own install.sh now installs only kiro-cli).
              # Install the real binary; autoPatchelfHook fixes its
              # interpreter/rpath.
              install -m 755 kirocli/bin/kiro-cli $out/bin/kiro-cli

              # Backwards-compat: earlier versions shipped a separate
              # kiro-cli-chat binary. The chat entrypoint is now `kiro-cli
              # chat`, so provide kiro-cli-chat as a thin wrapper that forwards
              # to it, keeping any existing references (desktop files, scripts,
              # PATH habits) working.
              cat > $out/bin/kiro-cli-chat <<EOF
              #!/bin/sh
              exec "$out/bin/kiro-cli" chat "\$@"
              EOF
              chmod 755 $out/bin/kiro-cli-chat

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
