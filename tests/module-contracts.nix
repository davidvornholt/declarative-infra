{ disabled, example, pkgs }:

assert example.boot.loader.systemd-boot.enable;
assert example.networking.firewall.allowedTCPPorts == [ 22 80 443 ];
assert example.services.caddy.email == "acme@example.com";
assert !example.services.openssh.settings.PasswordAuthentication;
assert example.services.postgresql.ensureDatabases == [ "app" "app_pr_47" ];
assert example.systemd.timers.postgres-backup.timerConfig.OnCalendar
  == "hourly";
assert example.users.users.admin.isNormalUser;
assert example.virtualisation.oci-containers.backend == "podman";
assert example.virtualisation.podman.enable;
assert !disabled.services.caddy.enable;
assert !disabled.services.openssh.enable;
assert !disabled.services.postgresql.enable;
assert !disabled.virtualisation.podman.enable;

pkgs.runCommand "declarative-infra-module-contracts" { } ''
  touch "$out"
''
