# Eval-only example host exercising every module. Not deployable: the
# filesystem and hardware configuration are stubs for `nix flake check`.
_:

{
  networking.hostName = "example";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  dv.base = {
    enable = true;
    adminUser = "admin";
    adminSshKeys = [ ];
    deploySshKeys = [ ];
  };

  dv.caddy = {
    enable = true;
    acmeEmail = "acme@example.com";
  };

  dv.podman.enable = true;

  dv.postgres = {
    enable = true;
    appDatabases = [ "app" ];
    appSystemUsers = [ "app" ];
    databaseSystemUsers = { app_pr_47 = [ "app-pr-47" ]; };
  };

  dv.backup = {
    enable = true;
    postgresDatabases = [ "app" ];
  };

  dv.githubRunner = {
    enable = true;
    tokenFile = "/run/secrets/github-runner-token";
    url = "https://github.com/davidvornholt/nix-infra";
    name = "example-runner";
    labels = [ "example" ];
  };

  system.stateVersion = "25.05";
}
