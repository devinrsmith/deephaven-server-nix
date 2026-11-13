# deephaven-flake

Nix flake for the [Deephaven Community Core](https://github.com/deephaven/deephaven-core) server
(`server-jetty` release tarball, unpacked into the store; not built from source).

## 1. Pre-named versions

```nix
inputs.deephaven.url = "github:devinrsmith/deephaven-server-nix";
inputs.deephaven.inputs.nixpkgs.follows = "nixpkgs";
# ...
inputs.deephaven.packages.${system}.deephaven-42_8
```

`packages.<system>.deephaven-42_8`, `deephaven-42_7`, ... and `deephaven`/`default` (newest).
Also `overlays.default` which adds `pkgs.deephaven` and `pkgs.deephavenVersions."42.8"`.

Available versions are listed in `versions.json`. Add one with `nix run .#add-version -- <version>`
(brings its own `jq`; run it from a checkout of this repo).

## 2. Parameterized: pick your own version and hash

```nix
deephaven = inputs.deephaven.lib.mkDeephaven {
  inherit pkgs;
  version = "42.6";
  hash = "sha256-...";   # nix store prefetch-file <server-jetty-<version>.tar URL>
};
```

## License

The Deephaven Community License is non-free, so the package is marked unfree. This flake's own
`packages` allow just this package. When using `mkDeephaven` or the overlay with your own `pkgs`, set:

```nix
config.allowUnfreePredicate = inputs.deephaven.lib.allowUnfreePredicate;
```

## Strict install

By default the build fails if the release tarball's root contains anything other than
`bin`, `etc` and `lib`, so a changed upstream layout is noticed rather than silently dropped.
Everything in the root is installed (only `bin/start.bat` is removed). Options for `mkDeephaven`:

- `strict = false` installs whatever the tarball contains, without checking.
- `expectedRoot = [ "bin" "etc" "lib" "newdir" ]` updates the allowed set.
