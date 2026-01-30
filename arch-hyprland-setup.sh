#!/bin/bash
# Arch Linux Hyprland Gaming & Work Setup Script
# For VM testing before migration
# Author: Setup for Geri
# Purpose: Test Hyprland stability, Chiaki (PS5), and Cisco VPN

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should NOT be run as root (except for the initial pacman parts)"
   error "Run it as your regular user. It will use sudo when needed."
   exit 1
fi

# Function to prompt for continuation
prompt_continue() {
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
}

###############################################################################
# SECTION 1: BASE SYSTEM UPDATE
###############################################################################

section_base_update() {
    log "=== SECTION 1: Base System Update ==="
    
    info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    info "Installing base development tools..."
    sudo pacman -S --needed --noconfirm \
        base-devel git wget curl \
        vim neovim \
        htop btop \
        unzip tar
    
    log "Base system updated successfully"
}

###############################################################################
# SECTION 2: AUR HELPER (yay)
###############################################################################

section_install_yay() {
    log "=== SECTION 2: Installing AUR Helper (yay) ==="
    
    if command -v yay &> /dev/null; then
        info "yay is already installed"
        return
    fi
    
    info "Installing yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    
    log "yay installed successfully"
}

###############################################################################
# SECTION 3: HYPRLAND & WAYLAND ECOSYSTEM
###############################################################################

section_install_hyprland() {
    log "=== SECTION 3: Installing Hyprland & Wayland Stack ==="
    
    info "Installing Hyprland core..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        qt5-wayland qt6-wayland \
        polkit-kde-agent
    
    info "Installing Wayland utilities..."
    sudo pacman -S --needed --noconfirm \
        waybar \
        wofi \
        swaybg \
        swaylock \
        swayidle \
        wl-clipboard \
        grim \
        slurp \
        brightnessctl \
        playerctl \
        dunst
    
    info "Installing terminal emulator..."
    sudo pacman -S --needed --noconfirm kitty
    
    log "Hyprland stack installed successfully"
}

###############################################################################
# SECTION 4: AUDIO SYSTEM (PipeWire)
###############################################################################

section_install_audio() {
    log "=== SECTION 4: Installing Audio System (PipeWire) ==="
    
    info "Installing PipeWire and related packages..."
    sudo pacman -S --needed --noconfirm \
        pipewire \
        pipewire-pulse \
        pipewire-alsa \
        pipewire-jack \
        wireplumber \
        pavucontrol \
        pamixer
    
    info "Enabling PipeWire services..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber
    
    # Create low-latency config for gaming
    info "Creating gaming audio configuration..."
    mkdir -p ~/.config/pipewire/pipewire.conf.d/
    cat > ~/.config/pipewire/pipewire.conf.d/10-gaming.conf <<EOF
# Low-latency configuration for gaming and streaming
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 512
}
EOF
    
    systemctl --user restart pipewire wireplumber
    
    log "Audio system configured successfully"
}

###############################################################################
# SECTION 5: VIDEO & GRAPHICS
###############################################################################

section_install_graphics() {
    log "=== SECTION 5: Installing Graphics Drivers & Hardware Acceleration ==="
    
    info "Detecting GPU..."
    GPU_VENDOR=$(lspci | grep -i 'vga\|3d\|2d' | head -n 1)
    echo "Detected: $GPU_VENDOR"
    
    info "Installing Mesa and VA-API..."
    sudo pacman -S --needed --noconfirm \
        mesa \
        libva-mesa-driver \
        mesa-vdpau
    
    # Detect and install appropriate drivers
    if echo "$GPU_VENDOR" | grep -iq "nvidia"; then
        warning "NVIDIA GPU detected"
        info "Installing NVIDIA drivers..."
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils
    elif echo "$GPU_VENDOR" | grep -iq "amd"; then
        info "AMD GPU detected"
        sudo pacman -S --needed --noconfirm \
            vulkan-radeon lib32-vulkan-radeon \
            xf86-video-amdgpu
    elif echo "$GPU_VENDOR" | grep -iq "intel"; then
        info "Intel GPU detected"
        sudo pacman -S --needed --noconfirm \
            vulkan-intel lib32-vulkan-intel \
            intel-media-driver
    else
        warning "Could not detect GPU vendor, installing generic drivers"
    fi
    
    info "Installing Vulkan tools..."
    sudo pacman -S --needed --noconfirm vulkan-tools
    
    log "Graphics drivers installed successfully"
}

