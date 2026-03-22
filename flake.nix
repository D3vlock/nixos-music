{
  description = "NixOS TidalCycles livecoding environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {

    nixosConfigurations = {

      # Bare-metal: nixos-rebuild switch --flake .#tidalartist
      tidalartist = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };

      # QEMU VM: nix run .#vm
      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./vm.nix
          ({ modulesPath, ... }: {
            imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

            virtualisation = {
              memorySize = 4096;
              cores = 4;
              diskSize = 10240;
              graphics = true;
              qemu.options = [
                "-device virtio-vga-gl"
                "-display gtk,gl=on"
              ];
            };
          })
        ];
      };

    };

    # Shortcut: nix run .#vm
    apps.x86_64-linux.vm = {
      type = "app";
      program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-tidalartist-vm";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.vm;
  };
}
