#!/usr/bin/env bash
set -euo pipefail

# WARNING:
# This script can DESTROY DATA on the selected disk.

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi

TARGET_DISK=""
EFI_PART=""
BTRFS_PART=""
SWAP_SIZE_GB=""
HOSTNAME_CHOICE=""
USERNAME_CHOICE=""
TIMEZONE_CHOICE="Europe/Brussels"

ROOT_SUBVOL="root"
HOME_SUBVOL="home"
NIX_SUBVOL="nix"
SWAP_SUBVOL="swap"

BTRFS_MOUNT_OPTS_ROOT="compress=zstd,subvol=${ROOT_SUBVOL}"
BTRFS_MOUNT_OPTS_HOME="compress=zstd,subvol=${HOME_SUBVOL}"
BTRFS_MOUNT_OPTS_NIX="compress=zstd,noatime,subvol=${NIX_SUBVOL}"
BTRFS_MOUNT_OPTS_SWAP="subvol=${SWAP_SUBVOL}"

pause() {
    read -r -p "Press Enter to continue..."
}

ask_yes_no() {
    local prompt="$1"
    local reply
    while true; do
        read -r -p "$prompt [y/n]: " reply
        case "${reply,,}" in
        y | yes) return 0 ;;
        n | no) return 1 ;;
        *) echo "Please answer y or n." ;;
        esac
    done
}

choose_menu() {
    local __resultvar="$1"
    shift
    local title="$1"
    shift
    local options=("$@")
    local i choice

    echo
    echo "$title"
    for i in "${!options[@]}"; do
        printf "  %d) %s\n" "$((i + 1))" "${options[$i]}"
    done

    while true; do
        read -r -p "Choose an option: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
            printf -v "$__resultvar" '%s' "${options[$((choice - 1))]}"
            return 0
        fi
        echo "Invalid choice."
    done
}

confirm_or_exit() {
    local msg="$1"
    echo
    echo "$msg"
    if ! ask_yes_no "Continue?"; then
        echo "Aborted."
        exit 1
    fi
}

show_disks() {
    echo
    echo "Available block devices:"
    lsblk -d -o NAME,SIZE,MODEL,TYPE,TRAN
    echo
}

pick_disk() {
    show_disks
    read -r -p "Enter the target disk (example: /dev/nvme0n1 or /dev/sda): " TARGET_DISK
    if [[ ! -b "$TARGET_DISK" ]]; then
        echo "Disk not found: $TARGET_DISK"
        exit 1
    fi
}

detect_part_names() {
    if [[ "$TARGET_DISK" =~ nvme|mmcblk ]]; then
        EFI_PART="${TARGET_DISK}p1"
        BTRFS_PART="${TARGET_DISK}p2"
    else
        EFI_PART="${TARGET_DISK}1"
        BTRFS_PART="${TARGET_DISK}2"
    fi
}

choose_swap_size() {
    local picked
    choose_menu picked "Select swapfile size" \
        "4" \
        "8" \
        "16" \
        "32" \
        "Custom"
    if [[ "$picked" == "Custom" ]]; then
        read -r -p "Enter swap size in GiB: " SWAP_SIZE_GB
    else
        SWAP_SIZE_GB="$picked"
    fi

    if [[ ! "$SWAP_SIZE_GB" =~ ^[0-9]+$ ]] || ((SWAP_SIZE_GB < 1)); then
        echo "Invalid swap size."
        exit 1
    fi
}

get_basic_settings() {
    read -r -p "Hostname [nixos-music]: " HOSTNAME_CHOICE
    HOSTNAME_CHOICE="${HOSTNAME_CHOICE:-nixos-music}"

    read -r -p "Primary username [artist]: " USERNAME_CHOICE
    USERNAME_CHOICE="${USERNAME_CHOICE:-artist}"

    read -r -p "Timezone [Europe/Brussels]: " TIMEZONE_CHOICE
    TIMEZONE_CHOICE="${TIMEZONE_CHOICE:-Europe/Brussels}"
}

wipe_and_partition() {
    echo
    echo "About to partition $TARGET_DISK"
    echo "This will create:"
    echo "  - EFI partition:   550 MiB"
    echo "  - Btrfs partition: rest of disk"
    confirm_or_exit "ALL DATA ON $TARGET_DISK WILL BE ERASED."

    wipefs -a "$TARGET_DISK"
    sgdisk --zap-all "$TARGET_DISK"

    parted -s "$TARGET_DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 551MiB \
        set 1 esp on \
        mkpart primary 551MiB 100%

    partprobe "$TARGET_DISK"
    udevadm settle

    detect_part_names

    echo
    echo "Created:"
    echo "  EFI:   $EFI_PART"
    echo "  Btrfs: $BTRFS_PART"
}

