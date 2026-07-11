# Eval-only example host exercising every module. Not deployable: the
# filesystem and hardware configuration are stubs for `nix flake check`.
_:

{
  networking.hostName = "example";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  davidvornholt.base = {
    enable = true;
    adminUser = "admin";
    adminSshKeys = [ ];
    deploySshKeys = [ ];
  };

  davidvornholt.caddy = {
    enable = true;
    acmeEmail = "acme@example.com";
  };

  davidvornholt.podman.enable = true;

  davidvornholt.postgres = {
    enable = true;
    appDatabases = [ "app" ];
    appSystemUsers = [ "app" ];
    databaseSystemUsers = { app_pr_47 = [ "app-pr-47" ]; };
  };

  davidvornholt.backup = {
    enable = true;
    postgresDatabases = [ "app" ];
  };

  davidvornholt.githubRunner = {
    enable = true;
    tokenFile = "/run/secrets/github-runner-token";
    url = "https://github.com/davidvornholt/declarative-infra";
    name = "example-runner";
    labels = [ "example" ];
  };

  system.stateVersion = "25.05";
}
