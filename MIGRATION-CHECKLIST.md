# Ubuntu to Arch Migration Checklist

## Complete Pre-Migration, Migration, and Post-Migration Guide

---

## Phase 0: Pre-Testing (Before VM)

### Gather Information About Your System

- [ ] List all applications you use daily
  ```bash
  # On Ubuntu, list installed packages
  dpkg --get-selections | grep -v deinstall > ~/ubuntu-packages.txt
  ```

- [ ] Document your current setup
  - Monitor configuration (resolution, arrangement)
  - Keyboard layout and shortcuts
  - Mouse/touchpad settings
  - Network printers
  - Mounted drives/NAS

- [ ] Export browser data
  - Bookmarks
  - Passwords (or use password manager)
  - Extensions list

- [ ] Note down work-critical tools
  - VPN software (Cisco Secure Client)
  - Company-specific apps
  - Meeting software (Zoom, Teams, Slack)
  - Development tools (Stata, R, Python environments)

- [ ] Check hardware compatibility
  ```bash
  lspci > ~/hardware-list.txt
  lsusb >> ~/hardware-list.txt
  ```

---

## Phase 1: VM Testing (Days 1-5)

### Day 1: VM Setup & Installation

- [ ] Download Arch ISO
- [ ] Create VM (8GB RAM, 40GB disk)
- [ ] Install Arch using archinstall
- [ ] Run setup script
- [ ] First boot into Hyprland
- [ ] Read all documentation
  - [ ] POST_INSTALL_README.txt
  - [ ] VM-TESTING-GUIDE.md
  - [ ] QUICK-REFERENCE.md

### Day 2: Core Functionality Testing

- [ ] Audio system
  - [ ] Speakers work
  - [ ] Microphone works
  - [ ] No crackling or distortion
  - [ ] Volume controls work

- [ ] Screen sharing
  - [ ] Portal picker appears
  - [ ] Can share full screen
  - [ ] Can share specific window
  - [ ] Smooth framerate

- [ ] Chiaki (PS5)
  - [ ] Can register PS5
  - [ ] Can connect and stream
  - [ ] Audio/video in sync
  - [ ] Controller works
  - [ ] Acceptable latency

- [ ] VPN
  - [ ] .deb converts successfully
  - [ ] Can install package
  - [ ] Can connect to work VPN
  - [ ] Can access work resources

### Day 3: Workflow Testing

- [ ] Morning routine
  - [ ] Check email (if using email client)
  - [ ] Join morning meeting
  - [ ] Screen share presentation

- [ ] Work tasks
  - [ ] Code/script editing
  - [ ] Data analysis (Stata, R, Python)
  - [ ] Document writing
  - [ ] File management

- [ ] Communication
  - [ ] Slack/Teams messages
  - [ ] Video calls
  - [ ] Share files

- [ ] Gaming/Break
  - [ ] Chiaki streaming session
  - [ ] Controller responsiveness
  - [ ] Game performance

### Day 4: Stress Testing

- [ ] Heavy multitasking
  - [ ] 10+ browser tabs
  - [ ] Multiple applications
  - [ ] Meeting + work simultaneously

- [ ] Long session
  - [ ] 8+ hours uptime
  - [ ] No memory leaks
  - [ ] No crashes

- [ ] Edge cases
  - [ ] Reconnect VPN mid-session
  - [ ] Switch networks
  - [ ] Plug/unplug USB devices

### Day 5: Decision Day

- [ ] Review all test results
- [ ] Document any blockers
- [ ] List remaining concerns
- [ ] Make migration decision
  - [ ] **GO**: Migrate to Arch
  - [ ] **NO-GO**: Stay on Ubuntu
  - [ ] **MAYBE**: Dual boot first

---

## Phase 2: Pre-Migration Backup (If GO Decision)

### Critical Data Backup

- [ ] Create backup directory
  ```bash
  mkdir ~/pre-migration-backup
  ```

