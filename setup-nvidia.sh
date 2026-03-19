#!/bin/bash
# NVIDIA power management udev rules
sudo tee /etc/udev/rules.d/80-nvidia-pm.rules > /dev/null << 'RULES'
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
RULES

echo "Created /etc/udev/rules.d/80-nvidia-pm.rules"

# Regenerate initramfs
sudo mkinitcpio -P

echo ""
echo "Done! Now reboot with: sudo reboot"
