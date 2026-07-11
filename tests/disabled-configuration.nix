_:

{
  networking.hostName = "disabled";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  system.stateVersion = "25.05";
}
