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
          variant = if system == "x86_64-linux" then "x86_64" else "aarch64";
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "kiro-cli";
            version = "latest";

            src = pkgs.fetchzip {
              url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-${variant}-linux.zip";
              hash = "sha256-beCuI02yPytsIwHL0xrdZuQFxT+SUVMGl/40SOgJ9UU=";
            };

            nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

            buildInputs = with pkgs; [
              stdenv.cc.cc.lib
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              install -m755 bin/kiro-cli $out/bin/
              install -m755 bin/kiro-cli-chat $out/bin/
              install -m755 bin/kiro-cli-term $out/bin/

              makeWrapper $out/bin/kiro-cli $out/bin/q --add-flags "--show-legacy-warning"
              makeWrapper $out/bin/kiro-cli $out/bin/qchat --add-flags "--show-legacy-warning chat"

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
