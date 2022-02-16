#!/bin/bash

set -x

if [ -f /usr/local/bin/qemu-system-x86_64 ]; then
	QEMULOCAL=/usr/local
fi

echo "allow all" | sudo tee $QEMULOCAL/etc/qemu/${USER}.conf
echo "include $QEMULOCAL/etc/qemu/${USER}.conf" | sudo tee --append $QEMULOCAL/etc/qemu/bridge.conf
sudo chown root:${USER} $QEMULOCAL/etc/qemu/${USER}.conf
sudo chmod 640 $QEMULOCAL/etc/qemu/${USER}.conf
