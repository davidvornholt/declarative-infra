{ config, lib, ... }:

let cfg = config.davidvornholt.podman;
in {
  options.davidvornholt.podman.enable =
    lib.mkEnableOption "Podman container runtime";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.oci-containers.backend = "podman";
  };
}
