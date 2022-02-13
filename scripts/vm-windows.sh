#!/bin/bash
## PROTOTIPO DE MÁQUINA VIRTUAL CON WINDOWS Y CON LA GRÁFICA INTEGRADA REDIRIGIDA
## FECHA: 9 de febrero de 2022

RAM="8192" # MiB
CPU="host"
VMROOT="$(realpath $(dirname $0))"

OVMF=../i915ovmf-archivos ## CAMBIAR SEGÚN CONVENGA
PCILOC_IGPU=0000:00:02.0
PCILOC_AUDIO1=0000:00:1f.3
PCILOC_ISA=0000:00:1f.0
PCILOC_MEMCONT=0000:00:1f.2
PCILOC_SMBUS=0000:00:1f.4
PCILOC_NVIDIA=0000:01:00.0
PCILOC_AUDIO2=0000:01:00.1

PCIID_TECLADOUSB="046d:c077"
PCIID_RATONUSB="258a:002a"

if lsusb | grep $PCIID_TECLADOUSB; then
	BUS=$(lsusb | grep $PCIID_TECLADOUSB | cut -c 5-7 | sed 's/^0*//')
	ID=$(lsusb | grep $PCIID_TECLADOUSB | cut -c 16-18 | sed 's/^0*//')
	TECLADOSTRING="-device usb-host,hostbus=$BUS,hostaddr=$ID"
fi

if lsusb | grep $PCIID_RATONUSB; then
	BUS=$(lsusb | grep $PCIID_RATONUSB | cut -c 5-7 | sed 's/^0*//')
	ID=$(lsusb | grep $PCIID_RATONUSB | cut -c 16-18 | sed 's/^0*//')
	RATONSTRING="-device usb-host,hostbus=$BUS,hostaddr=$ID"
fi

echo $TECLADOSTRING
echo $RATONSTRING

args=(
	-m "$RAM"
	-cpu 'host,kvm=off,hv_vendor_id=null'
	-machine type=q35,kernel_irqchip=on,accel=kvm
	-smp $(nproc)
	-nographic -vga none
	-chardev stdio,id=char0,logfile=serial.log,signal=off
	-nodefaults
	-rtc base=localtime,driftfix=slew
	-no-hpet
	#-global kvm-pit.lost_tick_policy=discard
	#-enable-kvm
#	-netdev user,id=n0 -device rtl8139,netdev=n0
	-drive if=pflash,format=raw,readonly=on,file="/usr/share/OVMF/OVMF_CODE.nv.fd"
	-drive if=pflash,format=raw,file="/var/lib/libvirt/qemu/nvram/win10_VARS.fd"
	-device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x1
 	-device vfio-pci,host=$PCILOC_NVIDIA,bus=pci.1,multifunction=on,addr=0x0,rombar=0,x-pci-vendor-id=0x10de,x-pci-device-id=0x1299,x-pci-sub-vendor-id=0x1043,x-pci-sub-device-id=0x18d0
	-device vfio-pci,host=$PCILOC_IGPU,romfile="$OVMF/i915ovmf.rom"
	-fw_cfg name=etc/igd-opregion,file="$OVMF/opregion.bin"
	-fw_cfg name=etc/igd-bdsm-size,file="$OVMF/bdsmSize.bin"
	-device vfio-pci,host=$PCILOC_AUDIO1
	-device vfio-pci,host=$PCILOC_MEMCONT
	-device vfio-pci,host=$PCILOC_ISA
	-device vfio-pci,host=$PCILOC_SMBUS
	-device qemu-xhci,p2=8,p3=8
	-device usb-kbd
	-device usb-tablet
	-usb
	$TECLADOSTRING
	$RATONSTRING
	-drive file=/pcgrande/Virtualizaciones/win10/win10.qcow2,format=qcow2,l2-cache-size=8M
	-object input-linux,id=kbd,evdev="/dev/input/by-path/platform-i8042-serio-0-event-kbd",grab_all=y
	-device virtio-input-host-pci,id=input1,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-event-mouse"
#	-device virtio-input-host-pci,id=mouse,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-mouse"
	-cdrom /home/manuel/Escritorio/ubuntu-20.04.3-desktop-amd64.iso
	-acpitable file="/usr/share/qemu/ssdt1.dat"
)

#$VMROOT/pci-unbind.sh
/usr/bin/qemu-system-x86_64 "${args[@]}"
#$VMROOT/pci-rebind.sh
