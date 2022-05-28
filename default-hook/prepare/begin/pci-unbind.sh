#!/bin/bash
## unbind

bash /usr/local/bin/vfio-bind igpu -u
#bash /usr/local/bin/vfio-bind dgpu -u
bash /usr/local/bin/vfio-bind audio -u
#bash /usr/local/bin/vfio-bind usb -u
