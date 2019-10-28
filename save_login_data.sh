#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++
# encrypt_login_data.sh
# Usage: save_login_data.sh login_name user_name password
# Description:
# Variables:
#  login_name   ログイン情報を保存する名前。WebサイトのURlなど
#  user_name    ログインユーザ名
#  password     ログインパスワード
# Options:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++

# 定数定義
readonly RSA_KEY=~/.ssh/id_rsa # 暗号化用RSAキー
readonly SAVE_DIR=~/login/      # ログイン情報保存ディレクトリ

# グローバル変数
LOGIN_NAME=$1
USER_NAME=$2
PASSWORD=$3

# 使い方
function _usage() {
  cat <<_EOT_
Usage:
  $(basename ${0}) login_name user_name password
_EOT_
  exit 1
}

if [ "$#" -ne 3 ]; then
  echo "$#"
       _usage
fi

# save username
uname_file=$SAVE_DIR$LOGIN_NAME".user"
echo $USER_NAME > $uname_file
chmod 600 $uname_file

# save password
passwd_file=$SAVE_DIR$LOGIN_NAME".passwd"
echo $PASSWORD | openssl rsautl -encrypt -inkey $RSA_KEY > $passwd_file
chmod 600 $passwd_file

