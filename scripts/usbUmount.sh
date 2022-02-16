#!/bin/bash
## DESMONTAR TODOS LOS DISPOSITIVOS DE ALMACENAMIENTO USB
## FUENTE (⛲️): https://stackoverflow.com/questions/19751624/how-to-unmount-all-usb-pen-drive-from-ubuntu-with-bash-script-or-terminal
## FECHA: 13 de febrero de 2022 

for usb_dev in /dev/disk/by-id/{wwn,usb}-*; do
    dev=$(readlink -f $usb_dev)
    if grep -qw ^$dev /proc/mounts; then
		if ! (grep -w ^$dev /proc/mounts | grep -qw "/pcgrande") && ! (grep -w ^$dev /proc/mounts | grep -qw "/"); then
			echo "ℹ️ Intentando desmontar $dev"
			umount $dev
			ERR=$?
			if [[ $ERR != 0 ]]; then
				echo "❌️ No se pudo desmontar $dev. No se puede seguir"
				exit 1
			else
				echo "✅️ Desmontado con éxito $dev"
			fi
		fi
	fi
done
exit 0
