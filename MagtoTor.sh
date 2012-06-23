#!/bin/bash

watchdir=empty
tmp="/tmp/mag"

if [ $watchdir=empty ]; then
	echo "You need to set up your watch directory. Edit this file $0";
	exit;
fi

function convert {
	[[ "$1" =~ xt=urn:btih:([^&/]+) ]] || exit
	hashh=${BASH_REMATCH[1]}
	if [[ "$1" =~ dn=([^&/]) ]]; then
		filename=${BASH_REMATCH[1]}
	else
		filename=$hashh
	fi
	echo "d10:magnet-uri${#1}:${1}e" > "$watchdir/meta-$filename.torrent"
}

function get_magnet {
	mkdir -p $tmp
	wget -O $tmp/index.html --post-data="url=$1" http://centrump2p.com/magnet/ &> /dev/null
	magnet=`grep magnet:\?xt=urn:btih:[[:digit:][:upper:]]*\" $tmp/index.html -o`
	magnet=${magnet%\"}
	rm -rf $tmp
	echo $magnet
}

if [ "$1" = "-s" ] || [ "$1" = "--scan" ]; then
	for i in 'ls -1 $watchdir/*.magnet'; do
		convert 'cat $i'
	done
	for i in 'ls -1 $watchdir/*.infohash'; do
		inf=`cat $i`
		convert `get_magnet $inf`
	done

elif [ "$1" = "-sp" ] || [ "$1" = "--scan-print" ]; then
	for i in 'ls -1 $watchdir/*.infohash'; do
		inf=`cat $i`
		echo `get_magnet $inf`
	done

elif [ "$1" = "-c" ] || [ "$1" = "--convert" ]; then
	convert $2

elif [ "$1" = "-i" ] || [ "$1" = "--info-hash" ]; then
	convert `get_magnet $2`

elif [ "$1" = "-ip" ] || [ "$1" = "--info-print" ]; then
	echo `get_magnet $2`

else
	echo "Usage: magtotor <command> [info hash|magnet link]"
	echo "commands:"
	echo "	-s  --scan Scans $watchdir for .magnet or .infohash files with the magnet uri in them"
	echo "	-c  --convert <magnet> convert magnet and put torrent in $watchdir"
	echo "	-i  --info-hash <info-hash> convert info hash to magnet then to torrent"
	echo "	-sp --scan-print scan watch directory for .infohash files and print magnet links"
	echo "	-ip --info-print print magnet from info hash"
fi
