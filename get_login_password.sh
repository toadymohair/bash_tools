#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++
# encrypt_login_password.sh
# Usage: save_login_password.sh login_name
# Description:
# Variables:
#  login_name   ログイン情報名。WebサイトのURlなど
#  user_name    ログインユーザ名
# Options:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++

# 定数定義
readonly RSA_KEY='/root/.ssh/id_rsa' # 暗号化用RSAキー
readonly SAVE_DIR='/root/login/'      # ログイン情報保存ディレクトリ

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

# get password
passwd_file=$SAVE_DIR$LOGIN_NAME".passwd"
openssl rsautl -decrypt -inkey $RSA_KEY -in $passwd_file

