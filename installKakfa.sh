#!/usr/bin/env bash
set -e

# 获取局域网ip 已有函数取值用$(getIp)
function getIp() {
  ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"
}

# 下载kafka
function downKafka() {
  wget --no-check-certificate http://mirrors.ustc.edu.cn/apache/kafka/3.2.0/kafka_2.13-3.2.0.tgz -O kafka.tgz
}

# 解压kafka
function decompressKafka() {
  if [ -s $1 ]; then
    tar -zxvf kafka.tgz > tar.log
    cat tar.log|head -n 1|tr -d "/"
  fi
}

# 初始化kafka配置
function initKafkaConfig() {
  if [ -s $1 ]&&grep "localhost" $1 ; then
    sed -i "s/localhost/$(getIp)/g" $1
    echo "kafka监听地址：$(getIp):9092"
  fi
}

# 创建shell脚本
function createShell() {
# 已有函数变量取值用$()，自定义变量取值用${}
cat > ${root}/kafka-start <<EOF
${root}/$1/bin/kafka-storage.sh format -t T1CYXg2DQPmdSYSUI-FNFw -c ${root}/$1/config/kraft/server.properties
nohup ${root}/$1/bin/kafka-server-start.sh ${root}/$1/config/kraft/server.properties >kafka-without-zk.log 2>&1 &
echo "kafka启动pid:$$ kafka执行日志保存在kafka-without-zk.log"
EOF
chmod +x ${root}/kafka-start
echo "启动命令: sh ${root}/kafka-start "

cat > ${root}/kafka-stop <<EOF
${root}/$1/bin/kafka-server-stop.sh -c ${root}/$1/config/kraft/server.properties
EOF
chmod +x ${root}/kafka-stop
echo "关闭命令: sh ${root}/kafka-stop"
}

root=$(pwd)
downKafka
kafkaPackage=$(decompressKafka "${root}/kafka.tgz")
initKafkaConfig "${root}/${kafkaPackage}/config/kraft/server.properties"
createShell "${kafkaPackage}"