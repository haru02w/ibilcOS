{
  description = "A learning operatinal system by UNESP-Ibilce students";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system:
          f (import nixpkgs {
            inherit system;
            # config.allowUnfree = true;
            # overlays = [];
          }));
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.clangStdenv.mkDerivation {
          name = "ibilcOS";
          propagatedBuildInputs = with pkgs; [
            nasm
            cmake
            xorriso
            qemu
          ];
        };
      });
    };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
}
