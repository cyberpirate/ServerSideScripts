#!/bin/bash
shres=$HOME
dat=.oldip.dat
email=empty

if [ $email=empty ]; then
	echo "You need to set up your email. Edit this file $0";
	exit;
fi

ip=`curl http://automation.whatismyip.com/n09230945.asp * 2> /dev/null`
oldip=`cat $shres/$dat * 2> /dev/null`

if [ -n $ip ]; then
	if [ "$ip" != "$oldip" ]; then
		echo "Changed to new IP $ip on `date`" | mail -s "New IP $ip" $email;
		echo $ip > $shres/$dat;
	fi
fi