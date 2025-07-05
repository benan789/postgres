{ lib, stdenv, fetchFromGitHub, openssl, postgresql, buildPgrxExtension_0_15_0, cargo, rust-bin }:
let
  rustVersion = "1.88.0";
  cargo = rust-bin.stable.${rustVersion}.default;
in
buildPgrxExtension_0_15_0 rec {
  pname = "paradedb";
  extension = "pg_search";
  version = "0.16.2";
  inherit postgresql;
  cargoPackageFlags = ["--package pg_search"];

  src = fetchFromGitHub {
    owner = "paradedb";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-mo4OsuCtFuGkefeKyU05mE+uF8x/7J+Ndylf4lJOaVw=";
  };

  nativeBuildInputs = [ cargo ];
  buildInputs = [ openssl postgresql ];

  CARGO="${cargo}/bin/cargo";

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
    outputHashes = {
      "tantivy-0.23.0" = "sha256-CD0dgLB3tilkZ4PkEjGsGjP7oE/cHqRVXecJckWlT/o=";
      "rust_icu_sys-5.0.0" = "sha256-5IinVaGLay6FWj6SLF1lGkCzRjTaf9vJuInXzMZkkRs=";
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
  cargoHash = "sha256-mo4OsuCtFuGkefeKyU05mE+uF8x/7J+Ndylf4lJOaVw=";

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