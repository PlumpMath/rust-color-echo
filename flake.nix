{
  description = "Build a cargo project while also compiling the standard library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustToolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
          extensions = [ "rust-src" "rust-std" "rust-analyzer" ];
          targets = [ "x86_64-unknown-linux-gnu" "x86_64-apple-darwin" "aarch64-apple-darwin" ];
        });

        # NB: we don't need to overlay our custom toolchain for the *entire*
        # pkgs (which would require rebuidling anything else which uses rust).
        # Instead, we just want to update the scope that crane will use by appending
        # our specific toolchain there.
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        src = craneLib.cleanCargoSource (craneLib.path ./.);

        rust-color-echo = craneLib.buildPackage {
          inherit src;
          strictDeps = true;

          cargoVendorDir = craneLib.vendorMultipleCargoDeps {
            inherit (craneLib.findCargoFiles src) cargoConfigs;
            cargoLockList = [
              ./Cargo.lock

              # Unfortunately this approach requires IFD (import-from-derivation)
              # otherwise Nix will refuse to read the Cargo.lock from our toolchain
              # (unless we build with `--impure`).
              #
              # Another way around this is to manually copy the rustlib `Cargo.lock`
              # to the repo and import it with `./path/to/rustlib/Cargo.lock` which
              # will avoid IFD entirely but will require manually keeping the file
              # up to date!
              "${rustToolchain.passthru.availableComponents.rust-src}/lib/rustlib/src/rust/Cargo.lock"
            ];
          };

          # cargoExtraArgs = "-Z build-std --target x86_64-unknown-linux-gnu";
          cargoExtraArgs = "-Z build-std";
          # cargoExtraArgs = if system == "x86_64-linux"
          #                  then "-Z build-std --target x86_64-unknown-linux-gnu"
          #                  else (if system == "x86_64-darwin"
          #                        then "-Z build-std --target x86_64-apple-"
          #                  );

          buildInputs = [
            # Add additional build inputs here
          ];
        };
      in
      {
        checks = {
          inherit rust-color-echo;
        };

        packages.default = rust-color-echo;

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Extra inputs can be added here; cargo and rustc are provided by default
          # from the toolchain that was specified earlier.
          packages = [
            # rustToolchain
          ];
        };
      });
}
