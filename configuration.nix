{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "tidalartist";
  time.timeZone = "Europe/Brussels";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  users.users.artist = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # security
  
  security.sudo.enable = true;
  security.rtkit.enable = true;

  # environment
  
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sway-launch" ''
      if systemd-detect-virt --quiet && [ "$(systemd-detect-virt)" = "oracle" ]; then
        export WLR_NO_HARDWARE_CURSORS=1
        export WLR_RENDERER=pixman
        exec ${pkgs.sway}/bin/sway --unsupported-gpu "$@"
      else
        exec ${pkgs.sway}/bin/sway "$@"
      fi
    '')
    foot
    git
    stow
    vim
    neovim
    starship
    eza
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

  # services
  
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "artist" ];
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

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway-launch";
        user = "greeter";
      };
    };
  };

  # hardware
  
  hardware.bluetooth.enable = true;

  # programs
  
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      switch = "sudo nixos-rebuild switch";
    };

    histSize = 10000;
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };

  programs.sway.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
        set -g default-shell ${pkgs.zsh}/bin/zsh
        set -g default-command ${pkgs.zsh}/bin/zsh
    '';
  };

  # greetd does not trigger the normal pipewire → wireplumber activation
  # chain reliably. Force wireplumber into the base user session target.
  systemd.user.services.wireplumber.wantedBy = [ "default.target" ];

  system.stateVersion = "25.05";
}

