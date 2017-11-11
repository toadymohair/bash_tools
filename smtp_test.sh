#!/bin/bash

DATE_FORMAT='%Y/%m/%d %H:%M:%S.%2N'
OK_MSG='OK'
RFS_MSG='NG: connection refused.'
TOUT_MSG='NG: timeout.'

res_judge(){
	awk '/^220/{print ok;exit;}/refused/{print rfs;exit;}' ok="$OK_MSG" rfs="$RFS_MSG" $1
}


con_smtp(){
	stime=`date +"$DATE_FORMAT"`
	cip=$1
	cport=$2
	tout=$3

	result=`(sleep $tout;echo quit) | timeout -sKILL $tout telnet $cip $cport 2>&1| res_judge`
 	if [ -z "$result" ]; then
		result="$TOUT_MSG"
	fi

	echo $stime " , " $result | tee -a /tmp/test.txt

}


ip_port=(`echo $1 | tr ':' ' '`)
ip=${ip_port[0]}
port=${ip_port[1]}
timeout=$2


for i in {0..100}
do
	#sleep 0.1s
	usleep 100000
	con_smtp $ip $port $timeout &

done



