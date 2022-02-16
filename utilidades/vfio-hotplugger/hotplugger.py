#!/usr/bin/python3
import re
import os
import ast
import sys
import yaml
import json
import time
import pprint
from pathlib import Path
from qemu import *

configFilename = Path(__file__).parent / "config.yaml"
tmpFolderPath = Path(__file__).parent / "tmp"


def printp(dict):
	pprint.pprint(dict, width=1)


def sanitizeDevpath(devpath):
	return devpath.replace('/', '_').replace(':', '_')


def sanitize(str):
	return "".join(re.findall("[a-zA-Z0-9]+", str))


def loadConfig():
	with open(configFilename) as file:
		return yaml.load(file, Loader=yaml.FullLoader)


def savePortDeviceMetadata(metadata, devpath):
	if not os.path.exists(tmpFolderPath):
		os.makedirs(tmpFolderPath)
	usbdefPath = f"{tmpFolderPath}/{sanitizeDevpath(devpath)}"
	print(f"Saving port metadata to {usbdefPath} ...")
	f = open(usbdefPath, "w")
	f.write(json.dumps(metadata))
	f.close()


def loadPortDeviceMetadata(config, devpath):
	for rootKey, rootValue in config.items():
		for k, v in rootValue.items():
			for port in v['ports']:
				if devpath.find(port) >= 0:
					print(f"Found {devpath} in port {port}")

					if not os.path.exists(tmpFolderPath):
						os.makedirs(tmpFolderPath)
					metadataFiles = [f for f in os.listdir(tmpFolderPath) if os.path.isfile(os.path.join(tmpFolderPath, f))]
					metadataFiles.sort(key=len, reverse=True)
					print(f"Metadata files:")
					printp(metadataFiles)

					usbDefPathFile = sanitizeDevpath(devpath)
					for f in metadataFiles:
						metadataFilename = os.path.join(tmpFolderPath, f)
						if usbDefPathFile.find(f) >= 0:
							print(f"Found {devpath} in {metadataFilename}")
							with open(metadataFilename) as metadataFile:
								rv = json.loads(metadataFile.read())
								rv["SOCKET"] = rootValue[k]['socket']
								rv["FILENAME"] = metadataFilename
								rv["HUBS"] = rootValue[k]['hubs']
								rv["DELAY"] = rootValue[k]['delay']
								return rv


def plug():

	print('==================================================================')
	print('PLUG')
	print('==================================================================')
	printp(dict(os.environ))
	print('==================================================================')
	config = loadConfig()
	devpath = os.environ['DEVPATH']
	is_usb_port = (os.getenv('DEVNUM') or '') != '' and (os.getenv('BUSNUM') or '') != ''
	print(f"Is USB Port? {is_usb_port}")

	if is_usb_port == True:
		savePortDeviceMetadata(json.loads(json.dumps(dict(os.environ))), devpath)
	else:
		metadata = loadPortDeviceMetadata(config, devpath)
		if not metadata:
			print(f"Metadata file for {devpath} not found")
		else:
			print(metadata)

		print(f"Connecting to QEMU at {metadata['SOCKET']}...")
		with QEMU(metadata["SOCKET"]) as qemu:
			usbhost = qemu.hmp("info usbhost")
		print(usbhost)

		hostport = 0
		hostaddr = metadata['DEVNUM'].lstrip('0')
		hostbus = metadata['BUSNUM'].lstrip('0')
		print(f"Looking for USB Bus: {hostbus}, Addr {hostaddr} ...")

		for line in usbhost.splitlines():
			if line.find(f"Bus {hostbus}") >= 0:
				if line.find(f"Addr {hostaddr}") >= 0:
					print('FOUND IN', line)
					hostport_search = re.search(".*Port.*?([\d\.]*),", line, re.IGNORECASE)
					hostport = hostport_search.group(1)
					break
		print(f"Found USB Bus: {hostbus}, Addr {hostaddr}, Port {hostport}")

		if hostport != 0:
			print(f"Plugging USB device in port {hostport}...")

			with QEMU(metadata["SOCKET"]) as qemu:

				device_id = sanitize(metadata['DEVNAME'])
				print(f"Device ID = {device_id}")
				for guesthub in metadata["HUBS"]:
					time.sleep(int(metadata["DELAY"]))
					result = qemu.hmp(f"device_add driver=usb-host,bus={guesthub},hostbus={hostbus},hostport={hostport},id={device_id}")
					if result.find("speed mismatch trying to attach usb device") >= 0:
						qemu.hmp(f"device_del {device_id}")
					else:
						print(f"Device plugged in on hub {guesthub}. Current USB devices on guest:")
						print(qemu.hmp("info usb"))
						break

			if Path(metadata["FILENAME"]).exists():
				os.remove(metadata["FILENAME"])


def unplug():

	print('==================================================================')
	print('UNPLUG')
	print('==================================================================')
	printp(dict(os.environ))
	print('==================================================================')
	config = loadConfig()
	devpath = os.environ['DEVPATH']
	if (os.getenv('DEVNAME') or '') != '':
		for rootKey, rootValue in config.items():
			for k, v in rootValue.items():
				socket = rootValue[k]['socket']
				socketFile = Path(socket)
				if socketFile.exists():
					print(f"Connecting to QEMU at {socket}...")
					with QEMU(socket) as qemu:
						usbhost = qemu.hmp("info usbhost")
					print(usbhost)

					with QEMU(socket) as qemu:
						device_id = sanitize(os.environ["DEVNAME"])
						qemu.hmp(f"device_del {device_id}")
						print(f"Device unplugged from {k}")
						print(qemu.hmp("info usb"))
						usbDefPathFile = os.path.join(tmpFolderPath, sanitizeDevpath(devpath))
						if Path(usbDefPathFile).exists():
							os.remove(usbDefPathFile)


action = os.environ['ACTION']
if action == 'add':
	plug()
elif action == 'remove':
	unplug()
else:
	print("")
	print("Device plug/unplug helper script")
	print("")
	print("This should be run by an udev rules file you create that will trigger on every")
	print("USB command. For more info have a look at the README file.")
