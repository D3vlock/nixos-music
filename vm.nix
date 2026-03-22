{ config, pkgs, lib, ... }:

{
  imports = [ ./configuration.nix ];

  # Software rendering for Sway under QEMU
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "pixman";
  };

  # Allow password login for testing (artist/artist)
  users.users.artist = {
    initialPassword = "artist";
  };

  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Greetd: launch sway with software rendering flags
  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.sway}/bin/sway --unsupported-gpu'";
}
