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
          
          # Determine which variant to use based on system
          variant = if system == "x86_64-linux" then "x86_64" else "aarch64";
          
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "latest";

            src = pkgs.fetchzip {
              url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-${variant}-linux.zip";
              stripRoot = false;
              hash = "sha256-a/os1d4rOR/e4EAfPj4j932YHErPIOtN/4JXI8kCpOM=";
            };

            nativeBuildInputs = [ pkgs.autoPatchelfHook ];

            buildInputs = with pkgs; [
              stdenv.cc.cc.lib
            ];

            installPhase = ''
              runHook preInstall
              
              mkdir -p $out/bin
              cp -r kirocli/* $out/
              
              if [ -f $out/bin/kiro-cli ]; then
                chmod +x $out/bin/kiro-cli
              fi
              
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