- [ ] Backup home directory
  ```bash
  # Full home backup (may be large)
  tar czf ~/pre-migration-backup/home-backup.tar.gz ~/ \
    --exclude=~/.cache \
    --exclude=~/.local/share/Trash \
    --exclude=~/Downloads
  
  # Or selective backup
  tar czf ~/pre-migration-backup/important-files.tar.gz \
    ~/Documents \
    ~/Projects \
    ~/Pictures \
    ~/Music \
    ~/.ssh \
    ~/.gnupg
  ```

- [ ] Export configuration files
  ```bash
  mkdir ~/pre-migration-backup/configs
  cp -r ~/.bashrc ~/pre-migration-backup/configs/
  cp -r ~/.bash_profile ~/pre-migration-backup/configs/
  cp -r ~/.profile ~/pre-migration-backup/configs/
  cp -r ~/.gitconfig ~/pre-migration-backup/configs/
  cp -r ~/.config/nvim ~/pre-migration-backup/configs/ 2>/dev/null || true
  cp -r ~/.config/Code ~/pre-migration-backup/configs/ 2>/dev/null || true
  ```

- [ ] Export SSH keys
  ```bash
  cp -r ~/.ssh ~/pre-migration-backup/ssh-backup
  chmod 600 ~/pre-migration-backup/ssh-backup/*
  ```

- [ ] Export GPG keys (if used)
  ```bash
  gpg --export-secret-keys > ~/pre-migration-backup/gpg-private.asc
  gpg --export > ~/pre-migration-backup/gpg-public.asc
  ```

- [ ] Document installed software
  ```bash
  dpkg --get-selections > ~/pre-migration-backup/ubuntu-packages.txt
  snap list > ~/pre-migration-backup/snap-packages.txt 2>/dev/null || true
  flatpak list > ~/pre-migration-backup/flatpak-packages.txt 2>/dev/null || true
  ```

- [ ] Export browser data
  - [ ] Bookmarks (export to HTML)
  - [ ] Passwords (if using browser)
  - [ ] Extensions list (screenshot or write down)

- [ ] Copy backup to external drive or cloud
  ```bash
  # To external drive
  cp -r ~/pre-migration-backup /media/your-external-drive/
  
  # Or to cloud
  rclone copy ~/pre-migration-backup remote:backup/
  # Or use your cloud provider's tool
  ```

- [ ] Verify backup integrity
  ```bash
  # Check archive
  tar tzf ~/pre-migration-backup/home-backup.tar.gz | head -20
  
  # Verify files
  ls -lh ~/pre-migration-backup/
  ```

### Document Current System

- [ ] Screenshot your desktop setup
- [ ] Write down keyboard shortcuts you use
- [ ] List browser extensions
- [ ] Document network shares/mounts
- [ ] Note any custom scripts or automations

### Application-Specific Backups

- [ ] **Development environments**
  - [ ] Python virtual environments (requirements.txt)
    ```bash
    pip freeze > ~/pre-migration-backup/python-packages.txt
    ```
  - [ ] Node.js global packages
    ```bash
    npm list -g --depth=0 > ~/pre-migration-backup/npm-global.txt
    ```
  - [ ] R packages
    ```R
    # In R
    installed.packages()[, c("Package", "Version")] |> 
      write.csv("~/pre-migration-backup/r-packages.csv")
    ```

- [ ] **Stata** (if you use it)
  - [ ] Backup .do files
  - [ ] Backup datasets (.dta files)
  - [ ] Document installed user-written commands
  - [ ] Backup Stata settings/preferences

- [ ] **Database data**
  - [ ] Export databases if local
  - [ ] Document connection strings

- [ ] **Email** (if using local client)
  - [ ] Export mailbox
  - [ ] Save account settings

- [ ] **Password Manager**
  - [ ] Export vault (if not cloud-synced)
  - [ ] Verify you can access from phone

---

## Phase 3A: Full Migration Path

### Preparation

- [ ] Create Arch bootable USB
  ```bash
  # On Ubuntu
  sudo dd if=archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress
  sudo sync
  ```

- [ ] Verify USB boots correctly
- [ ] Have VM config available for reference
- [ ] Print or save offline:
  - [ ] VM-TESTING-GUIDE.md
  - [ ] QUICK-REFERENCE.md
  - [ ] Installation notes

### Installation Day

