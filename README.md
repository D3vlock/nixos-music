# 🎵 NixOS TidalCycles Music

Minimal terminal-only NixOS setup for TidalCycles + SuperCollider livecoding.

### Designed for

    low-latency audio
    PipeWire
    Btrfs filesystem
    reproducible system configuration
    no GUI required

### ✨ Features

    Btrfs filesystem with subvolumes
    swapfile on Btrfs
    PipeWire audio
    SuperCollider + SuperDirt
    TidalCycles via GHC
    minimal terminal environment

### 🧰 Requirements

    NixOS installer ISO
    UEFI system
    one target disk (will be wiped)

# 🚀 Installation

Boot the NixOS installer and open a terminal.

`nmtui` to setup internet connection.

Clone the repository:

```
git clone https://github.com/D3vlock/nixos-music.git
cd nixos-music
```

Run the installation helper:

```
./btrfs-install-helper.sh
```

The script will:

    wipe the selected disk
    create GPT partitions
    create Btrfs subvolumes
    create a swapfile
    mount the filesystem
    generate NixOS configuration
    nixos-install

### 🛠 Finish Installation

Inspect the generated configuration:

```
vi /mnt/etc/nixos/configuration.nix
vi /mnt/etc/nixos/hardware-configuration.nix
```

Reboot:

```
reboot
```

### ⚙️ First Boot Setup

Set the password for your user:

```
passwd <username>
```

Switch to your user with `su <username>` and clone the repo again on the new system:

```
git clone https://github.com/D3vlock/nixos-music.git
cd nixos-music
```

Run the bootstrap script:

```
./bootstrap.sh
```

🔧 Apply System Configuration

```
sudo nixos-rebuild switch
```

Log out and log back in (or reboot).

### 🎛 Start SuperCollider

Start the SuperCollider interpreter:

```
sclang
```

The startup script automatically:

    installs SuperDirt if needed
    configures PipeWire
    loads samples
    starts SuperDirt on port 57120

Expected output:

```
SuperDirt: listening on port 57120
```

### 🎹 Start TidalCycles

Open a second terminal:

```
ghci -ghci-script ~/tidal.hs
```

Test playback:

```
d1 $ sound "bd sn"
```

Stop playback:

```
hush
```

🔊 Audio Tools

Useful tools included in the system:

```
wpctl status
```

### 💾 Filesystem Layout

The installer creates this Btrfs layout:

```
/
├── root
├── home
├── nix
└── swap
```

Mount points:

/ → root
/home → home
/nix → nix

Swapfile:

/.swapvol/swapfile

### 📂 Repository Structure

```
.
├── btrfs-install-helper.sh
├── configuration.nix
├── hardware-configuration.nix
├── startup.scd
├── tidal.hs
└── README.md
```

### 🔄 Updating the System

After modifying configuration.nix:

```
sudo nixos-rebuild switch
```

### 📝 Notes

    QT_QPA_PLATFORM=offscreen allows SuperCollider to run without a GUI.
    SuperDirt Quarks install automatically on first run.
    Additional sample packs can be added to:

<!-- -->

### 📜 License

MIT (or whatever license you choose).
