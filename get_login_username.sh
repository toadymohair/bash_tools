#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++
# get_login_username.sh
# Usage: get_login_username.sh login_name
# Description:
# Variables:
#  login_name   ログイン情報名。WebサイトのURlなど
# Options:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++

# 定数定義
readonly RSA_KEY=~/.ssh/id_rsa # 暗号化用RSAキー
readonly SAVE_DIR=~/login/     # ログイン情報保存ディレクトリ

# グローバル変数
LOGIN_NAME=$1

# 使い方
function _usage() {
  cat <<_EOT_
Usage:
  $(basename ${0}) login_name
_EOT_
  exit 1
}

if [ "$#" -ne 1 ]; then
 _usage
fi

# get username
uname_file=$SAVE_DIR$LOGIN_NAME".user"
cat $uname_file