- [ ] Boot from USB
- [ ] Install Arch (use archinstall or manual)
- [ ] Configure same username as Ubuntu
- [ ] Transfer setup script (via USB or download)
- [ ] Run setup script
- [ ] Reboot into Hyprland

### Post-Installation

- [ ] Restore personal files
  ```bash
  # From external drive
  cp -r /media/backup/Documents ~/
  cp -r /media/backup/Projects ~/
  
  # Or extract from archive
  tar xzf /media/backup/home-backup.tar.gz -C ~/
  ```

- [ ] Restore SSH keys
  ```bash
  cp -r /media/backup/ssh-backup ~/.ssh
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/*.pub
  ```

- [ ] Restore GPG keys
  ```bash
  gpg --import /media/backup/gpg-private.asc
  gpg --import /media/backup/gpg-public.asc
  ```

- [ ] Restore configs
  ```bash
  cp /media/backup/configs/.bashrc ~/
  cp /media/backup/configs/.gitconfig ~/
  source ~/.bashrc
  ```

- [ ] Install additional software
  ```bash
  # Reference your Ubuntu package list
  # Install Arch equivalents
  sudo pacman -S ...
  yay -S ...
  ```

- [ ] Set up VPN
- [ ] Configure Chiaki
- [ ] Join test meeting

### First Week Verification

- [ ] Day 1: Basic functionality
- [ ] Day 2: Full work day
- [ ] Day 3: Gaming session
- [ ] Day 4: Heavy multitasking
- [ ] Day 5: Weekend use
- [ ] Day 7: Decision to keep or rollback

---

## Phase 3B: Dual Boot Migration Path

### Preparation

- [ ] Backup (same as Phase 2)
- [ ] Boot into Ubuntu
- [ ] Open GParted
- [ ] Shrink Ubuntu partition
  - Recommended: Leave 40GB+ free for Arch
  - Keep Ubuntu at least 30GB

### Installation

- [ ] Boot from Arch USB
- [ ] During installation:
  - [ ] Use manual partitioning
  - [ ] Install to free space (not Ubuntu partition!)
  - [ ] Install GRUB bootloader
- [ ] Complete Arch setup

### Configure Dual Boot

- [ ] Verify GRUB shows both systems
- [ ] Set default OS
  ```bash
  # On Arch
  sudo vim /etc/default/grub
  # Set: GRUB_DEFAULT=0  (for Arch)
  # or   GRUB_DEFAULT=1  (for Ubuntu)
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  ```

- [ ] Test booting both systems

### Transition Period (1 Month)

**Week 1-2: Primary Arch**
- [ ] Use Arch for all work
- [ ] Boot Ubuntu only if blocked
- [ ] Document any issues

**Week 3-4: Arch Only**
- [ ] Try not booting Ubuntu at all
- [ ] Verify everything works in Arch

**End of Month: Decision**
- [ ] If confident: Remove Ubuntu, reclaim space
- [ ] If uncertain: Keep dual boot longer

### Remove Ubuntu (When Ready)

- [ ] Boot into Arch
- [ ] Use GParted to:
  - [ ] Delete Ubuntu partition
  - [ ] Extend Arch partition
  - [ ] Apply changes
- [ ] Update GRUB
  ```bash
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  ```

---

## Phase 4: Post-Migration Setup

### Essential Applications

- [ ] **Development Tools**
  - [ ] Python, pip, pipx
    ```bash
    sudo pacman -S python python-pip python-pipx
    ```
  - [ ] R and RStudio
    ```bash
    sudo pacman -S r
    yay -S rstudio-desktop
    ```
  - [ ] Stata (if available for Arch, or wine)
  - [ ] Git
    ```bash
    sudo pacman -S git
    git config --global user.name "Your Name"
    git config --global user.email "your@email.com"
    ```
  - [ ] Code editor (VS Code, Neovim)
    ```bash
    yay -S visual-studio-code-bin
    sudo pacman -S neovim
    ```

- [ ] **Office/Productivity**
  - [ ] LibreOffice
    ```bash
    sudo pacman -S libreoffice-fresh
    ```
  - [ ] PDF reader
    ```bash
    sudo pacman -S zathura zathura-pdf-mupdf
    ```
  - [ ] LaTeX (if you use it)
    ```bash
    sudo pacman -S texlive-most
    ```

