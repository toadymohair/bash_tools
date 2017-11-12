#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++
# smtp_test.sh
# k.yamamoto
# Usage: smtp_test.sh [options]... ip_address
# Description:
#  SMTP 接続（TELNET) を連続で発行し、
#  結果をファイル出力する。
#  SMTPサーバから応答コード 220 が返ってきた場合にOK、
#  それ以外の場合はNGと判断する。
# Options:
#  -c    接続実行回数 。デフォルトは無限。
#  -i     接続実行間隔(秒)。デフォルトは 1秒。
#  -p    ポート番号。デフォルトは 25。
#  -t    接続タイムアウト(秒)。デフォルトは 1 秒。
# +++++++++++++++++++++++++++++++++++++++++++++++++++++

set -e


# 定数定義
readonly DATE_FORMAT='%Y/%m/%d %H:%M:%S.%2N'
readonly OK_MSG='OK'
readonly RFS_MSG='NG: connection refused.'
readonly TOUT_MSG='NG: timeout.'

# グローバル変数
CON_COUNT=0	# 接続回数（0は無限）
CON_INTERVAL=1	# 接続間隔（秒）
CON_PORT=25	# 接続ポート
CON_TIMEOUT=1	# タイムアウト（秒）

# 使い方
function _usage() {
cat <<_EOT_
Usage:
  $(basename ${0}) [-c count] [-i interval] [-t timeout] [-p port] ip_address
_EOT_
exit 1
}


# 返り値を元に結果を判定
function _res_judge(){
	awk '/^220/{print ok;exit;}/refused/{print rfs;exit;}' ok="$OK_MSG" rfs="$RFS_MSG" $1
}

# TELNET 接続
function _con_smtp(){
	stime=`date +"$DATE_FORMAT"`
	cip=$1
	cport=$2
	tout=$3

	result=`(sleep $tout;echo quit) | timeout -sKILL $tout telnet $cip $cport 2>&1| _res_judge`
 	if [ -z "$result" ]; then
		result="$TOUT_MSG"
	fi

	echo $stime " , " $result | tee -a /tmp/test.txt

}


# 引数・オプション取得
if [ "$OPTIND" = 1 ]; then
  while getopts :c:i:p:t:h: OPT
  do
   case $OPT in
     c)
       CON_COUNT=$OPTARG
       echo "count: $CON_COUNT"            # for debug
       ;;
     i) 	
       CON_INTERVAL=$OPTARG
       echo "interval: $CON_INTERVAL"            # for debug
       ;;
     p)
       CON_PORT=$OPTARG
       echo "port: $CON_PORT"              # for debug
       ;;
     t)
       CON_TIMEOUT=$OPTARG
       echo "timeout: $CON_TIMEOUT"              # for debug
       ;;
     h)
       echo "h option. display help"       # for debug
       _usage
       ;;
     :|\?)
       _usage
       ;;
   esac
 done
else
 echo "No installed getopts-command." 1>&2
 exit 1
fi

shift $((OPTIND-1))


if [ "$#" -ne 1 ]; then
	echo "$#"
       _usage
fi	


for i in {0..100}
do
	sleep "$CON_INTERVAL"s
	# usleep 100000
	_con_smtp $1 $CON_PORT $CON_TIMEOUT &

done



