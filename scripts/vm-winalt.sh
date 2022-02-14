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
source $ROOTDIR/listaUSB.sh

echo ${QEMU_USB_ARGS[@]}

if ! $ROOTDIR/usbUmount.sh $SILENTMODE; then
	mensaje "❌️ Al haber dispositivos USB que no pueden ser desmontados, no podemos seguir. F."
	exit 1
fi
source $ROOTDIR/archivos.sh
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
    -netdev bridge,br=virbr0,id=net0
    -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27
	-display gtk,gl=off
	-vga qxl
## BIOS Y ACPI Y TO ESO
	-drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
	-drive if=pflash,format=raw,file="$OVMF_VARS"
	-fw_cfg name=etc/igd-opregion,file="$OVMF_OPREG"
	-fw_cfg name=etc/igd-bdsm-size,file="$OVMF_BDSM"
	-acpitable file="$SSDT_BATERIAFALSA"
	-device qemu-xhci,p2=8,p3=8
	-device usb-kbd
	-device usb-tablet
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
