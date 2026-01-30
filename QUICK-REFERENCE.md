# Hyprland Quick Reference Card

## Essential Keyboard Shortcuts

### Window Management
| Shortcut | Action |
|----------|--------|
| `Super + Enter` | Open terminal (Kitty) |
| `Super + D` | Application launcher (Wofi) |
| `Super + Q` | Close focused window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating |
| `Super + P` | Toggle pseudo-tiling |
| `Super + J` | Toggle split direction |
| `Super + M` | Exit Hyprland |

### Navigation
| Shortcut | Action |
|----------|--------|
| `Super + ←/→/↑/↓` | Move focus (arrows) |
| `Super + H/L/K/J` | Move focus (vim keys) |
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + Shift + 1-9` | Move window to workspace 1-9 |
| `Super + Mouse Wheel` | Cycle workspaces |

### Special Workspaces
| Shortcut | Action |
|----------|--------|
| `Super + S` | Toggle scratchpad workspace |
| `Super + Shift + S` | Move window to scratchpad |
| `Super + G` | Toggle gaming workspace (for Chiaki) |
| `Super + Shift + G` | Move window to gaming workspace |

### Window Moving & Resizing
| Shortcut | Action |
|----------|--------|
| `Super + Left Mouse` | Move window |
| `Super + Right Mouse` | Resize window |

### Screenshots
| Shortcut | Action |
|----------|--------|
| `Print Screen` | Select area → clipboard |
| `Shift + Print Screen` | Save to ~/Pictures |

### Media Controls
| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute toggle |
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |

### Lockscreen
| Shortcut | Action |
|----------|--------|
| `Super + L` | Lock screen |

---

## Essential Commands

### System Management

```bash
# Update system
sudo pacman -Syu

# Install package
sudo pacman -S package-name

# Install from AUR
yay -S package-name

# Remove package
sudo pacman -R package-name

# Search packages
pacman -Ss search-term
yay -Ss search-term

# Clean package cache
sudo pacman -Sc

# List installed packages
pacman -Q

# Check package info
pacman -Qi package-name
```

### Hyprland Commands

```bash
# Reload Hyprland config
hyprctl reload

# Kill Hyprland (exit to login)
hyprctl dispatch exit

# List windows
hyprctl clients

# List workspaces
hyprctl workspaces

# Get monitor info
hyprctl monitors

# Execute command
hyprctl dispatch exec program-name
```

### Audio Management

```bash
# Open volume control GUI
pavucontrol

# List audio devices
pactl list sinks short        # Output devices
pactl list sources short      # Input devices

# Set default output
pactl set-default-sink SINK_NAME

# Adjust volume
pamixer -i 5    # Increase 5%
pamixer -d 5    # Decrease 5%
pamixer -t      # Toggle mute

# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check PipeWire status
systemctl --user status pipewire
```

### Network & VPN

```bash
# NetworkManager CLI
nmcli device status              # List network devices
nmcli connection show            # List connections
nmcli connection up VPN_NAME     # Connect VPN
nmcli connection down VPN_NAME   # Disconnect VPN

# OpenConnect (Cisco VPN alternative)
sudo openconnect vpn-server.com

# Check network
ip addr          # Show IP addresses
ip route         # Show routing table
ping 8.8.8.8     # Test connectivity
```

### System Monitoring

```bash
# Resource monitor
htop             # Classic
btop             # Modern, prettier

# GPU monitoring
nvtop            # NVIDIA
radeontop        # AMD
intel_gpu_top    # Intel

# Disk usage
df -h            # Filesystem usage
du -sh *         # Directory sizes

# Check system logs
journalctl -xe                   # Recent errors
journalctl -b                    # Boot log
journalctl --user -u pipewire    # PipeWire logs
```

### File Management

```bash
# Open file manager
thunar

# Quick navigation
cd ~             # Home directory
cd -             # Previous directory
cd ..            # Parent directory

# File operations
cp file1 file2           # Copy
mv file1 file2           # Move/rename
rm file                  # Delete file
rm -rf directory         # Delete directory
mkdir directory          # Create directory
```

---

## Chiaki (PS5 Remote Play)

### Launch Chiaki
```bash
# Standard launch
chiaki

# With gamemode (better performance)
gamemoderun chiaki

# With MangoHud overlay (FPS counter)
mangohud chiaki

# Both
gamemoderun mangohud chiaki
```

### Chiaki Tips

**First-time setup:**
1. Connect PS5 controller via USB
2. Enable Remote Play on PS5: Settings → System → Remote Play
3. In Chiaki: Add Console → Follow registration wizard
4. You'll need your PSN account ID

**Best performance:**
- Use 720p resolution for lower latency
- Ethernet on both PC and PS5
- Close other applications
- Enable gamemode

**Controller troubleshooting:**
```bash
# Check if controller is detected
ls /dev/input/js*

# Test controller input
jstest /dev/input/js0

# If no Bluetooth:
sudo systemctl start bluetooth
sudo systemctl enable bluetooth
bluetoothctl
> power on
> scan on
> pair XX:XX:XX:XX:XX:XX
> connect XX:XX:XX:XX:XX:XX
```

---

## Screen Sharing (Meetings)

### Fix Screen Sharing Issues

```bash
# Restart portals
systemctl --user restart xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal

