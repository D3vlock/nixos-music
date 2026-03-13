#!/usr/bin/env bash
set -euo pipefail

# WARNING:
# This script can DESTROY DATA on the selected disk.

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

TARGET_DISK=""
EFI_PART=""
BTRFS_PART=""
SWAP_SIZE_GB=""
HOSTNAME_CHOICE=""
USERNAME_CHOICE=""
TIMEZONE_CHOICE=""

ROOT_SUBVOL="root"
HOME_SUBVOL="home"
NIX_SUBVOL="nix"
SWAP_SUBVOL="swap"

BTRFS_MOUNT_OPTS_ROOT="compress=zstd,subvol=${ROOT_SUBVOL}"
BTRFS_MOUNT_OPTS_HOME="compress=zstd,subvol=${HOME_SUBVOL}"
BTRFS_MOUNT_OPTS_NIX="compress=zstd,noatime,subvol=${NIX_SUBVOL}"
BTRFS_MOUNT_OPTS_SWAP="subvol=${SWAP_SUBVOL}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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

teardown() {
    echo
    echo "Tearing down mounts..."
    swapoff /mnt/.swapvol/swapfile 2>/dev/null || true
    umount /mnt/boot 2>/dev/null || true
    umount /mnt/.swapvol 2>/dev/null || true
    umount /mnt/nix 2>/dev/null || true
    umount /mnt/home 2>/dev/null || true
    umount /mnt 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Cleanup trap — unmounts /mnt subtree on unexpected exit
# ---------------------------------------------------------------------------

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo
        echo "Script failed (exit $exit_code). Attempting to clean up mounts..."
        swapoff /mnt/.swapvol/swapfile 2>/dev/null || true
        # Unmount in reverse order; ignore errors since some may not be mounted
        umount /mnt/boot 2>/dev/null || true
        umount /mnt/.swapvol 2>/dev/null || true
        umount /mnt/nix 2>/dev/null || true
        umount /mnt/home 2>/dev/null || true
        umount /mnt 2>/dev/null || true
        echo "Cleanup done. You can safely re-run the script."
    fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Disk selection
# ---------------------------------------------------------------------------

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

# Sets EFI_PART and BTRFS_PART based on TARGET_DISK naming convention.
# Must be called after TARGET_DISK is set.
detect_part_names() {
    if [[ "$TARGET_DISK" =~ nvme|mmcblk ]]; then
        EFI_PART="${TARGET_DISK}p1"
        BTRFS_PART="${TARGET_DISK}p2"
    else
        EFI_PART="${TARGET_DISK}1"
        BTRFS_PART="${TARGET_DISK}2"
    fi
}

# ---------------------------------------------------------------------------
# Settings gathering
# ---------------------------------------------------------------------------

choose_swap_size() {
    local picked
    choose_menu picked "Select swapfile size (GiB)" \
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

validate_timezone() {
    local tz="$1"
    if [[ ! -f "/etc/zoneinfo/$tz" ]]; then
        echo "Unknown timezone: $tz"
        echo "Check /etc/zoneinfo for valid options."
        exit 1
    fi
}

get_basic_settings() {
    read -r -p "Hostname [nixos-music]: " HOSTNAME_CHOICE
    HOSTNAME_CHOICE="${HOSTNAME_CHOICE:-nixos-music}"

    # Hostnames: lowercase letters, digits, hyphens; no leading/trailing hyphen
    if [[ ! "$HOSTNAME_CHOICE" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        echo "Invalid hostname: $HOSTNAME_CHOICE"
        exit 1
    fi

    read -r -p "Primary username [artist]: " USERNAME_CHOICE
    USERNAME_CHOICE="${USERNAME_CHOICE:-artist}"

    # POSIX username: starts with letter/underscore, alphanumeric/hyphen/underscore
    if [[ ! "$USERNAME_CHOICE" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "Invalid username: $USERNAME_CHOICE"
        exit 1
    fi

    read -r -p "Timezone [Europe/Brussels]: " TIMEZONE_CHOICE
    TIMEZONE_CHOICE="${TIMEZONE_CHOICE:-Europe/Brussels}"
    validate_timezone "$TIMEZONE_CHOICE"
}

# ---------------------------------------------------------------------------
# Disk operations
# ---------------------------------------------------------------------------

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

    # Derive partition names now that they actually exist
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

    mkdir -p /mnt/{home,nix,.swapvol,boot}

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

# ---------------------------------------------------------------------------
# NixOS config generation
# ---------------------------------------------------------------------------

generate_config() {
    echo
    echo "Generating NixOS hardware config..."
    nixos-generate-config --root /mnt
}

copy_configuration() {
    local src="${REPO_DIR}/configuration.nix"
    local dest="/mnt/etc/nixos/configuration.nix"

    if [[ ! -f "$src" ]]; then
        echo "  [skip] No configuration.nix found in repo, using generated one"
        return 0
    fi

    cp "$src" "$dest"
    echo "  [copy] $src -> $dest"
}

set_user_password() {
    echo
    echo "Set password for '${USERNAME_CHOICE}':"
    nixos-enter --root /mnt -- passwd "${USERNAME_CHOICE}"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

show_summary() {
    echo
    echo "================================================================"
    echo " Installation complete."
    echo "================================================================"
    echo
    echo "Disk layout:"
    lsblk -f "$TARGET_DISK"
    echo
    echo "Mounted filesystems under /mnt:"
    findmnt /mnt
    echo
    echo "Swap:"
    swapon --show
    echo
    echo "Generated files:"
    echo "  /mnt/etc/nixos/configuration.nix"
    echo "  /mnt/etc/nixos/hardware-configuration.nix"
    echo
    echo "Next steps:"
    echo "  1) Review /mnt/etc/nixos/hardware-configuration.nix"
    echo "     Ensure its fileSystems entries don't conflict with"
    echo "     the ones written into configuration.nix by this script."
    echo "  2) Review /mnt/etc/nixos/configuration.nix"
    echo "  3) Reboot"
    echo "  4) Set a password: passwd ${USERNAME_CHOICE}"
    echo
    echo "  Hibernate note: if you want suspend-to-disk, see the"
    echo "  resume_offset comment in configuration.nix."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo "NixOS Btrfs Manual Install Helper"
    echo "UEFI · single disk · Btrfs subvolumes · swapfile"
    echo

    pick_disk
    choose_swap_size
    get_basic_settings

    # Derive partition names for the summary (disk exists, names are stable)
    detect_part_names

    echo
    echo "================================================================"
    echo " Summary"
    echo "================================================================"
    echo "  Disk:      $TARGET_DISK"
    echo "  EFI part:  $EFI_PART"
    echo "  Btrfs:     $BTRFS_PART"
    echo "  Swap:      ${SWAP_SIZE_GB} GiB"
    echo "  Hostname:  $HOSTNAME_CHOICE"
    echo "  Username:  $USERNAME_CHOICE"
    echo "  Timezone:  $TIMEZONE_CHOICE"
    confirm_or_exit "Proceed with partitioning and setup."

    wipe_and_partition # calls detect_part_names again after partition table exists
    format_partitions
    create_subvolumes
    mount_layout
    create_swapfile
    generate_config
    copy_configuration
    nixos-install
    set_user_password

    teardown
    show_summary
}

main "$@"
