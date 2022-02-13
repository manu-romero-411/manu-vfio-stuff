#!/bin/bash
## PROTOTIPO DE MÁQUINA VIRTUAL CON WINDOWS Y CON LA GRÁFICA INTEGRADA REDIRIGIDA
## FECHA: 9 de febrero de 2022
#set -x
SILENTMODE=$1
RAM="8192" # MiB
CPU="host"
ROOTDIR="$(realpath $(dirname $0))"

OVMF=../i915ovmf-archivos ## CAMBIAR SEGÚN CONVENGA
PCILOC_IGPU=0000:00:02.0
PCILOC_AUDIO1=0000:00:1f.3
PCILOC_ISA=0000:00:1f.0
PCILOC_MEMCONT=0000:00:1f.2
PCILOC_SMBUS=0000:00:1f.4
PCILOC_NVIDIA=0000:01:00.0
PCILOC_AUDIO2=0000:01:00.1

function mensaje(){
	if [[ "$SILENTMODE" != "-s" ]]; then
		echo $@
	fi
}

mensaje "ℹ️ Escaneando dispositivos USB pasables a la máquina virtual"
source $OVMF/listaUSB.sh

echo ${QEMU_USB_ARGS[@]}

if ! $ROOTDIR/usbUmount.sh $SILENTMODE; then
	mensaje "❌️ Al haber dispositivos USB que no pueden ser desmontados, no podemos seguir. F."
	exit 1
fi

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
#	-netdev user,id=n0 -device rtl8139,netdev=n0
	-display gtk,gl=off -full-screen
	-vga qxl
	-drive if=pflash,format=raw,readonly=on,file="/usr/share/OVMF/OVMF_CODE.nv.fd"
	-drive if=pflash,format=raw,file="/var/lib/libvirt/qemu/nvram/win10_VARS.fd"
	#-device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x1
 	#-device vfio-pci,host=$PCILOC_NVIDIA,bus=pci.1,multifunction=on,addr=0x0,rombar=0,x-pci-vendor-id=0x10de,x-pci-device-id=0x1299,x-pci-sub-vendor-id=0x1043,x-pci-sub-device-id=0x18d0
	-acpitable file="/usr/share/qemu/ssdt1.dat"
	-fw_cfg name=etc/igd-opregion,file="$OVMF/opregion.bin"
	-fw_cfg name=etc/igd-bdsm-size,file="$OVMF/bdsmSize.bin"
	-device qemu-xhci,p2=8,p3=8
	-device usb-kbd
	-device usb-tablet
#	-drive file=/pcgrande/Virtualizaciones/win10/win10.qcow2,format=qcow2,l2-cache-size=8M
#	-object input-linux,id=kbd,evdev="/dev/input/by-path/platform-i8042-serio-0-event-kbd",grab_all=y
#	-device virtio-input-host-pci,id=input1,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-event-mouse"
#	-device virtio-input-host-pci,id=mouse,evdev="/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-mouse"
	-cdrom /home/manuel/Escritorio/ubuntu-20.04.3-desktop-amd64.iso
	-chardev socket,id=mon1,server=on,wait=off,path=$OVMF/qmp-sock
	-mon chardev=mon1,mode=control,pretty=on
	${QEMU_USB_ARGS[@]}
)

echo ${args[@]}

mensaje "ℹ️ Cerrando el escritorio y dando control de los dispositivos a vfio-pci..."

mensaje "ℹ️ Ejecutando QEMU/KVM..."

qemu-system-x86_64 "${args[@]}"
mensaje "ℹ️ Devolviendo dispositivos al PC y reiniciando el escritorio..."
