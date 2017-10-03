# raspberry-pi-hotspot
The scripts in this directory enable a raspberry pi 3 (running raspbian jessie or stretch) to perform hotspot duties while forwarding client traffic through the ethernet port (or another wifi card/dongle) and out to the interwebs.

## Installed software (and their dependencies)
- hostapd
- dnsmasq
- iptables-persistent

## Files edited
- /etc/network/interfaces
- /etc/dhcpcd.conf
- /etc/dnsmasq.conf
- /etc/hostapd/hostapd.conf (created and edited)
- /etc/default/hostapd
- /etc/sysctl.conf

## 3 iptables rules added
```
sudo iptables -t nat -A  POSTROUTING -o ethX -j MASQUERADE
sudo iptables -A FORWARD -i ethX -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o ethX -j ACCEPT
```

## user input required
- prompted for hotspot ssid
- prompted for hotspot password
- asked which interface to route traffic out to the internet
- asked which interface to be used as a hotspot
- asked to reboot

### REMEMBER! there are separate scripts for raspbian jessie and stretch 