###############################################################################
# SECTION 6: NETWORKING & VPN TOOLS
###############################################################################

section_install_networking() {
    log "=== SECTION 6: Installing Networking & VPN Tools ==="
    
    info "Installing network tools..."
    sudo pacman -S --needed --noconfirm \
        networkmanager \
        network-manager-applet \
        openconnect \
        networkmanager-openconnect \
        nm-connection-editor
    
    info "Enabling NetworkManager..."
    sudo systemctl enable --now NetworkManager
    
    info "Installing debtap for .deb conversion..."
    yay -S --needed --noconfirm debtap
    
    info "Updating debtap database (this may take a few minutes)..."
    sudo debtap -u || warning "debtap update had issues, may need to run manually"
    
    log "Networking tools installed successfully"
}

###############################################################################
# SECTION 7: CHIAKI (PS5 REMOTE PLAY)
###############################################################################

section_install_chiaki() {
    log "=== SECTION 7: Installing Chiaki (PS5 Remote Play) ==="
    
    info "Installing Chiaki Next Generation (recommended version)..."
    yay -S --needed --noconfirm chiaki-ng || {
        warning "chiaki-ng not available, falling back to standard chiaki"
        sudo pacman -S --needed --noconfirm chiaki
    }
    
    info "Installing gaming dependencies..."
    sudo pacman -S --needed --noconfirm \
        gamemode \
        lib32-gamemode \
        mangohud \
        lib32-mangohud \
        goverlay
    
    info "Installing controller support..."
    sudo pacman -S --needed --noconfirm \
        libmanette \
        antimicrox
    
    # Enable gamemode
    info "Configuring gamemode..."
    sudo usermod -aG gamemode $USER
    
    # Create gaming environment config
    info "Creating gaming environment configuration..."
    mkdir -p ~/.config/environment.d/
    cat > ~/.config/environment.d/gaming.conf <<EOF
# Gaming optimizations
SDL_AUDIODRIVER=pipewire
PULSE_LATENCY_MSEC=60
MANGOHUD=1
EOF
    
    # Network optimizations for streaming
    info "Applying network optimizations for game streaming..."
    sudo tee /etc/sysctl.d/90-chiaki.conf > /dev/null <<EOF
# Network optimizations for PS5 Remote Play
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_fastopen=3
EOF
    
    sudo sysctl --system
    
    log "Chiaki and gaming tools installed successfully"
}

###############################################################################
# SECTION 8: MEETING & SCREEN SHARING APPS
###############################################################################

section_install_meeting_apps() {
    log "=== SECTION 8: Installing Meeting & Communication Apps ==="
    
    info "Installing communication apps..."
    
    # Check which apps to install
    echo "Which meeting apps do you use? (y/n for each)"
    
    read -p "Install Zoom? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        yay -S --needed --noconfirm zoom
    fi
    
    read -p "Install Slack? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        yay -S --needed --noconfirm slack-desktop
    fi
    
    read -p "Install Discord? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm discord
    fi
    
    read -p "Install Microsoft Teams? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        yay -S --needed --noconfirm teams-for-linux
    fi
    
    log "Meeting apps installed successfully"
}

###############################################################################
# SECTION 9: HYPRLAND CONFIGURATION
###############################################################################

