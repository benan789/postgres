{
  lib,
  stdenv,
  callPackages,
  fetchFromGitHub,
  postgresql,
  buildEnv,
  rust-bin,
  pkg-config,
  openssl,
}:

let
  pname = "paradedb";

  build =
    version: hash: rustVersion: pgrxVersion:
    let
      cargo = rust-bin.stable.${rustVersion}.default;
      mkPgrxExtension = callPackages ../../cargo-pgrx/mkPgrxExtension.nix {
        inherit rustVersion pgrxVersion;
      };
    in
    mkPgrxExtension rec {
      inherit pname version postgresql;

      src = fetchFromGitHub {
        owner = "paradedb";
        repo = pname;
        rev = "refs/tags/v${version}";
        inherit hash;
      };
      
      sourceRoot = "source/pg_search";

      nativeBuildInputs = [ pkg-config cargo ];
      buildInputs = [ openssl postgresql ];

      CARGO = "${cargo}/bin/cargo";

      cargoLock = {
        lockFile = "${src}/Cargo.lock";
        # Add outputHashes if you have git dependencies:
        outputHashes = {
          "datafusion-distributed-1.0.0" = "sha256-hzRlV7IkH7Le3ww8ScoSfjndAJSO09WIXefeY7LwF3A=";
          "ownedbytes-0.9.0" = "sha256-hzRlV7IkH7Le3ww8ScoSfjndAJSO09WIXefeY7LwF3A=";
          "tantivy-fst-0.5.0" = "sha256-YeHk7tlEE2jGxgLhqhZhFj8rtZ0bwQINNdLQDh4Mw7I=";
        };
      };

      # Optional: if extension's Cargo.toml needs modification
      # preConfigure = ''
      #   sed -i 's/pgrx = "0.12"/pgrx = "0.12.6"/' Cargo.toml
      # '';

      meta = with lib; {
        description = "Postgres for Search and Analytics";
        homepage = "https://github.com/${src.owner}/${src.repo}";
        license = licenses.mit;  # adjust as needed
      };
    };

  allVersions = (builtins.fromJSON (builtins.readFile ../versions.json)).${pname};

  supportedVersions = lib.filterAttrs (
    _: value: builtins.elem (lib.versions.major postgresql.version) value.postgresql
  ) allVersions;

  versions = lib.naturalSort (lib.attrNames supportedVersions);
  latestVersion = lib.last versions;

  packages = map (
    version:
    let
      v = supportedVersions.${version};
    in
    build version v.hash v.rust v.pgrx
  ) versions;
in
buildEnv {
  name = pname;
  paths = packages;
  pathsToLink = [
    "/lib"
    "/share/postgresql/extension"
  ];

  postBuild = ''
    # Create version-specific SQL symlinks for migrations
    ${lib.concatMapStringsSep "\n" (version: ''
      if [ -f $out/share/postgresql/extension/${pname}--${version}.sql ]; then
        ln -sf ${pname}--${version}.sql $out/share/postgresql/extension/${pname}--${latestVersion}--${version}.sql 2>/dev/null || true
      fi
    '') versions}
  '';
}