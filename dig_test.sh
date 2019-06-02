#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++
# smtp_test.sh
# k.yamamoto
# Usage: smtp_test.sh [options]... server_ip query_domain
# Description:
#  SMTP 接続（TELNET) を連続で発行し、
#  結果をファイル出力する。
#  SMTPサーバから応答コード 220 が返ってきた場合にOK、
#  それ以外の場合はNGと判断する。
# Options:
#  -c    接続実行回数 。デフォルトは無限。
#  -f    結果ファイル名のプレフィックス。デフォルトは「smtp_test_result」。
#  -i    接続実行間隔(秒)。デフォルトは 1秒。
#  -p    ポート番号。デフォルトは 25。
#  -t    接続タイムアウト(秒)。デフォルトは 1 秒。
# +++++++++++++++++++++++++++++++++++++++++++++++++++++



# 定数定義
readonly DATE_FORMAT_FOR_RESULT='%Y/%m/%d %H:%M:%S.%2N'	# 日付フォーマット（結果行）
readonly DATE_FORMAT_FOR_FILE='%Y%m%d-%H%M%S'		# 日付フォーマット（結果ファイル名）
readonly OK_MSG='OK'					# 接続成功テキスト
readonly RFS_MSG='NG: connection refused.'		# 接続失敗テキスト（接続拒否）
readonly TOUT_MSG='NG: timeout.'			# 接続失敗テキスト（タイムアウト）

# グローバル変数
CON_COUNT=0						# 接続回数（0は無限）
CON_INTERVAL=1						# 接続間隔（秒）
CON_IP=$1						# 接続IPアドレス
CON_PORT=53						# 接続ポート
CON_TIMEOUT=1						# タイムアウト（秒）

RESULT_FILE_PREFIX='dig_test_result'			# 結果ファイル名プレフィックス
CNT=0							# 接続回数カウンタ
OK_CNT=0						# 成功回数カウンタ
NG_CNT=0						# 失敗回数カウンタ
RESULT_FILE=""						# 結果ファイル
TMP_RESULT_FILE=$(mktemp)				# 一時結果ファイル



# 使い方
function _usage() {
cat <<_EOT_
Usage:
  $(basename ${0}) [-c count] [-f file_name_prefix] [-i interval] [-t timeout] [-p port] server_ip query_domain
_EOT_
exit 1
}


# 返り値を元に結果を判定
function _res_judge(){

  local _res

  _res=`awk '/status: NO ERROR/{print ok;exit;}/refused/{print rfs;exit;}' ok="$OK_MSG" rfs="$RFS_MSG" $1`

  if [ -z "$_res" ]; then
    _res="$TOUT_MSG"
  fi

  echo $_res

}



# 接続コマンド実行
function _con_smtp(){
  local _stime=`date +"$DATE_FORMAT_FOR_RESULT"`
  local _cmd="dig -p $CON_PORT @$CON_IP $QUERY_DOMAIN"

  local _result=`(sleep $CON_TIMEOUT;echo quit) | timeout -sKILL $CON_TIMEOUT $_cmd 2>&1| _res_judge`

  echo $_stime " , " $_result | tee -a $TMP_RESULT_FILE

}

# 終了処理
function _finalize(){

	wait

	# 成功/失敗数をカウント
	OK_CNT=`cat $TMP_RESULT_FILE | awk 'BEGIN{count=0;}$4 == "OK"{count++}END{print count}'`
	NG_CNT=`cat $TMP_RESULT_FILE | awk 'BEGIN{count=0;}$4 == "NG:"{count++}END{print count}'`

	# 各種パラメータと結果サマリを表示
	echo "++++++++++++++++++++++++++++++++++++++++++" | tee $RESULT_FILE
	echo "**SMTP TEST RESULT**" | tee -a $RESULT_FILE
	echo "- Parameters" | tee -a $RESULT_FILE
	echo "	target = " $CON_IP":"$CON_PORT | tee -a $RESULT_FILE
	echo "	interval = " $CON_INTERVAL "s"| tee -a $RESULT_FILE
	echo "	timeout = " $CON_TIMEOUT "s"| tee -a $RESULT_FILE
	echo "- Result" | tee -a $RESULT_FILE
	echo "	total: " $CNT ", OK: " $OK_CNT ", NG: " $NG_CNT | tee -a $RESULT_FILE
	echo "++++++++++++++++++++++++++++++++++++++++++" | tee -a $RESULT_FILE

	# 接続結果をタイムスタンプ順にソート
	LC_ALL=C
	sort $TMP_RESULT_FILE >> $RESULT_FILE

	# 一時ファイルを削除
	rm -f $TMP_RESULT_FILE
}

# 引数・オプション取得
if [ "$OPTIND" = 1 ]; then
  while getopts :c:f:i:p:t:h: OPT
  do
   case $OPT in
     c)
       CON_COUNT=$OPTARG
       ;;
     f)
       RESULT_FILE_PREFIX=$OPTARG
       ;;
     i)
       CON_INTERVAL=$OPTARG
       ;;
     p)
       CON_PORT=$OPTARG
       ;;
     t)
       CON_TIMEOUT=$OPTARG
       ;;
     h)
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


if [ "$#" -ne 2 ]; then
	echo "$#"
       _usage
fi

# 接続先IPアドレス
CON_IP=$1

# 結果出力ファイル名生成
RESULT_FILE=$RESULT_FILE_PREFIX'_'`date +"$DATE_FORMAT_FOR_FILE"`".txt"


trap "_finalize" 0

while :
do
	if [ $CON_COUNT -ne 0 -a $CNT -ge $((CON_COUNT)) ]; then
		break
	fi

	sleep "$CON_INTERVAL"s
	_con_smtp &
	(( CNT ++ ))
done



