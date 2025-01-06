{ lib, stdenv, fetchFromGitHub, openssl, postgresql, buildPgrxExtension_0_12_7, cargo, rust-bin }:
let
  rustVersion = "1.83.0";
  cargo = rust-bin.stable.${rustVersion}.default;
in
buildPgrxExtension_0_12_7 rec {
  pname = "paradedb";
  extension = "pg_search";
  version = "0.13.2";
  inherit postgresql;
  cargoPackageFlags = ["--package pg_search"];

  src = fetchFromGitHub {
    owner = "paradedb";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-xP7y6eprDMFCGjMtjw7+GIgzzBnsNZB8ClfflqiQJFM=";
  };

  nativeBuildInputs = [ cargo ];
  buildInputs = [ openssl postgresql ];

  CARGO="${cargo}/bin/cargo";

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
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
  cargoHash = "sha256-xP7y6eprDMFCGjMtjw7+GIgzzBnsNZB8ClfflqiQJFM=";

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