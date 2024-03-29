#!/bin/bash
## CIERRA LA SESIÓN GRÁFICA DE USUARIO, EL LIGHTDM, Y COLOCA LA GRÁFICA INTEGRA-
## DA BAJO EL AMPARO DEL DRIVER vfio-pci
## FECHA: 9 de febrero de 2022

set -x
## PCILOCs
export IGPU_PCILOC=0000:00:02.0
export AUDIO1_PCILOC=0000:00:1f.3
export PUENTEISA_PCILOC=0000:00:1f.0
export MEMCONT_PCILOC=0000:00:1f.2
export SMBUS_PCILOC=0000:00:1f.4
export NVIDIA_PCILOC=0000:01:00.0
export AUDIO2_PCILOC=0000:01:00.1

## PCIIDs
export IGPU_PCIID="8086 5916"
export AUDIO1_PCIID="8086 9d71"
export PUENTEISA_PCIID="8086 9d58"
export MEMCONT_PCIID="8086 9d21"
export SMBUS_PCIID="8086 9d23"
export NVIDIA_PCIID="10de 1299"
export AUDIO2_PCIID="10de 0e0f"

#export DefaultGVTMODE=1

## CERRAR LO GRÁFICO (TODO: CERRAR SESIÓN DE CINNAMON/XFCE/GNOME DE FORMA CORRECTA, POR SI SE RAYA LUEGO)

#service lightdm stop

## DECIRLE A vfio-pci QUE LOS DISPOSITIVOS TALES VAN ENTRAR EN GRUPOS IOMMU

echo $NVIDIA_PCIID > /sys/bus/pci/drivers/vfio-pci/new_id
echo $AUDIO2_PCIID > /sys/bus/pci/drivers/vfio-pci/new_id

## PASAR LOS DISPOSITIVOS (GRÁFICAS INTEL Y NVIDIA, SONIDO, TECLADO, RATÓN Y MANDO) AL DRIVER vfio-pci

### gráfica Nvidia (0000:01:00.0) - grupo iommu 11
echo $NVIDIA_PCILOC > /sys/bus/pci/drivers/nouveau/unbind
echo $NVIDIA_PCILOC > /sys/bus/pci/drivers/vfio-pci/bind
echo $AUDIO2_PCILOC > /sys/bus/pci/drivers/snd_hda_intel/unbind
echo $AUDIO2_PCILOC > /sys/bus/pci/drivers/vfio-pci/bind


