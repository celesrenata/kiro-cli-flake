# Kiro CLI Nix Flake

A Nix flake for [Kiro CLI](https://kiro.dev/docs/cli/installation/) - AWS's AI-powered command line interface.

## Note on Unfree Software

Kiro CLI is proprietary software. You need to use the `--impure` flag to allow unfree packages:

## Usage

### Run directly
```bash
nix run --impure github:celesrenata/kiro-cli-flake
```

### Install to profile
```bash
nix profile install --impure github:celesrenata/kiro-cli-flake
```

### Use in NixOS configuration
```nix
{
  inputs.kiro-cli.url = "github:celesrenata/kiro-cli-flake";
  
  outputs = { nixpkgs, kiro-cli, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        {
          environment.systemPackages = [ kiro-cli.packages.x86_64-linux.default ];
        }
      ];
    };
  };
}
```

## Supported Systems
- x86_64-linux
- aarch64-linux

## License
Kiro CLI is proprietary software by AWS.
