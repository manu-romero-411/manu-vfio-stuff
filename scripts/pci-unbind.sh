#!/bin/bash
## CIERRA LA SESIÓN GRÁFICA DE USUARIO, EL LIGHTDM, Y COLOCA LA GRÁFICA INTEGRA-
## DA BAJO EL AMPARO DEL DRIVER vfio-pci
## FECHA: 9 de febrero de 2022

set -x
export PCILOC=0000:00:02.0
export PCIID="8086 5916"
#export DefaultGVTMODE=1

## CERRAR LO GRÁFICO (TODO: CERRAR SESIÓN DE CINNAMON/XFCE/GNOME DE FORMA CORRECTA, POR SI SE RAYA LUEGO)

service lightdm stop

## DECIRLE A vfio-pci QUE LOS DISPOSITIVOS TALES VAN ENTRAR EN GRUPOS IOMMU

echo $PCIID > /sys/bus/pci/drivers/vfio-pci/new_id | exit 1 # gráfica integrada (8086 5916)

## PASAR LOS DISPOSITIVOS (GRÁFICAS INTEL Y NVIDIA, SONIDO, TECLADO, RATÓN Y MANDO) AL DRIVER vfio-pci

### gráfica integrada (0000:00:02.0)
echo $PCILOC > /sys/bus/pci/drivers/i915/unbind | exit 1
echo $PCILOC > /sys/bus/pci/drivers/vfio-pci/bind | exit 1
