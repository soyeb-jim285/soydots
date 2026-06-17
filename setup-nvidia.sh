#!/usr/bin/env bash
# NVIDIA driver setup for Arch hybrid AMD/NVIDIA laptops.
set -euo pipefail

packages=(
    linux-headers
    dkms
    nvidia-open-dkms
    nvidia-utils
    nvidia-settings
    nvidia-prime
    libva-nvidia-driver
)

has_nvidia_open=0
while IFS= read -r pkg; do
    if [[ "$pkg" == "nvidia-open" ]]; then
        has_nvidia_open=1
        break
    fi
done < <(pacman -Qq)

if (( has_nvidia_open )); then
    echo "Replacing kernel-versioned nvidia-open with nvidia-open-dkms"
    sudo pacman -Rns --noconfirm nvidia-open
fi

echo "Installing NVIDIA DKMS driver stack"
sudo pacman -S --needed --noconfirm "${packages[@]}"

sudo install -dm755 /etc/modprobe.d /etc/modules-load.d /etc/udev/rules.d /etc/pacman.d/hooks

sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'CONF'
options nvidia NVreg_DynamicPowerManagement=0x02 NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
options nvidia_drm modeset=1 fbdev=1
CONF

# Suspend/resume/hibernate services required for VRAM save-restore
# with NVreg_PreserveVideoMemoryAllocations=1
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service

sudo tee /etc/modules-load.d/nvidia.conf >/dev/null <<'CONF'
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
CONF

sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null <<'RULES'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="d3cold_allowed", ATTR{d3cold_allowed}="0"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="d3cold_allowed", ATTR{d3cold_allowed}="0"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
RULES

sudo tee /etc/pacman.d/hooks/nvidia-dkms-initramfs.hook >/dev/null <<'HOOK'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-open-dkms
Target=nvidia-utils

[Action]
Description=Rebuilding initramfs after NVIDIA driver transaction
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
HOOK

# Inject nvidia modules into MODULES=() if missing. Idempotent.
# Uses sed in-place with .bak so /etc/mkinitcpio.conf can't end up empty.
if ! grep -qE '^MODULES=\([^)]*\bnvidia\b' /etc/mkinitcpio.conf; then
    if ! grep -qE '^MODULES=\(' /etc/mkinitcpio.conf; then
        echo "ERROR: /etc/mkinitcpio.conf missing MODULES=() line — aborting" >&2
        exit 1
    fi
    sudo sed -i.bak -E 's/^MODULES=\(([^)]*)\)/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    # collapse leading whitespace inside parens for tidiness
    sudo sed -i -E 's/^MODULES=\( +/MODULES=(/' /etc/mkinitcpio.conf
fi

sudo udevadm control --reload-rules

echo "Regenerating initramfs"
sudo mkinitcpio -P

echo "Loading NVIDIA modules for this boot"
if sudo modprobe nvidia; then
    sudo modprobe nvidia_modeset
    sudo modprobe nvidia_uvm
    sudo modprobe nvidia_drm
else
    echo "NVIDIA could not be loaded in the current boot."
    echo "The GPU is probably already stuck in D3cold; reboot so the new early module and udev config applies."
fi

echo ""
echo "NVIDIA setup complete. Validate with: nvidia-smi"
echo "If nvidia-smi still fails before reboot, reboot once with: sudo reboot"
