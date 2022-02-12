#!/bin/bash
## PROTOTIPO DE MÁQUINA VIRTUAL CON WINDOWS Y CON LA GRÁFICA INTEGRADA REDIRIGIDA
## FECHA: 9 de febrero de 2022

OVMF=../i915ovmf-archivos ## CAMBIAR SEGÚN CONVENGA
PCILOC_IGPU=0000:00:02.0
PCILOC_AUDIO1=0000:00:1f.3
PCILOC_ISA=0000:00:1f.0
PCILOC_MEMCONT=0000:00:1f.2
PCILOC_SMBUS=0000:00:1f.4
PCILOC_NVIDIA=0000:01:00.0
PCILOC_AUDIO2=0000:01:00.1

qemu-system-x86_64 \
-k en-us \
-name uefitest,debug-threads=on \
-nographic -vga none \
-chardev stdio,id=char0,logfile=serial.log,signal=off \
-serial chardev:char0 -m 2048 -M pc -cpu host \
-global PIIX4_PM.disable_s3=1 \
-global PIIX4_PM.disable_s4=1 \
-machine type=q35,accel=kvm,kernel_irqchip=on \
-nodefaults \
-rtc base=localtime,driftfix=slew \
-no-hpet \
-global kvm-pit.lost_tick_policy=discard \
-enable-kvm \
-netdev user,id=n0 -device rtl8139,netdev=n0 \
-bios "$OVMF/OVMF_CODE.fd" \
-device vfio-pci,host=$PCILOC_IGPU,romfile="$OVMF/i915ovmf.rom" \
-device vfio-pci,host=$PCILOC_AUDIO1 \
-device vfio-pci,host=$PCILOC_MEMCONT \
-device vfio-pci,host=$PCILOC_ISA \
-device vfio-pci,host=$PCILOC_SMBUS \
-fw_cfg name=etc/igd-opregion,file="$OVMF/opregion.bin" \
-fw_cfg name=etc/igd-bdsm-size,file="$OVMF/bdsmSize.bin" \
-device qemu-xhci,p2=8,p3=8 \
-device usb-kbd \
-device usb-tablet \
-usb \
-drive file=/pcgrande/Virtualizaciones/debianEstable/debian.qcow2,format=qcow2,l2-cache-size=8M \
-object input-linux,id=kbd,evdev="/dev/input/by-path/platform-i8042-serio-0-event-kbd",grab_all=true
