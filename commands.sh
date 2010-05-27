#!/bin/sh

echo "setting hostname"
set -a
NAME="@PARAM1@"
sysctl -w kernel.hostname=$NAME
uci set system.@system[0].hostname=$NAME
uci commit

echo "setting wireless"
set -a
IP="@PARAM3@"
CHANNEL="@PARAM5@"
CELL="@PARAM6@"
uci set wireless.wifi0.channel=$CHANNEL
uci set wireless.wifi0.disabled=0
uci set wireless.wifi0.hwmode=11g
uci set wireless.wifi0.txpower=1
uci set wireless.@wifi-iface[0].network=wlan
uci set wireless.@wifi-iface[0].mode=adhoc
uci set wireless.@wifi-iface[0].ssid=WBM2009v2-Test0
uci set wireless.@wifi-iface[0].encryption=none
uci set wireless.@wifi-iface[0].bssid=$CELL
uci set wireless.@wifi-iface[0].rate=54M
uci set wireless.@wifi-iface[0].bgscan=0
uci set network.wlan=interface
uci set network.wlan.proto=static
uci set network.wlan.ipaddr=$IP
uci set network.wlan.netmask=255.255.255.0
uci set wireless.wifi0.disabled=0
uci commit wireless && wifi
uci commit

echo "disabling servers"
set -a
/etc/init.d/dnsmasq stop
/etc/init.d/dnsmasq disable
/etc/init.d/firewall stop
/etc/init.d/firewall disable
/etc/init.d/httpd stop
/etc/init.d/httpd disable

echo "configuring wired network interface"
WIREDIP="@PARAM2@"
uci set network.zlan=alias
uci set network.zlan.interface=lan
uci set network.zlan.proto=static
uci set network.zlan.ipaddr=$WIREDIP
uci set network.zlan.netmask=255.255.255.0
uci commit

#reboot
echo "finished!"
exit
