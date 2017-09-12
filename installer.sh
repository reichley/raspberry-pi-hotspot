#!/bin/bash
#raspberry-pi-hotspot

#The following list of commands and files to edit enable a raspberry pi 3 (running raspbian stretch) to perform hotspot duties while #forwarding client traffic through the ethernet port and out to the interwebs.
#commands to install the software (saving iptables-persistent until we've added some iptables rules)

if [ "$EUID" -ne 0 ];
      then echo "Must be root"
      exit
fi

if [[ $# -lt 2 ]];
      then echo "You need to pass both an ssid and password for your hotspot."
      echo ""
      echo "Usage:"
      echo "sudo $0 yourssid yourpassword"
      echo ""
      exit
fi

HOTSSID="$1"
HOTPASS="$2"

apt-get remove --purge hostapd -yqq
apt-get remove --purge iptables-persistent -yqq
apt-get update -yqq
apt-get upgrade -yqq
apt-get install hostapd dnsmasq dialog -yqq

echo "which interface do you wish to turn into a hotspot?"
ls /sys/class/net | grep wlan
read HOTFACE

echo "which interface do you wish to route the traffic out of? (internet connected)"
ls /sys/class/net
read HOTNET

#edits to /etc/dhcpcd.conf
cat << EOF >> /etc/dhcpcd.conf
interface $HOTFACE
static ip_address=10.1.1.1/24
static routers=10.1.1.1
static domain_name_servers=10.1.1.1,208.67.222.222 #opendns server
EOF

#edits to /etc/dnsmasq.conf
cat << EOF >> /etc/dnsmasq.conf
interface=$HOTFACE
domain-needed
bogus-priv
dhcp-range=10.1.1.2,10.1.1.222,24h
EOF

#edits to /etc/hostapd/hostapd.conf (will be a new file)
cat << EOF >> /etc/hostapd/hostapd.conf
interface=$HOTFACE
#driver=nl80211
ssid=$HOTSSID
hw_mode=g
channel=1
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTPASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
EOF

#edits to /etc/default/hostapd
sed -i -- 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd

#edits to /etc/sysctl.conf (simple, remove the '#' from the front of the following line)
sed -i -- 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf


#edits to /etc/rc.local (to disable power mgmt on the wifi interface, add before the 'exit 0' line)
#sed -i -- "$i sudo iw dev $HOTFACE set power_save off" /etc/rc.local

#commands to add iptables rules (remember to change 'ethX' and 'wlan0' to the interfaces on your pi...easiest way to find them is the iwconfig command)

iptables -t nat -A  POSTROUTING -o $HOTNET -j MASQUERADE
iptables -A FORWARD -i $HOTNET -o $HOTFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $HOTFACE -o $HOTNET -j ACCEPT

#commands to install iptables-persistent (select 'yes' to both ipv4 and ipv6 'save current rules' dialogs)
DEBIAN_FRONTEND=noninteractive apt-get install -yqq iptables-persistent

systemctl enable hostapd
systemctl enable dnsmasq

service hostapd start
service dnsmasq start

echo ""
echo "reboot and connect to the pi hotspot and verify connectivity!"
