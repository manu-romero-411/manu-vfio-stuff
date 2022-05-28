#!/bin/bash


rootdir=$(realpath $(dirname $0))
USUARIO=$(getent passwd 1000 | cut -d: -f1) #Es complicado que sea un usuario distinto del 1000

if [ $EUID -ne 0 ]
	then
		echo "Please run this as root!" 
		exit 1
fi

#Remove files related to Intel GPU passthrough
if [ -a grub_backup.txt ]; then 
	mv grub_backup.txt /etc/default/grub
fi

if [ -a modules_backup.txt ]; then 
	mv modules_backup.txt /etc/modules
fi

update-grub
update-initramfs -u

##Borrar cosas que hayan quedado
rm -r /etc/libvirt/hooks/
rm -r /home/$USUARIO/.libvirt
apt-get autoremove --purge -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf -y

#Now the computer needs to be rebooted
while [ true ]; do
	echo
	echo "To reboot your computer now, please enter (r)"
	read REBOOT

	if [ $REBOOT = "r" ]; then
		reboot
	fi
done
