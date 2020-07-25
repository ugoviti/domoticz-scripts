# Configuring USB Devices

sudo lsusb -v | grep 'idVendor\|idProduct\|iProduct\|iSerial'

example output:
```
idVendor           0x1cf1 Dresden Elektronik
idProduct          0x0030 
iProduct                2 ConBee II
iSerial                 3 DE2198636

idVendor           0x0658 Sigma Designs, Inc.
idProduct          0x0200 Aeotec Z-Stick Gen5 (ZW090) - UZB
iProduct                0 
iSerial                 1 12345678-9012-3456-7890-123456789012
```

file: /etc/udev/rules.d/99-local.rules
```
SUBSYSTEM=="tty", KERNEL=="ttyACM*", GROUP="dialout", MODE="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1cf1", ATTRS{idProduct}=="0030", SYMLINK+="ttyACM-ConBee2"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="ttyACM-ZStick-5G"

udevadm control --reload-rules
```

# Using vhclient

docker exec vhclient ./vhclientx86_64 -t "LIST"

docker exec vhclient ./vhclientx86_64 -t "MANUAL HUB ADD,usb01"

docker exec vhclient ./vhclientx86_64 -t "AUTO USE HUB,usb01"

or:
docker exec vhclient ./vhclientx86_64 -t "USE,CloudHub_e34f38.113"
docker exec vhclient ./vhclientx86_64 -t "USE,CloudHub_e34f38.1112"
