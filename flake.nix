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
          packages.slides = with pkgs; stdenv.mkDerivation {
            name = "asciidoc slides";
            src = lib.cleanSourceWith {
              src = gitignoreSource ./slides;
              filter = name: type: ! ((type == "regular") && ((baseNameOf name) == "README.adoc"));
            };
            buildInputs = [
              asciidoctor
              nodePackages.pnpm
              nodejs-slim
            ];
            configurePhase = ''
              pnpm install
            '';
            buildPhase = ''
              ./node_modules/.bin/asciidoctor-revealjs *.adoc
            '';
            installPhase = ''
              outdir="$out"/slides
              mkdir -p "$outdir"

              # Install built HTML files alongside needed resources
              cp -r \
                node_modules/reveal.js \
                node_modules/@highlightjs \
                *.html \
                *.png \
                styles \
                "$outdir"/
            '';
          };

          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [
              asciidoctor
              cue
              git
              go
              mage
              nix
              pulumi
              pulumi-language-go
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
