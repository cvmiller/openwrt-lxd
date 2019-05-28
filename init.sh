#!/bin/sh

# Original script by: melato
#
# Modified by Craig Miller
# December 2018

VERSION="0.93"

usage() {
               echo "	$0 - complete LXD OpenWrt boot  "
	       echo "	e.g. $0 -m"
	       echo "	-m  use mount /dev method (default: use mknod)"
	       echo "	-h  this help"
	       echo "	"
	       echo " By Craig Miller - Version: $VERSION"
	       exit 1
           }

# show help
if [ "$1" == "-h" ]; then
	usage 
fi

# use gjedeer "mount /dev" method
if [ "$1" == "-m" ]; then
	# 8 May 2019
	#
	# gjedeer found a simpler way to get openwrt to complete the boot process
	#
	# mount /dev
	mount -t devtmpfs devtmpfs /dev

else 
	# use "old" way of making nodes
	
	# make devices
	mknod -m 666 /dev/zero c 1 5
	mknod -m 666 /dev/full c 1 7
	mknod -m 666 /dev/random c 1 8
	mknod -m 666 /dev/urandom c 1 9
	mknod -m 666 /dev/null c 1 3
	# create node to make ssh login better --  gjedeer
	mknod -m 666 /dev/ptmx c 5 2
	
	# unmount /dev/pts in order to make nodes for ssh access
	umount /dev/pts
	# make pts devices (for ssh)
	mknod -m 666 /dev/pts/0 c 136 0
	mknod -m 666 /dev/pts/1 c 136 1
	# remount /dev/pts now that nodes are made
	mount -t devpts -o rw,nosuid,noexec,relatime,mode=600,ptmxmode=000 devpts /dev/pts

fi


# wait, let things startup
echo "waiting for rest of boot up..."
while ! pgrep uhttpd 
do
  echo "wait.."
  sleep 1
done



# kick iptables, so firewall will start 
ip6tables -L
iptables -L

echo "Restarting Firewall"
# clear and restart firewall
/etc/init.d/firewall restart

# show result
#ip6tables -L


# insert NAT44 iptables rule, firewall fails to insert this rule
WAN=$(uci get network.wan.ifname)
if [ $(uci get firewall.@zone[1].masq) -eq 1 ]; then
    echo "Enabling IPv4 NAT"
   /usr/sbin/iptables -t nat -A POSTROUTING -o $WAN -j MASQUERADE
fi

echo "Pau!"

