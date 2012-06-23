#!/bin/bash

tmp="/tmp/blacklist"
lib="/var/lib/blacklist"
url="http://list.iblocklist.com/?list=bt_level1&fileformat=p2p&archiveformat=gz"
filename="bt_level1.gz"
filtername="p2pfilter"
portstart=6889
portstop=6999
update="update"
start="start"
stop="stop"
reload="reload"


if [ "$1" = "$update" ]; then
        echo "Getting rule updates"
        rm -fr $tmp
        mkdir -p $tmp
        echo "Downloading"
        wget -O $tmp/$filename $url &> /dev/null
        gzip -d $tmp/$filename
        filename=${filename%.gz}
        echo "*filter" > $tmp/filter
        echo "-N $filtername" >> $tmp/filter


	echo "Extracting"
	grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\(-[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.\)\?$' -o $tmp/$filename |\
		grep -o '[0-9.-]*' | while read file; do
		echo "-A $filtername -m iprange --src-range $file -j DROP" >> $tmp/filter; done;
	echo "-A $filtername -j ACCEPT" >> $tmp/filter
	echo "COMMIT" >> $tmp/filter
	mkdir -p $lib
	mv $tmp/filter $lib/
	rm -rf $tmp
	exit

elif [ "$1" = "$start" ]; then
	echo "Adding rules"
	iptables -F $filtername &> /dev/null
	iptables -D INPUT -p tcp --dport $portstart:$portstop -j $filtername &> /dev/null
	iptables -D INPUT -p udp --dport $portstart:$portstop -j $filtername &> /dev/null
	iptables -D OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT &> /dev/null
	iptables -D OUTPUT -p tcp -j $filtername &> /dev/null
	iptables -D OUTPUT -p udp -j $filtername &> /dev/null
	iptables -X $filtername &> /dev/null

	iptables-restore --noflush < $lib/filter
	iptables -I INPUT 4 -p tcp --dport $portstart:$portstop -j $filtername
	iptables -I INPUT 4 -p udp --dport $portstart:$portstop -j $filtername
	iptables -I OUTPUT 1 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp -j $filtername
	iptables -A OUTPUT -p udp -j $filtername
	exit

elif [ "$1" = "$stop" ]; then
	echo "Flushing"
	iptables -F $filtername
	iptables -D INPUT -p tcp --dport $portstart:$portstop -j $filtername
	iptables -D INPUT -p udp --dport $portstart:$portstop -j $filtername
	iptables -D OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT &> /dev/null
	iptables -D OUTPUT -p tcp -j $filtername &> /dev/null
	iptables -D OUTPUT -p udp -j $filtername &> /dev/null
	iptables -X $filtername &> /dev/null
	exit

elif [ "$1" = "$reload" ]; then
	echo "Flushing"
	iptables -F $filtername
	iptables -D INPUT -p tcp --dport $portstart:$portstop -j $filtername
	iptables -D INPUT -p udp --dport $portstart:$portstop -j $filtername
	iptables -D OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT &> /dev/null
	iptables -D OUTPUT -p tcp -j $filtername &> /dev/null
	iptables -D OUTPUT -p udp -j $filtername &> /dev/null
	iptables -X $filtername &> /dev/null

	echo "Adding rules"
	iptables -F $filtername &> /dev/null
	iptables -D INPUT -p tcp --dport $portstart:$portstop -j $filtername &> /dev/null
	iptables -D INPUT -p udp --dport $portstart:$portstop -j $filtername &> /dev/null
	iptables -D OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT &> /dev/null
	iptables -D OUTPUT -p tcp -j $filtername &> /dev/null
	iptables -D OUTPUT -p udp -j $filtername &> /dev/null
	iptables -X $filtername &> /dev/null

	iptables-restore --noflush < $lib/filter
	iptables -I INPUT 4 -p tcp --dport $portstart:$portstop -j $filtername
	iptables -I INPUT 4 -p udp --dport $portstart:$portstop -j $filtername
	iptables -I OUTPUT 1 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp -j $filtername
	iptables -A OUTPUT -p udp -j $filtername
	exit

else
	echo "Usage: $0 <command>"
	echo "commands:"
	echo "	$update (updates the filter file from the online blocklists"
	echo "	$start  (adds ips to drop list, as well as adds $portstart-$portstop to open ports)"
	echo "	$stop   (opposite of start)"
	echo "	$reload (reloads the blocklist)"
fi