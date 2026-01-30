# Arch Linux VM Testing Guide
## Complete Guide for Testing Before Migration from Ubuntu

This guide will walk you through setting up an Arch Linux VM to test Hyprland, Chiaki, and your work VPN before migrating from Ubuntu.

---

## Part 1: VM Setup Prerequisites

### System Requirements (Recommended)
- **RAM**: Allocate 8GB to VM (4GB minimum)
- **Disk**: 40GB virtual disk (20GB minimum)
- **CPU**: 4 cores (2 minimum)
- **Graphics**: Enable 3D acceleration
- **Network**: Bridged mode (for VPN testing)

### Download Required Files

1. **Arch Linux ISO**
   ```bash
   wget https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso
   ```

2. **Your Cisco VPN installer**
   - Place `cisco-secure-client.deb` in a shared folder or download URL

---

## Part 2: VM Software Options

### Option A: VirtualBox (Easiest)

```bash
# Install VirtualBox on Ubuntu
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack

# Create VM
VBoxManage createvm --name "ArchTest" --ostype "ArchLinux_64" --register
VBoxManage modifyvm "ArchTest" --memory 8192 --cpus 4 --vram 128
VBoxManage modifyvm "ArchTest" --nic1 bridged --bridgeadapter1 eth0
VBoxManage createhd --filename ~/VMs/ArchTest.vdi --size 40960
VBoxManage storagectl "ArchTest" --name "SATA Controller" --add sata --bootable on
VBoxManage storageattach "ArchTest" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ~/VMs/ArchTest.vdi
VBoxManage storageattach "ArchTest" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium ~/Downloads/archlinux-x86_64.iso

# Start VM
VBoxManage startvm "ArchTest"
```

### Option B: QEMU/KVM (Better Performance)

```bash
# Install QEMU/KVM
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

# Add user to libvirt group
sudo usermod -aG libvirt $USER
newgrp libvirt

# Create VM using virt-manager GUI
virt-manager
```

### Option C: VMware Workstation Player (Good Middle Ground)

```bash
# Download from VMware website
wget https://www.vmware.com/go/getplayer-linux
chmod +x VMware-Player-*.bundle
sudo ./VMware-Player-*.bundle

# Use GUI to create VM with:
# - Type: Linux
# - Version: Other Linux 5.x kernel 64-bit
# - Disk: 40GB
# - Memory: 8GB
# - Processors: 4
```

---

## Part 3: Arch Linux Base Installation

### Step 1: Boot from ISO

1. Boot the VM from Arch ISO
2. You'll see the Arch installation menu
3. Select "Arch Linux install medium"

### Step 2: Quick Base Install (Using archinstall)

The easiest way is to use the official `archinstall` script:

```bash
# Once booted, run:
archinstall
```

**archinstall Configuration:**

1. **Language**: English
2. **Mirrors**: Select your country (Hungary for you)
3. **Disk configuration**: 
   - Use a best-effort default partition layout
   - Select your virtual disk
   - Filesystem: ext4 (or btrfs if you want snapshots)
4. **Disk encryption**: Optional (not needed for testing)
5. **Bootloader**: GRUB
6. **Swap**: Yes (same as RAM size)
7. **Hostname**: archtest
8. **Root password**: Set a password
9. **User account**: 
   - Username: geri (or your preferred name)
   - Password: Set password
   - Sudo: Yes
