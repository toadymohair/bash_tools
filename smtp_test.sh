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

CNT=0		# 接続回数カウンタ

OK_CNT_FILE=$(mktemp)	# 接続成功回数カウンタ
NG_CNT_FILE=$(mktemp)	# 接続成功回数カウンタ

echo 0 > $OK_CNT_FILE
echo 0 > $NG_CNT_FILE



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
	local _stime=`date +"$DATE_FORMAT"`
	local _ok_cnt=`cat $OK_CNT_FILE`
	local _ng_cnt=`cat $NG_CNT_FILE`

	local _result=`(sleep $CON_TIMEOUT;echo quit) | timeout -sKILL $CON_TIMEOUT telnet $1 $CON_PORT 2>&1| _res_judge`

	if [ -z "$_result" ]; then
		_result="$TOUT_MSG"
	fi

	if [ "$_result" = "$OK_MSG" ]; then
	#	(( OK_CNT ++ ))
		echo $(( $_ok_cnt + 1 )) > $OK_CNT_FILE

	else
		echo $(( $_ng_cnt + 1 )) > $NG_CNT_FILE

	fi

	echo $_stime " , " $_result | tee -a /tmp/test.txt

}

# 終了処理
function _finalize(){
	wait
	echo "+++++++++++++++++++++++++++++++++"
	echo "Total: " $CNT ", OK: " `cat $OK_CNT_FILE` ", NG: " `cat $NG_CNT_FILE`
	rm -f $OK_CNT_FILE
	rm -f $NG_CNT_FILE
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


trap "_finalize" 0

while : 
do
	if [ $CON_COUNT -ne 0 -a $CNT -ge $((CON_COUNT)) ]; then
		break
	fi

	sleep "$CON_INTERVAL"s
	_con_smtp $1 &
	(( CNT ++ ))
done