section_configure_hyprland() {
    log "=== SECTION 9: Configuring Hyprland ==="
    
    info "Creating Hyprland configuration directory..."
    mkdir -p ~/.config/hypr
    
    info "Creating optimized Hyprland configuration..."
    cat > ~/.config/hypr/hyprland.conf <<'EOF'
# Hyprland Configuration
# Optimized for gaming, meetings, and stability

###############################################################################
# MONITORS
###############################################################################
monitor=,preferred,auto,1

###############################################################################
# AUTOSTART
###############################################################################
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = waybar
exec-once = dunst
exec-once = nm-applet --indicator

###############################################################################
# ENVIRONMENT VARIABLES
###############################################################################
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = SDL_VIDEODRIVER,wayland
env = GDK_BACKEND,wayland,x11

###############################################################################
# INPUT
###############################################################################
input {
    kb_layout = us,hu
    kb_variant =
    kb_model =
    kb_options = grp:alt_shift_toggle
    kb_rules =

    follow_mouse = 1

    touchpad {
        natural_scroll = yes
    }

    sensitivity = 0
}

###############################################################################
# GENERAL
###############################################################################
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle
    allow_tearing = true  # For gaming
}

###############################################################################
# DECORATION
###############################################################################
decoration {
    rounding = 8
    
    blur {
        enabled = true
        size = 3
        passes = 1
    }

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

###############################################################################
# ANIMATIONS
###############################################################################
animations {
    enabled = yes

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default
}

###############################################################################
# LAYOUTS
###############################################################################
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_status = master
}

###############################################################################
# GESTURES
###############################################################################
gestures {
    workspace_swipe = on
}

###############################################################################
# MISC
###############################################################################
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    vrr = 1  # Variable refresh rate for gaming
}

###############################################################################
# WINDOW RULES
###############################################################################

# Screen sharing
windowrulev2 = opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$
windowrulev2 = noanim,class:^(xwaylandvideobridge)$
windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$
windowrulev2 = maxsize 1 1,class:^(xwaylandvideobridge)$
windowrulev2 = noblur,class:^(xwaylandvideobridge)$

# Chiaki (PS5 Remote Play) - Gaming optimizations
windowrulev2 = fullscreen,class:^(Chiaki|chiaki)$
windowrulev2 = immediate,class:^(Chiaki|chiaki)$
windowrulev2 = noborder,class:^(Chiaki|chiaki)$
windowrulev2 = workspace special:gaming,class:^(Chiaki|chiaki)$
windowrulev2 = allowsinput,class:^(Chiaki|chiaki)$

# Gaming in general
windowrulev2 = immediate,class:^(steam_app_.*)$
windowrulev2 = fullscreen,class:^(steam_app_.*)$

# Meeting apps - prevent sleep
windowrulev2 = idleinhibit focus,class:^(zoom)$
windowrulev2 = idleinhibit focus,class:^(slack)$
windowrulev2 = idleinhibit focus,class:^(teams-for-linux)$
windowrulev2 = idleinhibit focus,class:^(discord)$

# Picture-in-Picture
windowrulev2 = float,title:^(Picture-in-Picture)$
windowrulev2 = pin,title:^(Picture-in-Picture)$
windowrulev2 = move 100%-25% 100%-25%,title:^(Picture-in-Picture)$

###############################################################################
# KEYBINDINGS
###############################################################################
$mainMod = SUPER

# Applications
bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive, 
bind = $mainMod, M, exit, 
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating, 
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen, 0

# Screenshots
bind = , PRINT, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, PRINT, exec, grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus with mainMod + vim keys
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Gaming workspace
bind = $mainMod, G, togglespecialworkspace, gaming
bind = $mainMod SHIFT, G, movetoworkspace, special:gaming

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Media keys
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl s +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl s 5%-

# Lock screen
bind = $mainMod, L, exec, swaylock -f -c 000000
EOF
    
    log "Hyprland configuration created successfully"
}

###############################################################################
# SECTION 10: ADDITIONAL TOOLS
###############################################################################

