{ config, lib, ... }:

let
  cfg = config.davidvornholt.postgres;
  databases =
    lib.unique (cfg.appDatabases ++ lib.attrNames cfg.databaseSystemUsers);
  systemUsersForDatabase = database:
    cfg.databaseSystemUsers.${database} or cfg.appSystemUsers;
in {
  options.davidvornholt.postgres = {
    enable = lib.mkEnableOption "host-managed PostgreSQL";

    appDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Application databases and matching local users.";
    };

    appSystemUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description =
        "System users allowed to peer-authenticate as application database users.";
    };

    databaseSystemUsers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description =
        "Per-database system users allowed to peer-authenticate as the matching application database role.";
      example = { app_pr_47 = [ "app-pr-47" ]; };
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = databases;
      ensureUsers = map (name: {
        inherit name;
        ensureDBOwnership = true;
      }) databases;
      authentication = lib.mkForce ''
        local all postgres peer
        ${lib.concatMapStringsSep "\n" (name: ''
          local ${name} ${name} peer map=${name}
        '') databases}
        local all all peer
        host all all 127.0.0.1/32 scram-sha-256
        host all all ::1/128 scram-sha-256
      '';
      identMap = lib.concatMapStringsSep "\n" (name:
        lib.concatMapStringsSep "\n" (systemUser: ''
          ${name} ${systemUser} ${name}
        '') (systemUsersForDatabase name)) databases;
    };
  };
}
