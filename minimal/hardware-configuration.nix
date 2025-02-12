{ modulesPath, lib, ... }:
{
  # Generate using `nixos-generate-config`

  imports = [
    "${modulesPath}/profiles/minimal/hardware-configuration.nix"
  ];
}
