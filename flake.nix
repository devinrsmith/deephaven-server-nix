{
  description = "Deephaven Core server (server-jetty) release as a consumable flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;

      versions = builtins.fromJSON (builtins.readFile ./versions.json);
      # The newest bundled version: highest by version-aware comparison.
      latest = lib.last (lib.sort (a: b: lib.versionOlder a b) (lib.attrNames versions));

      # Dotted versions are awkward as attribute names: "42.8" -> "deephaven-42_8".
      attrName = v: "deephaven-${lib.replaceStrings [ "." ] [ "_" ] v}";

      # 1. Parameterized: pick any release version and its SRI hash.
      # Optional: `strict` (default true) fails on unexpected root entries; `expectedRoot` overrides them.
      mkDeephaven = { pkgs, ... }@args:
        pkgs.callPackage ./nix/package.nix (removeAttrs args [ "pkgs" ]);

      # Allows exactly the one non-free package this flake provides.
      allowUnfreePredicate = pkg: lib.getName pkg == "deephaven-server-jetty";

      pkgsFor = system: import nixpkgs { inherit system; config = { inherit allowUnfreePredicate; }; };

      forAllSystems = f: lib.genAttrs systems (system: f (pkgsFor system));
    in
    {
      lib = { inherit mkDeephaven allowUnfreePredicate versions latest attrName; };

      # `pkgs.deephaven` (latest) and `pkgs.deephavenVersions."42.8"`, usable from any nixpkgs.
      overlays.default = final: _prev:
        let byVersion = lib.mapAttrs (version: hash: mkDeephaven { pkgs = final; inherit version hash; }) versions;
        in { deephavenVersions = byVersion; deephaven = byVersion.${latest}; };

      # 2. Pre-named: deephaven-42_8, ... plus `default`/`deephaven` for the newest.
      packages = forAllSystems (pkgs:
        let
          named = lib.mapAttrs' (version: hash:
            lib.nameValuePair (attrName version) (mkDeephaven { inherit pkgs version hash; })) versions;
        in
        named // { deephaven = named.${attrName latest}; default = named.${attrName latest}; });

      checks = forAllSystems (pkgs: {
        # Exercises the parameterized path end to end with the latest bundled version.
        parameterized = mkDeephaven { inherit pkgs; version = latest; hash = versions.${latest}; };
      });
    };
}
