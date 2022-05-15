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
export PCILOC_I2C1=0000:00:15.0
export PCILOC_I2C2=0000:00:15.1

## PCIIDs
export IGPU_PCIID="8086 5916"
export AUDIO1_PCIID="8086 9d71"
export PUENTEISA_PCIID="8086 9d58"
export MEMCONT_PCIID="8086 9d21"
export SMBUS_PCIID="8086 9d23"
export NVIDIA_PCIID="10de 1299"
export AUDIO2_PCIID="10de 0e0f"
export PCIID_I2C1="8086 9d60"
export PCIID_I2C2="8086 9d61"

#export DefaultGVTMODE=1

## CERRAR LO GRÁFICO (TODO: CERRAR SESIÓN DE CINNAMON/XFCE/GNOME DE FORMA CORRECTA, POR SI SE RAYA LUEGO)


## DECIRLE A vfio-pci QUE LOS DISPOSITIVOS TALES VAN ENTRAR EN GRUPOS IOMMU
echo $PCIID_I2C1 > /sys/bus/pci/drivers/vfio-pci/new_id
echo $PCIID_I2C2 > /sys/bus/pci/drivers/vfio-pci/new_id

## PASAR LOS DISPOSITIVOS (GRÁFICAS INTEL Y NVIDIA, SONIDO, TECLADO, RATÓN Y MANDO) AL DRIVER vfio-pci

### dispositivos i2c (touchpad)
echo $PCILOC_I2C1 > /sys/bus/pci/drivers/intel-lpss/unbind
echo $PCILOC_I2C1 > /sys/bus/pci/drivers/vfio-pci/bind
echo $PCILOC_I2C2 > /sys/bus/pci/drivers/intel-lpss/unbind
echo $PCILOC_I2C2 > /sys/bus/pci/drivers/vfio-pci/bind


