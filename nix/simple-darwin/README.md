# Nix-darwin

- Install Nix: `sh <(curl -L https://nixos.org/nix/install)`
- Install HomeBrew: <https://docs.brew.sh/Installation>

To apply the system configuration:

```bash
nix \
  --experimental-features 'nix-command flakes' \
  build .#darwinConfigurations.macbook.system

./result/sw/bin/darwin-rebuild switch --flake .#macbook

# Delete the manually installed `nix` instance to make `nix config check` happy
sudo nix profile remove nix cacert
```
