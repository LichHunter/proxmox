{
  modulesPath,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC = {
    privileged = false;
    manageNetwork = false;
    manageHostName = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  users.users.root.initialPassword = "changeme";

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
  ];

  system.stateVersion = "25.11";
}
