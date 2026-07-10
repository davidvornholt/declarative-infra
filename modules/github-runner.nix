{ config, lib, pkgs, ... }:

let cfg = config.dv.githubRunner;
in {
  options.dv.githubRunner = {
    enable = lib.mkEnableOption "GitHub Actions runner for trusted jobs";

    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to a GitHub runner registration token or PAT.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      description =
        "Repository or organization URL this runner registers against.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      description = "GitHub runner and systemd service name.";
    };

    labels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra labels used to target this runner from workflows.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.github-runner;
      defaultText = lib.literalExpression "pkgs.github-runner";
      description = "GitHub runner package to run.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [ curl jq openssh rsync unzip ];
      defaultText =
        lib.literalExpression "with pkgs; [ curl jq openssh rsync unzip ]";
      description = "Extra packages available to runner jobs.";
    };

    serviceOverrides = lib.mkOption {
      type = lib.types.attrs;
      default = {
        CPUQuota = "600%";
        MemoryHigh = "8G";
        MemoryMax = "12G";
      };
      description = "systemd service overrides for the runner unit.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;

    services.github-runners.${cfg.name} = {
      enable = true;
      inherit (cfg) name url tokenFile package extraPackages;
      extraLabels = cfg.labels;
      replace = true;
      extraEnvironment = {
        NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
        NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
      };
      inherit (cfg) serviceOverrides;
    };
  };
}
