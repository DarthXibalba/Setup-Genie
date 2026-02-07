# Golden Image Snapshots Change Log

### Base_v0.0.1: Init
+ Install third-party software for graphics and Wi-Fi hardware
+ Download and install support for additional media formats


### Base_v0.0.2: Dual Display
```
Edit -> Preferences:
-> General
  Uncheck: *Enable XML editing*
-> Console
  Uncheck: *Console autoconnect*
```

```
VirtManager VM -> Settings:
  Video Virtio:
    Edit XML: heads = "2"
  Display Spice:
    Type: Spice server
    Listen type: Address
    Address: Localhost only
    Port: 5900
```

Edit GNOME settings in VM to configure displays


### Base_v0.0.3: DevTools
```
VirtManager:
+ enabled shared memory
+ added hardware filesystem USB thumbdrive
  - source path: /media/username/thumbdrive
  - target path: setupdrive

VM:
sudo mkdir -p /mnt/setupdrive
sudo mount -t virtiofs setupdrive /mnt/setupdrive
```

installed "devtools":
- scripts/setup-bash-profile.sh
- scripts/install-vim.sh
- scripts/install-tools-build-essential.sh
- scripts/install-tools-networking.sh
- scripts/install-golang.sh
- scripts/install-golangci-lint.sh
- scripts/install-python3.sh


### Base_v0.0.4: Browsers
installed:
- scripts/install-vscode.sh (+extensions)
- scripts/install-google-chrome.sh (+sign in)
- scripts/install-rust-desk-client.sh

### Base_v0.0.5:
- Google Drive sign in
- Display resolution
- Dual display resolution

### Base_v0.0.6:
- init-git.sh & Github SSH key creation

### Dev_v1.0.0: System updates 20260205
- Ubuntu system updates

### Dev_v1.0.1: Grow Root
- /usr/local/sbin/anvil-grow-root.sh


### TODO
#### fix NVIDIA Ubuntu Drivers install
#### dev_nvidia v1.0.0: NVIDIA passthru & drivers install
#### fix containers install
#### dev_ctrs v1.0.0: containerd
#### dev_nvidia_ctrs v1.0.0: NVIDIA child + containerd
