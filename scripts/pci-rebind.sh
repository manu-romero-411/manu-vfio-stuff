#!/bin/bash
## SALIR DEL MODO VFIO Y RECUPERAR TODAS LAS COSAS (ESCRITORIO, DISPOSITIVOS...)
## FECHA: 9 de febrero de 2022

set -x
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

## RECOLOCAR CADA DISPOSITIVO CON SU DRIVER

### gráfica integrada
echo $IGPU_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
echo $IGPU_PCILOC > /sys/bus/pci/drivers/i915/bind

### chip de sonido principal
echo $AUDIO1_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
echo $AUDIO1_PCILOC > /sys/bus/pci/drivers/snd_hda_intel/bind
echo $SMBUS_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
echo $SMBUS_PCILOC > /sys/bus/pci/drivers/i801_smbus/bind
echo $MEMCONT_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
echo $PUENTEISA_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind

### gráfica Nvidia
#echo $NVIDIA_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
#echo $NVIDIA_PCILOC > /sys/bus/pci/drivers/nouveau/bind
#echo $AUDIO2_PCILOC > /sys/bus/pci/drivers/vfio-pci/unbind
#echo $AUDIO2_PCILOC > /sys/bus/pci/drivers/snd_hda_intel/bind

### dispositivos i2c
echo $PCILOC_I2C1 > /sys/bus/pci/drivers/vfio-pci/unbind
echo $PCILOC_I2C1 > /sys/bus/pci/drivers/intel-lpss/bind
echo $PCILOC_I2C2 > /sys/bus/pci/drivers/vfio-pci/unbind
echo $PCILOC_I2C2 > /sys/bus/pci/drivers/intel-lpss/bind


## POSYASTAH EL ESCRITORIO FUNCANDO

service lightdm start #SIGO SIENDO NOSTÁLGICO DEL SYSVINIT
