# SPDX-FileCopyrightText: 2023 Hoang Nguyen <folliekazetani@protonmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  description = "Pulumi AWS playground";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, gitignore, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = { config, system, ... }:
        let
          inherit (nixpkgs) lib;
          inherit (gitignore.lib) gitignoreSource;

          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          packages.slides = with pkgs; stdenv.mkDerivation (finalAttrs: {
            name = "asciidoc slides";
            src = lib.cleanSourceWith {
              src = gitignoreSource ./slides;
              filter = name: type: ! ((type == "regular") && ((baseNameOf name) == "README.adoc"));
            };
            buildInputs = [ nodejs yarn fixup_yarn_lock ];
            offlineCache = fetchYarnDeps {
              yarnLock = finalAttrs.src + "/yarn.lock";
              sha256 = "sha256-5ZmQYtuRXy3Vx4gUMViuQjA+XGBREAjRQMRA+rtTVLY";
            };
            configurePhase = ''
              export HOME="$TMPDIR"
              yarn config --offline set yarn-offline-mirror $offlineCache
              fixup_yarn_lock yarn.lock
              yarn install \
                --frozen-lockfile \
                --offline \
                --ignore-platfom \
                --ignore-scripts \
                --no-progress \
                --non-interactive
              patchShebangs node_modules/
            '';
            buildPhase = ''
              ./node_modules/.bin/asciidoctor-revealjs *.adoc
            '';
            installPhase = ''
              outdir="$out"/slides

              # Install static resources installed from npm
              mkdir -p "$outdir"/node_modules
              cp -r \
                node_modules/reveal.js \
                node_modules/@highlightjs \
                "$outdir"/node_modules/

              # Install built HTML files alongside static resources
              cp -r *.html *.png styles/ "$outdir"/
            '';
          });

          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [
              asciidoctor
              cue
              git
              go
              mage
              nix
              pulumi
              pulumiPackages.pulumi-language-go
              terraform
              vim
            ];

            shellHook = ''
              export NIX_CONFIG="experimental-features = nix-command flakes"
              export PULUMI_SKIP_UPDATE_CHECK=true
              export PULUMI_AUTOMATION_API_SKIP_VERSION_CHECK=true
              export MAGEFILE_ENABLE_COLOR=true
            '';
          };
        };
    };
}
