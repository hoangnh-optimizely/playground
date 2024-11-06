{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          homebrew = {
            brews = [
              "argocd"
              "azure-cli"
              "bash-completion"
              "git"
              "helm"
              "k9s"
              "kind"
              "kubernetes-cli"
              "kubeseal"
              "node"
              "oh-my-posh"
              "pinentry"
              "pinentry-mac"
              "pinentry-touchid"
              "pre-commit"
              "prowler"
              "terraform"
              "terraform-docs"
              "tree"
            ];
            casks = [
              "arc"
              "altair-graphql-client"
              "azure-data-studio"
              "displaylink"
              "docker"
              "fork"
              "karabiner-elements"
              "linearmouse"
              "maccy"
              "microsoft-azure-storage-explorer"
              "middleclick"
              "mongodb-compass"
              "obsidian"
              "openkey"
              "openvpn-connect"
              "postman"
              "powershell"
              "rectangle"
              "shottr"
              "skype"
              "spotify"
              "stats"
              "tabby"
              "visual-studio-code"
              "zalo"
            ];
            taps = [
              "jorgelbg/tap"
            ];
          };

          services.nix-daemon.enable = true;

          nix.package = pkgs.nixVersions.latest;

          nix.settings.experimental-features = "nix-command flakes";

          system.stateVersion = 5;

          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      darwinConfigurations."macbook" = darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
