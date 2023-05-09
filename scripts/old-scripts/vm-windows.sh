#!/bin/bash
## PROTOTIPO DE MÁQUINA VIRTUAL CON WINDOWS Y CON LA GRÁFICA INTEGRADA REDIRIGIDA
## FECHA: 9 de febrero de 2022

RAM="8192" # MiB
CPU="host"
ROOTDIR="$(realpath $(dirname $0))"

OVMF=/home/manuel/.libvirt ## CAMBIAR SEGÚN CONVENGA
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

mensaje "ℹ️  Escaneando dispositivos USB pasables a la máquina virtual"
#source $ROOTDIR/listaUSB.sh

#echo ${QEMU_USB_ARGS[@]}

#if ! $ROOTDIR/usbUmount.sh $SILENTMODE; then
#	mensaje "❌️ Al haber dispositivos USB que no pueden ser desmontados, no podemos seguir. F."
#	exit 1
#fi

source $ROOTDIR/archivos.sh
args=(

## COSAS BÁSICAS DE LA MÁQUINA VIRTUAL
	-m "$RAM"
	-cpu 'host,kvm=off,hv_vendor_id=null,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff'
	-machine type=q35,kernel_irqchip=on,accel=kvm
	-smp $(nproc)
	-nographic -vga none

## BIOS VIRTUAL
	-drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
	-drive if=pflash,format=raw,file="$OVMF_VARS"
	-fw_cfg name=etc/igd-opregion,file="$OVMF_OPREG"
	-fw_cfg name=etc/igd-bdsm-size,file="$OVMF_BDSM"
#	-acpitable file="$SSDT_BATERIAFALSA"

## DISPOSITIVOS PCI (PASSTHROUGH)
	#-device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x1
	-device vfio-pci,host=$PCILOC_IGPU,romfile="$INTEL_GVTD_BIOS"

## ALMACENAMIENTO Y ARCHIVOS ISO
	-drive file=/pcgrande/Sistemos/qcow-pool/manuvfio-macos-opencore.qcow2,format=qcow2,l2-cache-size=8M

## PERIFÉRICOS
	-object input-linux,id=kbd,evdev="/dev/input/by-path/platform-i8042-serio-0-event-kbd",grab_all=y
#	-chardev socket,id=mon1,server=on,wait=off,path=$HOTPLUG_QMPSOCK
#	-mon chardev=mon1,mode=control,pretty=on
#	${QEMU_USB_ARGS[@]}

## RED
#    -netdev bridge,br=virbr0,id=net0
 #   -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27
)

mensaje "ℹ️  Cerrando el escritorio y dando control de los dispositivos a vfio-pci..."

mensaje "ℹ️  Ejecutando QEMU/KVM..."
qemu-system-x86_64 "${args[@]}"
#$VMROOT/pci-rebind.sh
mensaje "ℹ️  Devolviendo dispositivos al PC y reiniciando el escritorio..."
