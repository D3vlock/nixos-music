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
    shell = pkgs.zsh;
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

  hardware.bluetooth.enable = true;

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

  programs.sway.enable = true;
  programs.tmux = {
    enable = true;
    extraConfig = ''
        set -g default-shell ${pkgs.zsh}/bin/zsh
        set -g default-command ${pkgs.zsh}/bin/zsh
    '';
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    foot
    git
    vim
    neovim
    starship
    fzf
    ripgrep
    tmux
    bluez
    nodejs
    qpwgraph
    qutebrowser

    supercollider
    supercolliderPlugins.sc3-plugins
    (haskellPackages.ghcWithPackages (p: with p; [
        tidal
    ]))
  ];

  environment.sessionVariables = {
    TERM = "foot";
  };

  environment.shellAliases = {
  tidal = "ghci -ghci-script ~/tidal.hs";
  };

  environment.etc."foot/foot.init".text = ''
    [main]
    shell=${pkgs.zsh}/bin/zsh
    font=JetBrainsMono Nerd Font:size=16
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  systemd.user.services.wireplumber.wantedBy = [ "default.target" ];

  system.stateVersion = "25.05";
}