- [ ] **Browsers**
  - [ ] Firefox
    ```bash
    sudo pacman -S firefox
    ```
  - [ ] Chrome/Chromium
    ```bash
    yay -S google-chrome
    # or
    sudo pacman -S chromium
    ```

- [ ] **Communication** (if not installed by script)
  - [ ] Zoom, Slack, Discord, Teams

- [ ] **Media**
  - [ ] VLC
    ```bash
    sudo pacman -S vlc
    ```
  - [ ] Image viewer
    ```bash
    sudo pacman -S imv
    ```
  - [ ] Music player
    ```bash
    sudo pacman -S spotify-launcher
    ```

### Configure Services

- [ ] **Printer Setup**
  ```bash
  sudo pacman -S cups system-config-printer
  sudo systemctl enable --now cups
  ```

- [ ] **Bluetooth** (if not done)
  ```bash
  sudo pacman -S bluez bluez-utils
  sudo systemctl enable --now bluetooth
  ```

- [ ] **Firewall**
  ```bash
  sudo pacman -S ufw
  sudo ufw enable
  sudo systemctl enable ufw
  ```

- [ ] **Time Synchronization**
  ```bash
  sudo systemctl enable --now systemd-timesyncd
  ```

### Restore Workflows

- [ ] **SSH Connections**
  - [ ] Test SSH to servers
  - [ ] Verify SSH keys work
  - [ ] Update known_hosts if needed

- [ ] **Cloud Storage**
  - [ ] Install Dropbox/Drive/OneDrive
  - [ ] Set up sync folders

- [ ] **Development Environments**
  - [ ] Recreate Python venvs
    ```bash
    python -m venv ~/venvs/myproject
    source ~/venvs/myproject/bin/activate
    pip install -r requirements.txt
    ```
  - [ ] Install Node.js global packages
    ```bash
    # From backup list
    npm install -g package1 package2 ...
    ```
  - [ ] Reinstall R packages
    ```R
    # In R
    packages <- read.csv("~/pre-migration-backup/r-packages.csv")
    install.packages(packages$Package)
    ```

- [ ] **Project Repositories**
  - [ ] Clone active projects
  - [ ] Verify they build/run
  - [ ] Update dependencies if needed

### Fine-Tuning

- [ ] **Keyboard Layout**
  - Already configured in Hyprland config (us,hu)
  - Verify Alt+Shift switches correctly

- [ ] **Monitor Setup**
  - [ ] Configure resolution/refresh rate
  - [ ] Set up multiple monitors if applicable
  - [ ] Save configuration

- [ ] **Trackpad/Mouse**
  - Edit `~/.config/hypr/hyprland.conf`:
  ```bash
  input {
      touchpad {
          natural_scroll = yes
          tap-to-click = yes
          scroll_factor = 1.0
      }
      
      sensitivity = 0.0  # Adjust as needed
      accel_profile = flat  # Or "adaptive"
  }
  ```

- [ ] **Startup Applications**
  - Add to `~/.config/hypr/hyprland.conf`:
  ```bash
  exec-once = your-app
  ```

### Customization

- [ ] **Terminal Customization**
  - [ ] Configure kitty (font, colors)
  - [ ] Set up shell (zsh, fish, or bash)
  - [ ] Install shell plugins (oh-my-zsh, starship, etc.)

- [ ] **Waybar Customization**
  - [ ] Edit `~/.config/waybar/config`
  - [ ] Customize modules
  - [ ] Style with CSS

- [ ] **GTK Theme**
  ```bash
  sudo pacman -S lxappearance
  lxappearance  # GUI to set themes
  
  # Or install themes
  yay -S arc-gtk-theme papirus-icon-theme
  ```

- [ ] **Wallpaper**
  ```bash
  sudo pacman -S swaybg
  # Add to hyprland.conf:
  exec-once = swaybg -i ~/Pictures/wallpaper.jpg
  ```

---

## Phase 5: Optimization & Maintenance

### Performance Tuning

