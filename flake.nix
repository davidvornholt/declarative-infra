{
  description =
    "Reusable declarative infrastructure: NixOS modules consumed as a flake input, OpenTofu modules consumed as pinned module sources";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, treefmt-nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in {
      nixosModules = {
        base = ./modules/base.nix;
        backup = ./modules/backup.nix;
        caddy = ./modules/caddy.nix;
        github-runner = ./modules/github-runner.nix;
        podman = ./modules/podman.nix;
        postgres = ./modules/postgres.nix;
        default.imports = [
          ./modules/base.nix
          ./modules/backup.nix
          ./modules/caddy.nix
          ./modules/github-runner.nix
          ./modules/podman.nix
          ./modules/postgres.nix
        ];
      };

      # Eval-only smoke coverage: `nix flake check` evaluates this host with
      # every module enabled, so option regressions fail fast without a build.
      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ self.nixosModules.default ./example/configuration.nix ];
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
