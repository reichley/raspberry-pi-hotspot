#!/bin/bash
#raspberry-pi-hotspot

#The following list of commands and files to edit enable a raspberry pi 3 (running raspbian stretch) to perform hotspot duties while #forwarding client traffic through the ethernet port and out to the interwebs.
#commands to install the software (saving iptables-persistent until we've added some iptables rules)

if [ "$EUID" -ne 0 ];
      then echo "Must be root"
      exit
fi

echo ""
echo "please enter an ssid for your hotspot"
read HOTSSID

echo ""
echo "please enter a password for your hotspot"
read HOTPASS

echo ""
echo "removing hostapd/iptables-persistent if installed..."
apt-get remove --purge hostapd -yq
apt-get remove --purge iptables-persistent -yq
apt-get update -yq
apt-get upgrade -yq
apt-get install hostapd dnsmasq dialog -yq

for i in $(ls /sys/class/net); do
  if ping -c 1 -I $i 208.67.222.222 &> /dev/null
  then
    echo ""
    echo "$i is connected to the internet"
  else
    :
  fi
done

echo ""
echo "which interface do you wish to route the traffic out of? (internet connected)"
ls /sys/class/net
read HOTNET

echo ""
echo "which interface do you wish to turn into a hotspot?"
ls /sys/class/net
read HOTFACE

#edits to /etc/dhcpcd.conf
echo ""
echo "assigning 10.1.1.1/24 as wifi ap ip/gateway..."
cat << EOF >> /etc/dhcpcd.conf
interface $HOTFACE
static ip_address=10.1.1.1/24
static routers=10.1.1.1
static domain_name_servers=10.1.1.1,208.67.222.222 #opendns server
EOF

#edits to /etc/dnsmasq.conf
echo ""
echo "clients will be .2 through .222"
cat << EOF >> /etc/dnsmasq.conf
interface=$HOTFACE
domain-needed
bogus-priv
dhcp-range=10.1.1.2,10.1.1.222,24h
EOF

#edits to /etc/hostapd/hostapd.conf (will be a new file)
echo ""
echo "just a reminder, the ap ssid is $HOTSSID and pw is $HOTPASS"
cat << EOF >> /etc/hostapd/hostapd.conf
interface=$HOTFACE
#driver=nl80211
ssid=$HOTSSID
hw_mode=g
channel=3
ieee80211n=1
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTPASS
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
EOF

#edits to /etc/default/hostapd
sed -i -- 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd

#edits to /etc/sysctl.conf (simple, remove the '#' from the front of the following line)
sed -i -- 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf


#edits to /etc/rc.local (to disable power mgmt on the wifi interface, add before the 'exit 0' line)
#sed -i -- '$isudo iw dev "$HOTFACE" set power_save off' /etc/rc.local

#commands to add iptables rules (remember to change 'ethX' and 'wlan0' to the interfaces on your pi...easiest way to find them is the iwconfig command)

iptables -t nat -A  POSTROUTING -o $HOTNET -j MASQUERADE
iptables -A FORWARD -i $HOTNET -o $HOTFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $HOTFACE -o $HOTNET -j ACCEPT

#commands to install iptables-persistent (select 'yes' to both ipv4 and ipv6 'save current rules' dialogs)
DEBIAN_FRONTEND=noninteractive apt-get install -yqq iptables-persistent

systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

service hostapd start
service dnsmasq start

echo ""
echo "reboot and connect to the pi hotspot and verify connectivity!"
