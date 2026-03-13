# 🎵 NixOS TidalCycles Music

NixOS setup for TidalCycles + SuperCollider livecoding with Sway.

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
    prompt to set new password for user

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

Clone the repo again on the new system:

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

or `switch`

Log out and log back in (or reboot).

###  Preferred workflow

Open a terminal and start the `music-session` script located in the `$HOME` folder.  
This will open a tmux session and starts `sclang` and `tidal` in separate panes.  
Open a new pane with `C-Space + c` and open a new file with `nvim music.tidal`.  
Send the line to tidal with `C-Space + t` or the entire file with `C-Space + T`.
Silence it with `C-Space + h`.

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

### 🔊 Audio Tools

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
