{ lib, stdenv, fetchFromGitHub, openssl, postgresql, buildPgrxExtension_0_12_7, cargo, rust-bin }:
let
  rustVersion = "1.84.0";
  cargo = rust-bin.stable.${rustVersion}.default;
in
buildPgrxExtension_0_12_7 rec {
  pname = "paradedb";
  extension = "pg_search";
  version = "0.15.0";
  inherit postgresql;
  cargoPackageFlags = ["--package pg_search"];

  src = fetchFromGitHub {
    owner = "benan789";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-jdYMCDwmPFVv0mWDmkcNGtrcab4df1YB4nbGVLo60Ts=";
  };

  nativeBuildInputs = [ cargo ];
  buildInputs = [ openssl postgresql ];

  CARGO="${cargo}/bin/cargo";

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
    outputHashes = {
      "tantivy-0.23.0" = "sha256-LOmTk5/K8s9iMz1OHXgzCXBY5sVzA2WFyS+A9/SO9no=";
      "pgrx-0.12.7" = "sha256-BnZWS7tYzibyGoJSHcBGoqRasaFVTvW/FM/YiXlfYZo=";
      "tantivy-fst-0.5.0" = "sha256-YeHk7tlEE2jGxgLhqhZhFj8rtZ0bwQINNdLQDh4Mw7I=";
    };
  };

  #darwin env needs PGPORT to be unique for build to not clash with other pgrx extensions
  env = lib.optionalAttrs stdenv.isDarwin {
    POSTGRES_LIB = "${postgresql}/lib";
    RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup -C debuginfo=2";
    PGPORT = "5436";
    COLORBT_SHOW_HIDDEN = "1";
    RUST_BACKTRACE = "full";
    CARGO_BUILD_OPTS = "--verbose"; 
  };
  cargoHash = "sha256-jdYMCDwmPFVv0mWDmkcNGtrcab4df1YB4nbGVLo60Ts=";

  # FIXME (aseipp): testsuite tries to write files into /nix/store; we'll have
  # to fix this a bit later.
  doCheck = false;

  meta = with lib; {
    description = "Postgres for Search and Analytics";
    homepage = "https://github.com/${src.owner}/${src.repo}";
    maintainers = with maintainers; [ philippemnoel ];
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}