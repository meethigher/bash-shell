#!/usr/bin/env bash
#set -e

# 安装postgis
function installPostGis() {
  yum -y install epel-release
  yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  yum -y install postgis30_11
}

# 安装pgRouting
function installPgRouting() {
  yum -y install pgrouting_11 osm2pgrouting_11
}

# 安装postgresql
function installPsql() {
# 安装 RPM:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# 安装 PostgreSQL:
sudo yum install -y postgresql11-server
# 初始化数据库并设置开机自启动
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
sudo systemctl enable postgresql-11
# 开启远程访问
psqlConf="/var/lib/pgsql/11/data/postgresql.conf"
if [ -s ${psqlConf} ];then
  cat >> ${psqlConf} <<EOF
# 开启postgresql的远程可访问
listen_addresses = '*'
EOF
else
  echo "psql没有该配置文件${psqlConf}，可能是脚本已不适用！"
  echo "码农最伟大的地方就是能够实现他的完美！"
  exit 1
fi
pghbaConf="/var/lib/pgsql/11/data/pg_hba.conf";
if [ -s ${pghbaConf} ]; then
  cat >> ${pghbaConf} <<EOF
host all all 0.0.0.0/0 md5
EOF
else
  echo "psql没有该配置文件${pghbaConf}，可能是脚本已不适用！"
  echo "码农最伟大的地方就是能够实现他的完美！"
  exit 1
fi
sudo systemctl restart postgresql-11
}


echo "可选安装如下："
echo "postgresql              1"
echo "postgis                 2"
echo "pgrouting               3"

# 读取键盘输入信息
printf "输入你要安装的内容，不选输入n"
read -p "(Default: n):" select
# 默认赋值
[ -z "${select}" ]&&select="n"

# 安装
# 判断选项
case ${select} in
"n")
echo "本次不安装"
exit 0
;;
"1")
echo "本次安装postgresql"
installPsql
;;
"2")
echo "本次安装postgis"
installPostGis
;;
"3")
echo "本次安装pgrouting"
installPgRouting
;;
esac