# raspberry-pi-hotspot
The following list of commands and files to edit enable a raspberry pi 3 (running raspbian stretch) to perform hotspot duties while forwarding client traffic through the ethernet port and out to the interwebs.

## commands to install the software (saving iptables-persistent until we've added some iptables rules)
```sudo apt install hostapd dnsmasq -y```

## edits to /etc/dhcpcd.conf
```
interface wlan0
static ip_address=10.1.1.1/24
static routers=10.1.1.1
static domain_name_servers=10.1.1.1,208.67.222.222 #opendns server
```

## edits to /etc/dnsmasq.conf
```
interface=wlan0
domain-needed
bogus-priv
dhcp-range=10.1.1.2,10.1.1.222,24h
```

## edits to /etc/hostapd/hostapd.conf (will be a new file)
```
interface=wlan0
driver=nl80211
# the 'ssid' will indeed be your hotspot ssid
ssid=pipi
hw_mode=g
channel=1
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
# the wpa_passphrase will be your hotspot's password (use at least 8 characters)
wpa_passphrase=314314314
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
```

## edits to /etc/default/hostapd
```
# uncomment following line and add file location between ""
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

## edits to /etc/sysctl.conf (simple, remove the '#' from the front of the following line)
```
net.ipv4.ip_forward=1
```

## edits to /etc/rc.local (to disable power mgmt on the wifi interface, add before the 'exit 0' line)
```
sudo iw dev wlan0 set power_save off
```

## commands to add iptables rules (remember to change 'ethX' and 'wlan0' to the interfaces on your pi...easiest way to find them is the ```iwconfig``` command) 
```
sudo iptables -t nat -A  POSTROUTING -o ethX -j MASQUERADE
sudo iptables -A FORWARD -i ethX -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o ethX -j ACCEPT
```

## commands to install iptables-persistent (select 'yes' to both ipv4 and ipv6 'save current rules' dialogs)
```
sudo apt install iptables-persistent -y
```

## commands to restart (check for errors)
```
sudo service hostapd restart
sudo service dnsmasq restart
```
# reboot, connect to the pi hotspot and verify connectivity!
```
sudo reboot
```
