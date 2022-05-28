#!/bin/bash
#bash /usr/local/bin/vfio-bind usb -r
bash /usr/local/bin/vfio-bind audio -r
#bash /usr/local/bin/vfio-bind dgpu -r
bash /usr/local/bin/vfio-bind igpu -r
