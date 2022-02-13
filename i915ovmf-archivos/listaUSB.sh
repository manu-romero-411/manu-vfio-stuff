#!/bin/bash
## SI QUIERO PONER UN DISPOSITIVO NUEVO, SOLO EJECUTO lsusb, MIRO LOS
## DISPOSITIVOS QUE HAY, Y ANOTO AQUÍ LOS IDS DE LOS DISPOSITIVOS QUE SE PASEN
## DIRECTOS A LAS MÁQUINAS VIRTUALES CUANDO LAS ARRANQUE. UNA CHAPUZA QUE FUNCA

LISTA_USB=(
	"258a:002a" # Teclado mecánico Stinger
	"046d:c077" # Ratón Logitech
	"248a:8366" # Ratón VictSing
	"0e6f:02a8" # Mando Xbox PDP
	"174c:55aa" # Carcasa de HDD negra
	"152d:0578" # Conector SATA a USB2
	"0930:6544" # ManuArreglo (Pendrive Toshiba)
	"0951:1666" # ManuArreglo macOS (Pendrive Kingston Zamo)
	"125f:c82a" # Pendrive Adata
	"13fe:6300" # Pendrive Magix
)


## NO TOCAR MUCHO ESTO DE AQUÍ ABAJO



QEMU_USB_ARGS=(
	-device nec-usb-xhci,id=xhci0
	-device nec-usb-xhci,id=xhci1
)

## VAMOS A ASIGNAR A CADA DISPOSITIVO EXISTENTE UN BUS DISTINTO Y DEPENDIENTE DE EN QUÉ PUERTO DEL pcgrande ESTÁ

EHCI_ID=0
EHCI_NUM=0
XHCI_ID=0
XHCI_NUM=0

for i in ${LISTA_USB[@]}; do
	if lsusb | grep $i &> /dev/null; then
		BUS=$(lsusb | grep $i | cut -c 5-7 | sed 's/^0*//')
		ID=$(lsusb | grep $i | cut -c 16-18 | sed 's/^0*//')
		USBPORT=$(grep $(echo $i | cut -d: -f1) /sys/bus/usb/devices/*/idVendor | cut -c 22- | cut -d/ -f1 | cut -d. -f1)
		if [[ $USBPORT == 1-3 ]] || [[ $USBPORT == 1-2 ]]; then
			VIRTUALBUS="xhci$XHCI_ID.0"
			XHCI_NUM=$(($XHCI_NUM + 1))
			if [ $XHCI_NUM -eq 3 ]; then
				XHCI_NUM=0
				XHCI_ID=$(($XHCI_ID + 1))
			fi
			NEW_USB="-device usb-host,hostbus=$BUS,hostaddr=$ID,bus=$VIRTUALBUS"
			#echo $NEW_USB
			QEMU_USB_ARGS+=($NEW_USB)
			NOPE=0
		fi
	fi
done
#echo ${QEMU_USB_ARGS[@]}
