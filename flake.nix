{
  description = "Short Node.js flake aliases built from nix-anynode";

  inputs = {
    anynode.url = "github:nficca/nix-anynode";
    nixpkgs.follows = "anynode/nixpkgs";
    flake-utils.follows = "anynode/flake-utils";
  };

  outputs =
    {
      anynode,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      data = import (anynode.outPath + "/data.nix");

      stripV = version: builtins.substring 1 (builtins.stringLength version - 1) version;

      isExactVersion = version: builtins.match "^v[0-9]+\\.[0-9]+\\.[0-9]+$" version != null;

      versionMajor = version: builtins.elemAt (builtins.match "^v([0-9]+)\\.[0-9]+\\.[0-9]+$" version) 0;

      versionAlias = version: builtins.replaceStrings [ "." ] [ "_" ] (stripV version);

      sortVersions =
        versions: builtins.sort (a: b: builtins.compareVersions (stripV a) (stripV b) < 0) versions;

      exactVersions = sortVersions (builtins.filter isExactVersion (builtins.attrNames data));

      versionsForSystem =
        system: builtins.filter (version: builtins.hasAttr system data.${version}) exactVersions;

      unique =
        values:
        builtins.attrNames (
          builtins.listToAttrs (
            map (value: {
              name = value;
              value = true;
            }) values
          )
        );

      latestVersionForSystem =
        system:
        let
          versions = versionsForSystem system;
        in
        if versions == [ ] then
          throw "No Node.js versions available for ${system}"
        else
          builtins.elemAt versions (builtins.length versions - 1);

      latestMajorAliasesForSystem =
        system:
        let
          versions = versionsForSystem system;
          majors = unique (map versionMajor versions);
          latestForMajor =
            major:
            let
              matching = builtins.filter (version: versionMajor version == major) versions;
            in
            builtins.elemAt matching (builtins.length matching - 1);
        in
        builtins.listToAttrs (
          map (major: {
            name = major;
            value = latestForMajor major;
          }) majors
        );

      exactAliasesForSystem =
        system:
        builtins.listToAttrs (
          map (version: {
            name = versionAlias version;
            value = version;
          }) (versionsForSystem system)
        );

      aliasesForSystem = system: exactAliasesForSystem system // latestMajorAliasesForSystem system;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        aliases = aliasesForSystem system;

        nodePackage = version: anynode.packages.${system}.${version};

        nodeShell =
          version:
          pkgs.mkShell {
            packages = [ (nodePackage version) ];
          };
      in
      {
        packages = builtins.mapAttrs (_: version: nodePackage version) aliases // {
          default = nodePackage (latestVersionForSystem system);
        };

        devShells = builtins.mapAttrs (_: version: nodeShell version) aliases // {
          default = nodeShell (latestVersionForSystem system);
        };
      }
    );
}