- [ ] **Enable Services**
  - [ ] Gamemode (already done by script)
  - [ ] Thermald (laptop thermal management)
    ```bash
    sudo pacman -S thermald
    sudo systemctl enable --now thermald
    ```
  - [ ] TLP (laptop power management)
    ```bash
    sudo pacman -S tlp
    sudo systemctl enable --now tlp
    ```

- [ ] **Gaming Optimizations**
  - [ ] Install Proton (for Steam)
  - [ ] Configure gamemode rules
  - [ ] Set up MangoHud for FPS overlay

- [ ] **CPU Governor** (laptops)
  ```bash
  # Check current
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  
  # Set to performance (when plugged in)
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  ```

### Backup Strategy

- [ ] **System Snapshots**
  - If using Btrfs:
    ```bash
    yay -S snapper snap-pac
    sudo snapper -c root create-config /
    ```
  
  - If using ext4:
    ```bash
    yay -S timeshift
    sudo timeshift --create --comments "Post-migration"
    ```

- [ ] **Automated Home Backup**
  - Set up rsync or borg backups
  - Schedule with systemd timers or cron

- [ ] **Config Backup**
  - Script to backup dotfiles
  ```bash
  #!/bin/bash
  tar czf ~/Backups/dotfiles-$(date +%Y%m%d).tar.gz \
    ~/.config/hypr \
    ~/.config/waybar \
    ~/.config/kitty \
    ~/.bashrc \
    ~/.gitconfig
  ```

### Maintenance Schedule

**Daily**
- [ ] Check system logs for errors
  ```bash
  journalctl -p 3 -xb  # Errors from current boot
  ```

**Weekly**
- [ ] Update system
  ```bash
  sudo pacman -Syu
  yay -Syu
  ```
- [ ] Clean package cache
  ```bash
  sudo pacman -Sc
  ```
- [ ] Check disk space
  ```bash
  df -h
  ```

**Monthly**
- [ ] Review installed packages
  ```bash
  pacman -Qe  # Explicitly installed
  pacman -Qm  # AUR packages
  ```
- [ ] Remove orphaned packages
  ```bash
  sudo pacman -Rns $(pacman -Qtdq)
  ```
- [ ] Check for broken symlinks
  ```bash
  find ~ -xtype l
  ```
- [ ] Test backups
- [ ] Update documentation

---

## Rollback Plan (Emergency)

If something goes catastrophically wrong:

### Dual Boot Rollback
- [ ] Reboot
- [ ] Select Ubuntu from GRUB
- [ ] Continue using Ubuntu
- [ ] Debug Arch issue later

### Full Migration Rollback

**If you have backup:**
- [ ] Boot from Ubuntu live USB
- [ ] Reinstall Ubuntu
- [ ] Restore from backup
- [ ] Document what went wrong

**If Arch is broken but bootable:**
- [ ] Boot into Arch
- [ ] Check logs: `journalctl -xe`
- [ ] Try to fix issue
- [ ] Ask for help on forums

**If Arch won't boot:**
- [ ] Boot from Arch live USB
- [ ] Mount partitions
- [ ] Chroot into system
- [ ] Fix issue or restore bootloader

---

## Success Criteria

You've successfully migrated when:

- [ ] ✅ All work tools function correctly
- [ ] ✅ VPN connects and is stable
- [ ] ✅ Meetings work (screen share, audio)
- [ ] ✅ Chiaki streams smoothly
- [ ] ✅ No productivity loss
- [ ] ✅ System is stable for 2+ weeks
- [ ] ✅ You're comfortable with Arch maintenance
- [ ] ✅ No urge to go back to Ubuntu

---

## Final Notes

### When to Abandon Migration

Consider staying on Ubuntu if:
- Critical work tools don't work on Arch
- VPN is completely broken
- You can't fix recurring issues
- Migration is too time-consuming
- Ubuntu works perfectly for your needs

**There's no shame in staying on Ubuntu.** It's a great distro.

### When Migration is Worth It

You'll know migration was right if:
- Better performance
- More stability
- More control and customization
- Learning experience
- Fun to use
- Hyprland workflow boost

---

**Good luck with your migration! 🚀**

Remember: Take your time, test thoroughly, and don't rush. The VM testing phase is crucial.