format_partitions() {
    echo
    echo "Formatting partitions..."
    mkfs.fat -F 32 "$EFI_PART"
    mkfs.btrfs -f "$BTRFS_PART"
}

create_subvolumes() {
    echo
    echo "Creating Btrfs subvolumes..."
    mkdir -p /mnt
    mount "$BTRFS_PART" /mnt

    btrfs subvolume create "/mnt/${ROOT_SUBVOL}"
    btrfs subvolume create "/mnt/${HOME_SUBVOL}"
    btrfs subvolume create "/mnt/${NIX_SUBVOL}"
    btrfs subvolume create "/mnt/${SWAP_SUBVOL}"

    umount /mnt
}

mount_layout() {
    echo
    echo "Mounting target layout..."
    mount -o "$BTRFS_MOUNT_OPTS_ROOT" "$BTRFS_PART" /mnt

    mkdir -p /mnt/home
    mkdir -p /mnt/nix
    mkdir -p /mnt/.swapvol
    mkdir -p /mnt/boot

    mount -o "$BTRFS_MOUNT_OPTS_HOME" "$BTRFS_PART" /mnt/home
    mount -o "$BTRFS_MOUNT_OPTS_NIX" "$BTRFS_PART" /mnt/nix
    mount -o "$BTRFS_MOUNT_OPTS_SWAP" "$BTRFS_PART" /mnt/.swapvol
    mount "$EFI_PART" /mnt/boot
}

create_swapfile() {
    local swapfile="/mnt/.swapvol/swapfile"

    echo
    echo "Creating ${SWAP_SIZE_GB} GiB swapfile..."

    truncate -s 0 "$swapfile"
    chattr +C "$swapfile"
    btrfs property set /mnt/.swapvol compression none || true
    fallocate -l "${SWAP_SIZE_GB}G" "$swapfile"
    chmod 600 "$swapfile"
    mkswap "$swapfile"
    swapon "$swapfile"
}

generate_config() {
    echo
    echo "Generating NixOS config..."
    nixos-generate-config --root /mnt
}

patch_configuration() {
    local cfg="/mnt/etc/nixos/configuration.nix"

    echo
    echo "Applying a small minimal configuration..."
    cp "$cfg" "${cfg}.bak"

    cat >"$cfg" <<EOF
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "${HOSTNAME_CHOICE}";
  time.timeZone = "${TIMEZONE_CHOICE}";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  users.users.${USERNAME_CHOICE} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  security.sudo.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "25.05";
}
EOF
}

show_summary() {
    echo
    echo "Done."
    echo
    echo "Disk layout:"
    lsblk -f "$TARGET_DISK"
    echo
    echo "Mounted filesystems:"
    findmnt /mnt
    echo
    echo "Swap:"
    swapon --show
    echo
    echo "Generated files:"
    echo "  /mnt/etc/nixos/configuration.nix"
    echo "  /mnt/etc/nixos/hardware-configuration.nix"
    echo
    echo "Next suggested steps:"
    echo "  1) Review /mnt/etc/nixos/hardware-configuration.nix"
    echo "  2) Review /mnt/etc/nixos/configuration.nix"
    echo "  3) Reboot"
    echo "  4) As root do passwd <user>"
}

main() {
    echo "NixOS Btrfs Manual Install Helper"
    echo "UEFI, single disk, with swapfile"
    echo

    pick_disk
    detect_part_names
    choose_swap_size
    get_basic_settings

    echo
    echo "Summary:"
    echo "  Disk:      $TARGET_DISK"
    echo "  EFI part:  $EFI_PART"
    echo "  Btrfs:     $BTRFS_PART"
    echo "  Swap:      ${SWAP_SIZE_GB} GiB"
    echo "  Hostname:  $HOSTNAME_CHOICE"
    echo "  Username:  $USERNAME_CHOICE"
    echo "  Timezone:  $TIMEZONE_CHOICE"
    confirm_or_exit "Proceed with partitioning and setup."

    wipe_and_partition
    format_partitions
    create_subvolumes
    mount_layout
    create_swapfile
    generate_config
    patch_configuration
    nixos-install
    show_summary
}

main "$@"
