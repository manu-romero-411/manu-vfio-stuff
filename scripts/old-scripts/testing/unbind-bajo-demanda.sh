#!/bin/bash
## SCRIPT PARA DESLIGAR LOS DISPOSITIVOS PCI RÁPIDAMENTE Y PONERLOS CON vfio-pci
## FUENTE: https://bbs.archlinux.org/viewtopic.php?pid=1756945#p1756945

modprobe vfio-pci

for dev in "$@"; do
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
                echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id
done