# Check portal status
systemctl --user status xdg-desktop-portal-hyprland

# View portal logs
journalctl --user -u xdg-desktop-portal-hyprland -f

# Verify xwaylandvideobridge
pgrep -a xwaylandvideobridge
```

### Meeting App Launch

```bash
# Zoom
zoom

# Slack
slack

# Discord
discord

# Teams
teams-for-linux
```

---

## Troubleshooting

### Hyprland Won't Start

```bash
# Switch to TTY
Ctrl + Alt + F2

# Check Hyprland log
cat ~/.cache/hyprland/hyprland.log

# Try starting manually
Hyprland

# Check config syntax
hyprctl reload
```

### Audio Not Working

```bash
# Restart PipeWire
systemctl --user restart pipewire wireplumber

# Check if running
systemctl --user status pipewire

# Verify devices
pactl list sinks
aplay -l

# Open mixer
pavucontrol
```

### Chiaki Laggy or Stuttering

```bash
# Check network latency
ping YOUR_PS5_IP

# Check CPU usage
htop

# Reduce quality in Chiaki settings:
# Resolution: 720p
# FPS: 30 (if 60 is laggy)
# Bitrate: Lower

# Enable hardware acceleration
# Check: vainfo
# Should show decode support
```

### VPN Connection Issues

```bash
# Check NetworkManager logs
journalctl -u NetworkManager -n 50

# Try OpenConnect instead
sudo openconnect your-vpn-server.com

# Check routes after VPN connect
ip route
```

### Screen Tearing

Add to `~/.config/hypr/hyprland.conf`:
```bash
misc {
    vrr = 2  # Adaptive sync
}
```

### High Memory Usage

```bash
# Check memory
free -h

# Find memory hogs
ps aux --sort=-%mem | head -10

# Clear cache
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

---

## Configuration Files

### Main Config Locations

```bash
~/.config/hypr/hyprland.conf          # Hyprland config
~/.config/waybar/config               # Waybar (taskbar)
~/.config/waybar/style.css            # Waybar styling
~/.config/kitty/kitty.conf            # Terminal config
~/.config/wofi/style.css              # App launcher styling
~/.config/dunst/dunstrc               # Notification daemon
```

### Quick Config Edits

```bash
# Edit Hyprland config
nvim ~/.config/hypr/hyprland.conf
# Then reload
hyprctl reload

# Edit terminal config
nvim ~/.config/kitty/kitty.conf
# Restart terminal to apply
```

---

## Performance Optimization

### Gaming Mode

```bash
# Enable gamemode for a game
gamemoderun ./game

# Check gamemode status
gamemoded -s

# Add to autostart (if needed)
systemctl --user enable gamemoded
```

### Disable Animations (for slower systems)

In `~/.config/hypr/hyprland.conf`:
```bash
animations {
    enabled = no
}
```

### Reduce Blur/Effects

In `~/.config/hypr/hyprland.conf`:
```bash
decoration {
    blur {
        enabled = false
    }
    drop_shadow = no
}
```

---

## Backup & Restore

### Backup Your Config

```bash
# Create backup
cd ~
tar czf hyprland-backup-$(date +%Y%m%d).tar.gz \
    .config/hypr \
    .config/waybar \
    .config/kitty \
    .config/wofi \
    .config/dunst

# List backup contents
tar tzf hyprland-backup-20240129.tar.gz
```

### Restore Config

```bash
# Extract backup
cd ~
tar xzf hyprland-backup-20240129.tar.gz

# Reload Hyprland
hyprctl reload
```

### Export Package List

```bash
# Save installed packages
pacman -Qqe > ~/pkglist.txt

# Reinstall from list
sudo pacman -S --needed - < ~/pkglist.txt
```

---

## Testing Scripts

All testing scripts are in `~/testing-scripts/`:

```bash
# Run all tests
~/testing-scripts/run-all-tests.sh

# Individual tests
~/testing-scripts/test-audio.sh
~/testing-scripts/test-screenshare.sh
~/testing-scripts/test-chiaki.sh
~/testing-scripts/test-vpn.sh
```

---

## Getting Help

### Check Logs

```bash
# System logs
journalctl -xe

# Hyprland log
cat ~/.cache/hyprland/hyprland.log

# PipeWire logs
journalctl --user -u pipewire -n 100

# Full boot log
journalctl -b
```

### Community Resources

- **Arch Wiki**: https://wiki.archlinux.org
- **Hyprland Wiki**: https://wiki.hyprland.org  
- **Arch Forums**: https://bbs.archlinux.org
- **Reddit**: r/archlinux, r/hyprland

### Report Issues

```bash
# Get system info
uname -a
pacman -Q hyprland
pacman -Q pipewire

# Share Hyprland log
cat ~/.cache/hyprland/hyprland.log

# Share hardware info
lspci | grep VGA
```

---

**Print this card or keep it open in a second workspace while learning Hyprland!**
