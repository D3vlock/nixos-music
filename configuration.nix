{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "tidalartist";
  time.timeZone = "Europe/Brussels";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.artist = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" ];
  };

  security.sudo.enable = true;
  security.rtkit.enable = true;

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      UseDns = true;
      PermitRootLogin = "no";
    };
  };

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    ripgrep
    tmux
    bluez
    nodejs

    supercollider
    supercolliderPlugins.sc3-plugins
    (haskellPackages.ghcWithPackages (p: with p; [
        tidal
    ]))
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "minimal";
  };

  environment.shellAliases = {
  tidal = "ghci -ghci-script ~/tidal.hs";
  };

  systemd.user.services.wireplumber.wantedBy = [ "default.target" ];

  system.stateVersion = "25.05";
}
