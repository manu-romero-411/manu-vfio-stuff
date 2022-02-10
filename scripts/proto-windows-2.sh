#!/bin/bash
## PROTOTIPO DE MÁQUINA VIRTUAL CON WINDOWS Y CON LA GRÁFICA INTEGRADA REDIRIGIDA
## FECHA: 9 de febrero de 2022

RAM="8192" # MiB
CPU="host"

OVMF=../i915ovmf-archivos ## CAMBIAR SEGÚN CONVENGA
PCILOC_IGPU=0000:00:02.0
PCILOC_AUDIO1=0000:00:1f.3
PCILOC_ISA=0000:00:1f.0
PCILOC_MEMCONT=0000:00:1f.2
PCILOC_SMBUS=0000:00:1f.4
PCILOC_NVIDIA=0000:01:00.0
PCILOC_AUDIO2=0000:01:00.1

args=(
	-enable-kvm -m "$RAM" -cpu "$CPU",kvm=off,hv_vendor_id=null
	-machine type=q35,accel=kvm,kernel_irqchip=on
	-smp $(nproc)
	-nographic -vga none
	-chardev stdio,id=char0,logfile=serial.log,signal=off
	-nodefaults 
	-rtc base=localtime,driftfix=slew
	-no-hpet
	-global kvm-pit.lost_tick_policy=discard
	-enable-kvm
	-netdev user,id=n0 -device rtl8139,netdev=n0
	-bios "$OVMF/OVMF_CODE.fd"
	-device vfio-pci,host=$PCILOC_IGPU,romfile="$OVMF/i915ovmf.rom"
	-device vfio-pci,host=$PCILOC_AUDIO1
	-device vfio-pci,host=$PCILOC_MEMCONT
	-device vfio-pci,host=$PCILOC_ISA
	-device vfio-pci,host=$PCILOC_SMBUS
	-device vfio-pci,host=$PCILOC_NVIDIA,romfile="$OVMF/nvidia.rom"
	-device vfio-pci,host=$PCILOC_AUDIO2
	-fw_cfg name=etc/igd-opregion,file="$OVMF/opregion.bin"
	-fw_cfg name=etc/igd-bdsm-size,file="$OVMF/bdsmSize.bin"
	-device qemu-xhci,p2=8,p3=8
	-device usb-kbd
	-device usb-tablet
	-usb
	-device usb-host,hostbus=1,hostaddr=5
	-device usb-host,hostbus=1,hostaddr=6
	-drive file=/pcgrande/Virtualizaciones/win10/win10.qcow2,format=qcow2,l2-cache-size=8M
	-object input-linux,id=kbd,evdev="/dev/input/by-path/platform-i8042-serio-0-event-kbd",grab_all=true
	-device virtio-input-host-pci,id=input1,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-event-mouse"
#	-device virtio-input-host-pci,id=mouse,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-mouse"
	-cdrom /home/manuel/Escritorio/ubuntu-20.04.3-desktop-amd64.iso
)

qemu-system-x86_64 "${args[@]}"
