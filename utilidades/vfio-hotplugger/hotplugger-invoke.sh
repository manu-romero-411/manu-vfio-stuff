#!/bin/bash

while ! pidof qemu-system-x86_64; do
	sleep 1
done
/bin/bash -c 'python3 /opt/vfio-hotplugger/hotplugger.py boot'
