{ config, lib, pkgs, ... }:

let cfg = config.dv.base;
in {
  options.dv.base = {
    enable = lib.mkEnableOption
      "hardened base configuration for a single-purpose server";

    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "david";
      description = "Non-root administrative user.";
    };

    adminSshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Authorized SSH public keys for the admin user.";
    };

    deploySshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Authorized SSH public keys for root deploy access.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" cfg.adminUser ];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    users.users.${cfg.adminUser} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = cfg.adminSshKeys;
    };

    users.users.root.openssh.authorizedKeys.keys = cfg.deploySshKeys;

    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        KbdInteractiveAuthentication = false;
      };
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };

    environment.systemPackages = with pkgs; [
      curl
      dig
      gitMinimal
      htop
      jq
      lsof
      rsync
      vim
    ];

    services.journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=14day
    '';
  };
}
