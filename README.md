# declarative-infra

Reusable declarative infrastructure, the companion to
[davidvornholt/standards](https://github.com/davidvornholt/standards): generic
NixOS modules consumed as a flake input, and generic OpenTofu modules consumed
as pinned module sources.

## Philosophy

Standards and infrastructure have inverted topologies, so they use different
reuse mechanisms:

- **Standards** is one template → many repos. Consumers must physically contain
  the files, so `standards` ships a file-sync engine and deliberately tracks
  `main` unpinned.
- **Infrastructure** is many repos → one host. A host is a singleton with
  state, hardware, and secrets, so nothing is copied: consumers reference this
  repo through Nix flake inputs and OpenTofu module sources, which provide
  pinning (`flake.lock`, `?ref=`), integrity hashing, and reviewable updates
  natively. Infrastructure is **always pinned** — a module change must never
  reach a production host without a lock-file diff in a reviewed PR.

The split across the three layers:

- **standards** owns the rules (the agent operating contract, including the
  `declarative-infrastructure` skill).
- **declarative-infra** owns the building blocks (this repo).
- **Each host's repo** owns one host's truth: flake composition and pins,
  hardware configuration, disko layout, SOPS secrets, OpenTofu root stacks and
  state, and app-specific modules.

No host definitions, secrets, or provider credentials live here.

## NixOS modules

All options are namespaced under `davidvornholt.*` (matching the `@davidvornholt` package
scope in standards). Every module is gated behind an `enable` option;
`nixosModules.default` imports them all.

| Module | Options | Provides |
| --- | --- | --- |
| `base` | `davidvornholt.base.*` | Hardened single-purpose server baseline: flakes, GC, systemd-boot, admin + deploy SSH users, sshd hardening, fail2ban, firewall (22/80/443), journald limits, core CLI tools. |
| `caddy` | `davidvornholt.caddy.*` | Caddy reverse proxy with an ACME contact email (`acmeEmail` is required). |
| `podman` | `davidvornholt.podman.*` | Podman with DNS-enabled default network as the `oci-containers` backend. |
| `postgres` | `davidvornholt.postgres.*` | Host-managed PostgreSQL with per-database peer authentication for application system users (`appDatabases`, `appSystemUsers`, `databaseSystemUsers`). |
| `backup` | `davidvornholt.backup.*` | Hourly local `pg_dump` timer with configurable `directory` and `retentionDays`. |
| `github-runner` | `davidvornholt.githubRunner.*` | Self-hosted GitHub Actions runner with nix-ld and resource limits. |

### Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    declarative-infra.url = "github:davidvornholt/declarative-infra";
  };

  outputs = { nixpkgs, declarative-infra, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        declarative-infra.nixosModules.default
        ./hosts/my-host/configuration.nix
      ];
    };
  };
}
```

Then in the host configuration:

```nix
{
  davidvornholt.base = {
    enable = true;
    adminSshKeys = [ "ssh-ed25519 ..." ];
    deploySshKeys = [ "ssh-ed25519 ..." ];
  };
  davidvornholt.caddy = {
    enable = true;
    acmeEmail = "admin@example.com";
  };
  davidvornholt.podman.enable = true;
  davidvornholt.postgres = {
    enable = true;
    appDatabases = [ "my_app" ];
    appSystemUsers = [ "my-app" ];
  };
  davidvornholt.backup = {
    enable = true;
    postgresDatabases = [ "my_app" ];
  };
}
```

`example/configuration.nix` is a full eval-only host exercising every module;
`nix flake check` evaluates it, so option regressions fail in CI without a
build.

## OpenTofu modules

Generic child modules under `opentofu/`. They declare providers and variables
only — backends, provider configuration, credentials, and state belong to the
consumer's root stack. Pin the source with `?ref=`:

```hcl
module "dns" {
  source  = "github.com/davidvornholt/declarative-infra//opentofu/cloudflare-dns?ref=v0.2.0"
  zone_id = local.cloudflare_zone_id
  records = local.dns_records
}

module "buckets" {
  source     = "github.com/davidvornholt/declarative-infra//opentofu/cloudflare-r2?ref=v0.2.0"
  account_id = var.cloudflare_account_id
  buckets = {
    app = { name = "my-app-media", jurisdiction = "eu" }
  }
}
```

| Module | Provides |
| --- | --- |
| `cloudflare-dns` | A map of Cloudflare DNS records for one zone, with sensible defaults (`ttl = 1`, `proxied = false`). |
| `cloudflare-r2` | A map of R2 buckets with `prevent_destroy` guarding against accidental deletion. |

When migrating existing root-level resources into these modules, add `moved`
blocks in the root stack and verify the plan is a no-op before applying.

## Versioning

Consumers pin: NixOS modules through `flake.lock`, OpenTofu modules through
`?ref=` tags. Cut annotated tags (`v0.1.0`, `v0.2.0`, …) for OpenTofu
consumers; flake consumers update with `nix flake update declarative-infra`, which
surfaces as a reviewable lock-file diff.

## License

[MIT](./LICENSE) © David Vornholt
