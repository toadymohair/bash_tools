#!/bin/bash

con_smtp(){
	stime=`date +"%Y/%m/%d %H:%M:%S.%2N"`

	result=`(sleep 0.5;echo quit) | timeout -sKILL 0.5 telnet $1 $2 2>&1| awk '/^220/{print "OK"}/refused/{print "NG: connection refused.";exit;}'`

	if [ -z "$result" ]; then
		result="NG: timeout."
	fi

	echo $stime " , " $result | tee -a /tmp/test.txt

}


for i in {0..100}
do
	sleep 0.1s
	con_smtp localhost 25 &
	con_smtp localhost 24 &
	con_smtp 10.10.10.1 25 &
done