section_install_additional_tools() {
    log "=== SECTION 10: Installing Additional Tools ==="
    
    info "Installing file manager and utilities..."
    sudo pacman -S --needed --noconfirm \
        thunar \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        file-roller \
        gvfs \
        gvfs-mtp
    
    info "Installing fonts..."
    sudo pacman -S --needed --noconfirm \
        ttf-dejavu \
        ttf-liberation \
        noto-fonts \
        noto-fonts-emoji \
        ttf-font-awesome
    
    info "Installing system monitoring tools..."
    sudo pacman -S --needed --noconfirm \
        htop \
        btop \
        nvtop
    
    log "Additional tools installed successfully"
}

###############################################################################
# SECTION 11: CREATE TESTING SCRIPTS
###############################################################################

section_create_test_scripts() {
    log "=== SECTION 11: Creating Testing Scripts ==="
    
    mkdir -p ~/testing-scripts
    
    # Chiaki test script
    cat > ~/testing-scripts/test-chiaki.sh <<'CHIAKI_EOF'
#!/bin/bash
# Chiaki PS5 Remote Play Testing Script

echo "=== Chiaki PS5 Remote Play Test ==="
echo ""
echo "This script will help you test Chiaki functionality"
echo ""

# Check if Chiaki is installed
if ! command -v chiaki &> /dev/null && ! command -v Chiaki &> /dev/null; then
    echo "ERROR: Chiaki is not installed!"
    exit 1
fi

echo "✓ Chiaki is installed"

# Check hardware acceleration
echo ""
echo "Checking hardware acceleration..."
vainfo 2>/dev/null | grep -q "VAEntrypointVLD" && echo "✓ Hardware video decoding available" || echo "✗ No hardware decoding found"

# Check audio
echo ""
echo "Checking audio system..."
pactl info | grep -q "Server Name: PulseAudio (on PipeWire" && echo "✓ PipeWire is running" || echo "✗ PipeWire not detected"

# Check network optimization
echo ""
echo "Checking network optimizations..."
sysctl net.core.rmem_max | grep -q "134217728" && echo "✓ Network buffers optimized" || echo "✗ Network not optimized"

# Check gamemode
echo ""
echo "Checking gamemode..."
command -v gamemoded &> /dev/null && echo "✓ Gamemode is installed" || echo "✗ Gamemode not found"

echo ""
echo "=== Manual Testing Steps ==="
echo "1. Connect your PS5 controller (USB or Bluetooth)"
echo "2. Launch Chiaki: chiaki"
echo "3. Register your PS5 (you'll need your PSN account)"
echo "4. Test connection and streaming quality"
echo "5. Check for audio/video sync issues"
echo "6. Test controller input lag"
echo ""
echo "Expected results:"
echo "- Video: Smooth 1080p60 or 720p60 depending on network"
echo "- Audio: Synchronized, no crackling"
echo "- Input: Minimal lag (<50ms on good network)"
echo ""
echo "Press Enter to launch Chiaki..."
read

if command -v chiaki &> /dev/null; then
    chiaki
else
    Chiaki
fi
CHIAKI_EOF
    
    chmod +x ~/testing-scripts/test-chiaki.sh
    
    # VPN test script
    cat > ~/testing-scripts/test-vpn.sh <<'VPN_EOF'
#!/bin/bash
# Cisco VPN Testing Script

echo "=== Cisco VPN Test ==="
echo ""

if [ ! -f ~/cisco-secure-client.deb ]; then
    echo "ERROR: Please place your cisco-secure-client.deb file in your home directory"
    exit 1
fi

echo "Found Cisco installer: ~/cisco-secure-client.deb"
echo ""
echo "Converting .deb to Arch package..."
echo "This may take a few minutes..."

cd ~
debtap -q cisco-secure-client.deb

echo ""
echo "Conversion complete. Installing package..."
CONVERTED_PKG=$(ls -t cisco-secure-client*.pkg.tar.zst 2>/dev/null | head -1)

if [ -z "$CONVERTED_PKG" ]; then
    echo "ERROR: Could not find converted package"
    exit 1
fi

echo "Installing: $CONVERTED_PKG"
sudo pacman -U "$CONVERTED_PKG"

echo ""
echo "=== Testing VPN Connection ==="
echo ""
echo "Manual test steps:"
echo "1. Launch Cisco Secure Client"
echo "2. Enter your organization's VPN server address"
echo "3. Authenticate with your credentials"
echo "4. Verify connection status"
echo "5. Test access to internal resources"
echo ""
echo "Alternative: Try OpenConnect"
echo "If Cisco client doesn't work, test with:"
echo "  sudo openconnect YOUR_VPN_SERVER"
echo ""
echo "Press Enter to continue..."
read
VPN_EOF
    
    chmod +x ~/testing-scripts/test-vpn.sh
    
    # Screen sharing test script
    cat > ~/testing-scripts/test-screenshare.sh <<'SCREEN_EOF'
#!/bin/bash
# Screen Sharing Testing Script

echo "=== Screen Sharing Test ==="
echo ""

# Check portals
echo "Checking XDG portals..."
ls /usr/share/xdg-desktop-portal/portals/ 2>/dev/null

echo ""
echo "Active portal:"
XDG_CURRENT_DESKTOP=Hyprland xdg-desktop-portal -r &
sleep 2
pkill xdg-desktop-portal

echo ""
echo "=== Manual Testing Steps ==="
echo ""
echo "Test in your meeting app:"
echo "1. Join a test meeting (Zoom/Teams/Slack)"
echo "2. Try to share your screen"
echo "3. You should see a portal dialog to select windows/screens"
echo "4. Verify the shared content is visible to others"
echo "5. Check audio quality during screen share"
echo ""
echo "Expected behavior:"
echo "- Portal picker appears when sharing"
echo "- Can select individual windows or entire screen"
echo "- Smooth framerate (30+ fps)"
echo "- Audio continues working"
echo ""
echo "If issues occur:"
echo "- Check that xwaylandvideobridge is running"
echo "- Verify portal configuration in ~/.config/xdg-desktop-portal/"
echo "- Restart Hyprland and try again"
echo ""
SCREEN_EOF
    
    chmod +x ~/testing-scripts/test-screenshare.sh
    
    # Audio test script
    cat > ~/testing-scripts/test-audio.sh <<'AUDIO_EOF'
#!/bin/bash
# Audio Testing Script

echo "=== Audio System Test ==="
echo ""

echo "PipeWire status:"
systemctl --user status pipewire pipewire-pulse wireplumber --no-pager | grep "Active:"

echo ""
echo "Audio server info:"
pactl info

echo ""
echo "Available output devices:"
pactl list sinks short

echo ""
echo "Available input devices:"
pactl list sources short

echo ""
echo "Testing speaker output..."
echo "You should hear a test tone in 3 seconds..."
sleep 3
speaker-test -t wav -c 2 -l 1

echo ""
echo "=== Manual Audio Tests ==="
echo ""
echo "1. Test microphone in meeting app"
echo "2. Test audio output during PS5 streaming"
echo "3. Test audio in/out simultaneously (meeting while streaming)"
echo "4. Check for crackling or latency issues"
echo ""
echo "If you experience issues:"
echo "- Check pavucontrol for routing"
echo "- Verify sample rate matches (48kHz recommended)"
echo "- Restart PipeWire: systemctl --user restart pipewire wireplumber"
echo ""
AUDIO_EOF
    
    chmod +x ~/testing-scripts/test-audio.sh
    
    # Master test script
    cat > ~/testing-scripts/run-all-tests.sh <<'MASTER_EOF'
#!/bin/bash
# Master Testing Script - Run All Tests

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Arch + Hyprland Complete Testing Suite               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

run_test() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Press Enter to run this test (or Ctrl+C to skip)..."
    $2
    echo ""
    read -p "Test complete. Press Enter to continue..."
}

