{
  description = "Pulumi AWS playground";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs @ { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages."${system}"; in
        {
          default = with pkgs; mkShell {
            nativeBuildInputs = [
              cue
              git
              go
              golangci-lint
              mage
              nix
              nixpkgs-fmt
              pulumi
              pulumiPackages.pulumi-language-go
              vim
            ];

            shellHook = ''
              export NIX_CONFIG="experimental-features = nix-command flakes"

              export PULUMI_SKIP_UPDATE_CHECK=true
              export PULUMI_AUTOMATION_API_SKIP_VERSION_CHECK=true

              export MAGEFILE_ENABLE_COLOR=true
            '';
          };
        });
    };
}
