{ config, lib, ... }:

let cfg = config.davidvornholt.caddy;
in {
  options.davidvornholt.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy";

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Contact email for ACME certificate registration.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
    };
  };
}
