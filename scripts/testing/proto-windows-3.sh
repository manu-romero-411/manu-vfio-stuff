#!/bin/bash

# Set audio output options
export OVMF=../i915ovmf-archivos
# Use command below to generate a MAC address
# printf '52:54:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))

# Refer https://github.com/saveriomiroddi/qemu-pinning for how to set your cpu affinity properly
qemu-system-x86_64 \
  -name "Windows10-QEMU" \
  -machine type=q35,accel=kvm \
  -global ICH9-LPC.disable_s3=1 \
  -global ICH9-LPC.disable_s4=1 \
  -enable-kvm \
  -cpu host,kvm=off,hv_vapic,hv_relaxed,hv_spinlocks=0x1fff,hv_time,hv_vendor_id=12alphanum \
  -smp 4,sockets=1,cores=2,threads=2 \
  -m 8G \
  -rtc clock=host,base=localtime \
  -device ich9-intel-hda -device hda-output \
  -device qxl,bus=pcie.0,addr=1c.4,id=video.2 \
  -vga qxl \
  -nographic \
  -serial none \
  -parallel none \
  -k en-us \
  -spice port=5901,addr=127.0.0.1,disable-ticketing \
  -usb \
  -device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1 \
  -device vfio-pci,host=01:00.0,bus=root.1,addr=00.0,x-pci-vendor-id=0x10de,x-pci-device-id=0x1299,x-pci-sub-device-id=0x18d0,x-pci-sub-vendor-id=0x1043,multifunction=on,romfile="/home/manuel/Escritorio/vbios_10de_1299_1.rom" \
	-drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE_nv.fd" \
	-drive if=pflash,format=raw,file="$OVMF/OVMF_VARS.fd" \
  -boot menu=on \
  -boot order=c \
  -drive file=/pcgrande/Virtualizaciones/debianEstable/debian.qcow2,format=qcow2,l2-cache-size=8M \
  -device pci-bridge,addr=12.0,chassis_nr=2,id=head.2 \
  -device usb-tablet \
  -display gtk,gl=off \
  -acpitable file="$OVMF/SSDT1.dat"
  
# The -device usb-tablet will not be accurate regarding the pointer in some cases, another option is to use 
# -device virtio-keyboard-pci,bus=head.2,addr=03.0,display=video.2 \
# -device virtio-mouse-pci,bus=head.2,addr=04.0,display=video.2 \

