{ config, lib, ... }:

let cfg = config.davidvornholt.backup;
in {
  options.davidvornholt.backup = {
    enable = lib.mkEnableOption "local PostgreSQL dumps on a timer";

    postgresDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "PostgreSQL databases to dump locally.";
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "/var/backups/postgres";
      description = "Directory that receives the dumps.";
    };

    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 14;
      description = "Days to keep dumps before they are deleted.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${cfg.directory} 0750 postgres postgres -" ];

    systemd.services.postgres-backup = {
      description = "Create local PostgreSQL dumps";
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
      };
      path = [ config.services.postgresql.package ];
      script = ''
        set -eu
        timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
        ${lib.concatMapStringsSep "\n" (db: ''
          pg_dump --format=custom --file=${cfg.directory}/${db}-$timestamp.dump ${db}
        '') cfg.postgresDatabases}
        find ${cfg.directory} -type f -name '*.dump' -mtime +${
          toString cfg.retentionDays
        } -delete
      '';
    };

    systemd.timers.postgres-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };
  };
}
