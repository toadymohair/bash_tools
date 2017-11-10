#!/bin/bash

con_smtp(){
	stime=`date`
	result=`(sleep 0.5;echo quit) | timeout -sKILL 0.5 telnet localhost 25 | awk '$1==220{print $1}'`
	echo $stime " , " $result | tee -a /tmp/test.txt
	result=`(sleep 0.5;echo quit) | timeout -sKILL 0.5 telnet 10.10.10.1 25 | awk '$1==220{print $1}'`
	#result=`(sleep 0.5;echo quit) | telnet localhost 25 | awk -v t="$stime" '$1==220{print t " , " $1}'`
	echo $stime " , " $result | tee -a /tmp/test.txt
}

for i in {0..100}
do
	sleep 0.1s
	con_smtp &
	#echo "i = $i"	
done