10. **Profile**: 
    - Type: Desktop
    - Desktop Environment: None (we'll install Hyprland manually)
11. **Audio**: pipewire
12. **Network configuration**: NetworkManager
13. **Timezone**: Europe/Budapest
14. **Additional packages**: 
    ```
    git base-devel wget curl vim neovim
    ```

15. **Install**: Yes

Wait for installation to complete (5-10 minutes).

### Step 3: Manual Installation (Alternative if archinstall fails)

If you prefer manual control or archinstall has issues:

```bash
# Verify boot mode (should show directory = UEFI)
ls /sys/firmware/efi/efivars

# Update system clock
timedatectl set-ntp true

# Partition disk (assuming /dev/sda)
cfdisk /dev/sda
# Create:
# - 512MB EFI partition (type: EFI System)
# - Remaining space for root (type: Linux filesystem)

# Format partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Install base system
pacstrap /mnt base linux linux-firmware base-devel git networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into new system
arch-chroot /mnt

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "hu_HU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "archtest" > /etc/hostname

# Set root password
passwd

# Create user
useradd -m -G wheel -s /bin/bash geri
passwd geri

# Enable sudo for wheel group
EDITOR=vim visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL

# Install bootloader
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

# Exit and reboot
exit
umount -R /mnt
reboot
```

---

## Part 4: Run the Setup Script

After rebooting into your new Arch installation:

### Step 1: Transfer the Setup Script

**Option A: Download from GitHub Gist** (if you upload it):
```bash
curl -L https://your-gist-url/arch-hyprland-setup.sh -o arch-hyprland-setup.sh
```

**Option B: Shared Folder** (VirtualBox):
```bash
# In VirtualBox, set up shared folder
# Then mount it in Arch:
sudo mkdir /mnt/shared
sudo mount -t vboxsf shared /mnt/shared
cp /mnt/shared/arch-hyprland-setup.sh ~/
```

**Option C: Copy-paste**:
```bash
vim arch-hyprland-setup.sh
# Paste the script content
# Save and exit (:wq)
```

### Step 2: Make Executable and Run

```bash
chmod +x arch-hyprland-setup.sh
./arch-hyprland-setup.sh
```

The script will:
1. Update system packages
2. Install yay (AUR helper)
3. Install Hyprland and Wayland stack
4. Configure PipeWire audio
5. Install graphics drivers
6. Install networking and VPN tools
7. Install Chiaki
8. Install meeting apps (you'll be prompted)
9. Configure Hyprland
10. Create testing scripts
11. Generate documentation

**Time**: 15-30 minutes depending on internet speed

### Step 3: Reboot

```bash
sudo reboot
```

---

## Part 5: First Boot into Hyprland

### Login

At the login screen:
1. Select your user
2. Before entering password, check if there's a session selector
3. Select "Hyprland"
4. Enter password

### First Impressions

- You should see a minimal desktop
- Wallpaper might be blank (this is normal)
- Super + Enter should open a terminal
- Super + D should open application launcher

---

## Part 6: Testing Procedure

### Read the README

```bash
cat ~/POST_INSTALL_README.txt
```

### Run Comprehensive Tests

```bash
cd ~/testing-scripts
./run-all-tests.sh
```

This will guide you through testing:

1. **Audio System**
2. **Screen Sharing**  
3. **Chiaki PS5**
4. **VPN Connection**

### Individual Test Details

#### Test 1: Audio

```bash
./test-audio.sh
```

**What to verify:**
- PipeWire is running
- Can hear test tone
- Microphone works (test in `pavucontrol`)
- No crackling or distortion

#### Test 2: Screen Sharing

```bash
./test-screenshare.sh
```

**What to verify:**
- Install a meeting app if not done during setup
- Join a test meeting
- Share screen - portal picker should appear
- Verify shared content is visible

**Troubleshooting:**
```bash
# If screen sharing doesn't work:
systemctl --user restart xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal

# Check logs:
journalctl --user -u xdg-desktop-portal-hyprland -n 50
```

#### Test 3: Chiaki (PS5 Remote Play)

```bash
./test-chiaki.sh
```

**Setup steps:**
1. Connect PS5 controller via USB
2. Launch Chiaki
3. Click "Add Console"
4. Follow registration wizard
   - You'll need your PSN account ID
   - Console must be on same network as VM
   - May need to enable remote play on PS5

**What to verify:**
- Can register PS5
- Can connect and stream
- Audio/video sync
- Controller input works
- Acceptable latency (<100ms)

**Network considerations for VM:**
- Bridged networking recommended
- VM and PS5 should be on same subnet
- Test ping: `ping <PS5_IP>`
- Expected latency: <5ms on local network

#### Test 4: VPN

```bash
./test-vpn.sh
```

**Prerequisites:**
- Copy `cisco-secure-client.deb` to ~/

**What to verify:**
- .deb converts successfully
- Package installs
- Can connect to VPN
- Can access work resources

**Alternative - OpenConnect:**
```bash
sudo openconnect your-vpn-server.com
# Enter credentials when prompted
```

Many Cisco VPNs work with openconnect even if the company only provides .deb files.

---

## Part 7: Extended Testing (Days 2-5)

### Day 2: Daily Driver Test

Use the VM as your main system for a full work day:

- [ ] Morning standup/meeting with screen share
- [ ] Work on code/research for 4+ hours
- [ ] Multiple browser tabs, applications open
- [ ] Lunch break - test Chiaki gaming
- [ ] Afternoon meetings
- [ ] VPN connected all day

**Stability checks:**
- Does Hyprland crash?
- Memory leaks? (Check with `htop`)
- Audio glitches during meetings?
- Screen sharing stability?

### Day 3: Stress Test

- [ ] Join meeting while streaming from PS5
- [ ] Open 50+ browser tabs
- [ ] Compile large project
- [ ] Multiple workspaces, many windows
- [ ] Rapid workspace switching

### Day 4: Real Workflow

- [ ] Stata data analysis (if you do this)
- [ ] Python/R work
- [ ] Document writing (LaTeX, LibreOffice)
- [ ] File management, organizing
- [ ] Video playback, media

### Day 5: Edge Cases

- [ ] Reconnect VPN after network change
- [ ] Hot-plug external monitor (if possible)
- [ ] USB device hot-plug
- [ ] Suspend/resume (may not work in VM)
- [ ] System updates: `sudo pacman -Syu`

---

## Part 8: Testing Checklist

### Critical Must-Work Items

- [ ] **Audio in/out works reliably**
- [ ] **Can screen share in meetings**
- [ ] **Chiaki connects and streams**
- [ ] **VPN connects and stable**
- [ ] **System stable for 8+ hours**
- [ ] **No dealbreaker crashes**

### Nice-to-Have Items

- [ ] Smooth animations
- [ ] Fast application launch
- [ ] Good battery life (if laptop)
- [ ] All shortcuts work
- [ ] Touchpad gestures (if applicable)

### Performance Comparison

Compare with Ubuntu:

| Metric | Ubuntu | Arch + Hyprland | Winner |
|--------|--------|-----------------|--------|
| RAM usage (idle) | ___MB | ___MB | ___ |
| Boot time | ___s | ___s | ___ |
| App launch time | ___ | ___ | ___ |
| Meeting stability | ___/10 | ___/10 | ___ |
| Gaming latency | ___ms | ___ms | ___ |
| Overall feel | ___/10 | ___/10 | ___ |

---

## Part 9: Decision Making

### Go/No-Go Criteria

**GO (Migrate to Arch):**
- ✅ All critical items work
- ✅ Stable for 3+ consecutive days
- ✅ Performance equal or better than Ubuntu
- ✅ You're comfortable with the workflow
- ✅ Troubleshooting issues was manageable

**NO-GO (Stay on Ubuntu):**
- ❌ Critical work tools don't work
- ❌ VPN completely broken
- ❌ Frequent crashes or freezes
- ❌ Can't fix issues after research
- ❌ Productivity significantly impacted

**MAYBE (Dual Boot First):**
- ⚠️ Most things work, some minor issues
- ⚠️ Need more time to test
- ⚠️ Want to keep Ubuntu as backup
- ⚠️ Migration feels risky

---

## Part 10: Migration Paths

### Option A: Full Migration (Confident)

1. Backup Ubuntu `/home` completely
2. Backup important configs (`~/.config`, `~/.bashrc`, etc.)
3. Create Arch bootable USB
4. Backup/export browser data, app settings
5. Install Arch on real hardware
6. Run setup script
7. Restore personal files
8. Configure additional work tools

**Timeline**: 1 weekend day

### Option B: Dual Boot (Cautious)

1. Shrink Ubuntu partition (use GParted)
2. Create new partition for Arch (40GB+)
3. Install Arch alongside Ubuntu
4. Configure GRUB to show both
5. Use Arch as primary, Ubuntu as fallback
6. After 1 month of stability, remove Ubuntu

**Timeline**: 1 weekend + 1 month testing

### Option C: Slow Transition (Very Cautious)

1. Keep VM for work
2. Continue using Ubuntu on host
3. Gradually move workflows to VM
4. When 100% confident, do Option B
5. Eventually move to Option A

**Timeline**: 1-3 months

---

## Part 11: Troubleshooting Common Issues

### Issue: No Internet in Arch VM

```bash
# Check NetworkManager
sudo systemctl status NetworkManager
sudo systemctl start NetworkManager

# Manual DHCP
sudo dhcpcd

# Check connection
ip addr
ping 8.8.8.8
```

### Issue: Can't Start Hyprland

```bash
# Check logs
cat ~/.cache/hyprland/hyprland.log

# Try starting manually
Hyprland

# Verify installation
which Hyprland
pacman -Q hyprland
```

### Issue: Black Screen After Login

```bash
# Switch to TTY: Ctrl + Alt + F2
# Login
# Check graphics drivers
lspci | grep VGA
ls /usr/lib/xorg/modules/drivers/

# Reinstall drivers
sudo pacman -S xf86-video-vmware  # For VMware
sudo pacman -S xf86-video-vesa     # Generic fallback
```

### Issue: Audio Doesn't Work

```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check status
systemctl --user status pipewire

# Verify devices
pactl list sinks
pactl list sources

# Set default sink
pactl set-default-sink @DEFAULT_SINK@
```

### Issue: VM is Too Slow

**VirtualBox:**
```bash
# Enable 3D acceleration
VBoxManage modifyvm "ArchTest" --accelerate3d on

# Increase VRAM
VBoxManage modifyvm "ArchTest" --vram 128

# Enable nested VT-x
VBoxManage modifyvm "ArchTest" --nested-hw-virt on
```

**QEMU/KVM:**
```bash
# Edit VM in virt-manager
# Video: Virtio
# Disk: VirtIO
# Network: VirtIO
# Add: Channel (Spice agent)
```

### Issue: Shared Clipboard Not Working

**VirtualBox:**
```bash
# Install Guest Additions
sudo pacman -S virtualbox-guest-utils
sudo systemctl enable vboxservice
```

**VMware:**
```bash
# Install open-vm-tools
sudo pacman -S open-vm-tools
sudo systemctl enable vmtoolsd
```

---

## Part 12: Optimization Tips

### Improve VM Performance

1. **Allocate more resources** (if host allows)
2. **Use VirtIO drivers** (QEMU/KVM)
3. **Enable hardware acceleration**
4. **Use SSD** for virtual disk
5. **Close host applications** during testing

### Make Testing More Efficient

1. **Take snapshots** before major changes
2. **Document issues** as you find them
3. **Script repetitive tasks**
4. **Keep a testing journal**

### Hyprland Optimization

Add to `~/.config/hypr/hyprland.conf`:

```bash
# For better VM performance
decoration {
    blur {
        enabled = false  # Disable blur in VM
    }
}

animations {
    enabled = yes
    # Use faster animations in VM
    animation = windows, 1, 3, default
    animation = fade, 1, 3, default
}
```

---

## Part 13: Resources

### Documentation
- Arch Wiki: https://wiki.archlinux.org
- Hyprland Wiki: https://wiki.hyprland.org
- Chiaki: https://git.sr.ht/~thestr4ng3r/chiaki

### Community
- Arch Forums: https://bbs.archlinux.org
- Hyprland Discord: https://discord.gg/hyprland
- Reddit: r/archlinux, r/hyprland

### Your Config Backup
When you're happy with your setup:

```bash
# Backup your configs
mkdir ~/hyprland-configs-backup
cp -r ~/.config/hypr ~/hyprland-configs-backup/
cp -r ~/.config/waybar ~/hyprland-configs-backup/
cp -r ~/.config/kitty ~/hyprland-configs-backup/
tar czf ~/hyprland-backup-$(date +%Y%m%d).tar.gz ~/hyprland-configs-backup/
```

---

## Quick Start Summary

For the impatient (TL;DR):

```bash
# 1. Create VM (8GB RAM, 40GB disk, bridged network)
# 2. Install Arch using archinstall
# 3. Boot into Arch, login
# 4. Transfer and run setup script:
chmod +x arch-hyprland-setup.sh
./arch-hyprland-setup.sh

# 5. Reboot
sudo reboot

# 6. Login to Hyprland
# 7. Run tests:
cd ~/testing-scripts
./run-all-tests.sh

# 8. Use for 3-5 days
# 9. Make migration decision
```

---

**Good luck with your testing! 🚀**

If you have any issues, document them and we can troubleshoot. The VM environment is perfect for experimenting without risk to your working Ubuntu setup.