# Run all tests
run_test "Audio System Test" ~/testing-scripts/test-audio.sh
run_test "Screen Sharing Test" ~/testing-scripts/test-screenshare.sh
run_test "Chiaki PS5 Test" ~/testing-scripts/test-chiaki.sh
run_test "VPN Connection Test" ~/testing-scripts/test-vpn.sh

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      All Tests Complete!                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Test Summary Checklist:"
echo "□ Audio working (input and output)"
echo "□ Screen sharing functional in meetings"
echo "□ Chiaki connects to PS5 successfully"
echo "□ VPN connects to work network"
echo "□ Overall Hyprland stability"
echo ""
echo "If all tests passed, you're ready to migrate from Ubuntu!"
echo ""
MASTER_EOF
    
    chmod +x ~/testing-scripts/run-all-tests.sh
    
    log "Testing scripts created in ~/testing-scripts/"
}

###############################################################################
# SECTION 12: POST-INSTALL INSTRUCTIONS
###############################################################################

section_post_install() {
    log "=== SECTION 12: Post-Installation Instructions ==="
    
    cat > ~/POST_INSTALL_README.txt <<'README_EOF'
╔════════════════════════════════════════════════════════════════════════╗
║            Arch + Hyprland Setup Complete!                             ║
╚════════════════════════════════════════════════════════════════════════╝

NEXT STEPS:
-----------

1. REBOOT THE SYSTEM
   This is important to load all kernel modules and start services properly.
   
   $ sudo reboot

2. LOG INTO HYPRLAND
   At the login screen, select Hyprland as your session.

3. BASIC HYPRLAND USAGE
   - Super + Enter       = Open terminal (Kitty)
   - Super + D           = Application launcher (Wofi)
   - Super + Q           = Close window
   - Super + F           = Fullscreen
   - Super + [1-9]       = Switch workspace
   - Super + Shift + [1-9] = Move window to workspace
   - Super + G           = Toggle gaming workspace (for Chiaki)
   - Print Screen        = Screenshot (to clipboard)

4. RUN TESTS
   Open a terminal and run:
   
   $ cd ~/testing-scripts
   $ ./run-all-tests.sh
   
   This will guide you through testing:
   - Audio system (PipeWire)
   - Screen sharing (meetings)
   - Chiaki (PS5 Remote Play)
   - VPN connection (Cisco)

5. CHIAKI SETUP
   First time setup:
   - Connect PS5 controller (USB recommended for first setup)
   - Launch Chiaki: $ chiaki
   - Click "Add Console"
   - You'll need your PSN account ID
   - Follow on-screen registration process
   
   For best performance:
   - Use wired ethernet on both PC and PS5
   - Set resolution to 720p for lower latency
   - Enable gamemode before launching: $ gamemoderun chiaki

6. CISCO VPN SETUP
   Place your .deb file in home directory, then:
   
   $ cd ~/testing-scripts
   $ ./test-vpn.sh
   
   If conversion fails, try OpenConnect:
   $ sudo openconnect your-vpn-server.com

7. MEETING APP CONFIGURATION
   For Zoom/Teams/Slack:
   - Screen sharing should work automatically via xdg-desktop-portal
   - If issues occur, restart: $ systemctl --user restart xdg-desktop-portal
   - Camera/mic permissions: check pavucontrol ($ pavucontrol)

8. TROUBLESHOOTING

   Audio not working:
   $ systemctl --user restart pipewire wireplumber
   $ pavucontrol  # Check device selection
   
   Screen sharing not working:
   $ systemctl --user restart xdg-desktop-portal-hyprland
   Make sure xwaylandvideobridge is installed
   
   Chiaki laggy:
   - Check network: ping your PS5 IP
   - Lower resolution in Chiaki settings
   - Close other applications
   - Use: $ gamemoderun chiaki
   
   Hyprland crashes:
   - Check logs: $ journalctl --user -xe
   - Hyprland log: ~/.cache/hyprland/hyprland.log

9. CUSTOMIZATION
   
   Hyprland config: ~/.config/hypr/hyprland.conf
   Waybar config: ~/.config/waybar/
   Terminal: Edit ~/.config/kitty/kitty.conf
   
10. PERFORMANCE MONITORING
    
    System resources: $ btop
    GPU usage: $ nvtop  (or $ radeontop for AMD)
    Network: $ iftop
    Gaming overlay: Press Shift+F12 in games (MangoHud)

╔════════════════════════════════════════════════════════════════════════╗
║                         TESTING CHECKLIST                              ║
╚════════════════════════════════════════════════════════════════════════╝

Before deciding to migrate from Ubuntu, verify:

□ Audio works in meetings (mic + speakers)
□ Can share screen in Zoom/Teams/Slack
□ Chiaki connects to PS5 and streams smoothly
□ VPN connects to work network
□ Can access work resources over VPN
□ All frequently used apps work
□ System is stable over several days
□ No dealbreaker bugs or crashes

MIGRATION DECISION:
-------------------

If all tests pass ✓ → Safe to migrate from Ubuntu
If critical issues ✗ → Document issues, try fixes, or stay on Ubuntu

You can always dual-boot Arch alongside Ubuntu as a transition period.

╔════════════════════════════════════════════════════════════════════════╗
║                         USEFUL COMMANDS                                ║
╚════════════════════════════════════════════════════════════════════════╝

Update system:
$ sudo pacman -Syu

Install package:
$ sudo pacman -S package-name
$ yay -S aur-package-name

Search packages:
$ pacman -Ss search-term
$ yay -Ss search-term

Remove package:
$ sudo pacman -R package-name

Clean package cache:
$ sudo pacman -Sc

View logs:
$ journalctl --user -xe
$ journalctl -b  (boot logs)

Restart Hyprland:
Super + M (exit) then log back in

Happy testing! 🎮🖥️
README_EOF
    
    log "Post-install README created: ~/POST_INSTALL_README.txt"
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║         Arch Linux + Hyprland Setup Script                            ║"
    echo "║         For Gaming (Chiaki PS5) + Work (VPN + Meetings)               ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    warning "This script will install and configure:"
    echo "  - Hyprland window manager"
    echo "  - PipeWire audio system"
    echo "  - Chiaki (PS5 Remote Play)"
    echo "  - Meeting apps (Zoom, Teams, Slack, Discord)"
    echo "  - VPN tools (OpenConnect + debtap for Cisco)"
    echo "  - Screen sharing infrastructure"
    echo "  - Gaming optimizations"
    echo ""
    info "Installation will take approximately 15-30 minutes depending on internet speed"
    echo ""
    prompt_continue
    
    # Execute all sections
    section_base_update
    section_install_yay
    section_install_hyprland
    section_install_audio
    section_install_graphics
    section_install_networking
    section_install_chiaki
    section_install_meeting_apps
    section_configure_hyprland
    section_install_additional_tools
    section_create_test_scripts
    section_post_install
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║                    ✓ Installation Complete!                           ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    log "Setup completed successfully!"
    echo ""
    warning "IMPORTANT NEXT STEPS:"
    echo ""
    echo "1. Read the instructions: cat ~/POST_INSTALL_README.txt"
    echo "2. Reboot the system: sudo reboot"
    echo "3. Log into Hyprland session"
    echo "4. Run tests: cd ~/testing-scripts && ./run-all-tests.sh"
    echo ""
    info "Testing scripts location: ~/testing-scripts/"
    info "  - run-all-tests.sh    (Run all tests)"
    info "  - test-chiaki.sh      (Test PS5 Remote Play)"
    info "  - test-vpn.sh         (Test VPN connection)"
    info "  - test-screenshare.sh (Test meeting screen sharing)"
    info "  - test-audio.sh       (Test audio system)"
    echo ""
    
    read -p "Would you like to reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Rebooting system..."
        sudo reboot
    else
        info "Remember to reboot before testing!"
        info "When ready: sudo reboot"
    fi
}

# Run main function
main "$@"
