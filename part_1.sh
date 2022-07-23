#!/bin/bash

function error(){
	echo "[ERROR] ${@}"
	exit 1
}

rootdir=$(realpath $(dirname $0))
USUARIO=$(getent passwd 1000 | cut -d: -f1) #Es complicado que sea un usuario distinto del 1000

#Making sure this script runs with elevated privileges
if [ $EUID -ne 0 ]
	then
		error "Ejecuta esto como root, cojones!"
fi

#Creating a GRUB variable equal to current content of grub cmdline.
GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`

#Creating a grub backup for the uninstallation script and making uninstall.sh executable
cat /etc/default/grub > grub_backup.txt
chmod +x uninstall.sh

#After the backup has been created, add intel_iommu=on kvm.ignore_msrs=1 i915.enable_gvt=1
# to GRUB variable
GRUB+=" intel_iommu=on video=vesafb:off kvm.ignore_msrs=1 i915.enable_gvt=1 i915.enable_guc=0 i915.enable_psr=0 vfio_pci.ids=10de:1299,10de:0e0f\""
sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

#User verification of new grub and prompt to manually edit it
echo
echo "Grub was modified to look like this: "
echo `cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT"`
echo
echo "Do you want to edit it? y/n"
read YN

if [ $YN = y ]
then
nano /etc/default/grub
fi

#Updating grub
update-grub

#Install required packages for virtualization
apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf -y

#Backing up /etc/modules for future use by uninstall.sh
cat /etc/modules > modules_backup.txt

#Adding kernel modules
echo "vfio_mdev" >> /etc/modules
echo "kvmgt" >> /etc/modules

#Updating initramfs
update-initramfs -u

#Copiar archivos necesarios (bios, etc) a su carpeta
#cp -r $rootdir/archivos /home/$USUARIO/.libvirt

#Configuración de qemu para apparmor
cp $rootdir/qemu.conf /etc/libvirt/qemu.conf
chmod 600 /etc/libvirt/qemu.conf

#Configuración de hooks
mkdir /etc/libvirt/hooks
mkdir /etc/libvirt/hooks/qemu.d
cp $rootdir/qemu.hook /etc/libvirt/hooks/qemu
chmod 755 /etc/libvirt/hooks/qemu

#Poner en marcha dos máquinas virtuales de ejemplo (macOS y Android)
virsh define $rootdir/libvirt/macOS.xml
cp -r $rootdir/default-hook /etc/libvirt/hooks/qemu.d/macOS

virsh define $rootdir/libvirt/android.xml
cp -r $rootdir/default-hook /etc/libvirt/hooks/qemu.d/android

#Now the computer needs to be rebooted
while [ true ]; do
	echo
	echo "To reboot your computer now, please enter (r)"
	read REBOOT

	if [ $REBOOT = "r" ]; then
		reboot
	fi
done
