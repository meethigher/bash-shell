**以下脚本均为原创，在实际工作中总结而出的！**

# 一、初始化

安装常用命令，像ifconfig、zip、unzip、wget、vim、yum-plugin-downloadonly

```sh
#!/usr/bin/env bash

set -e
# 更换yum源，参考[centos镜像-centos下载地址-centos安装教程-阿里巴巴开源镜像站](https://developer.aliyun.com/mirror/centos)
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 基础repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# 备用repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 清空旧缓存、生成新缓存
yum clean all
yum makecache

yum -y install net-tools vim zip unzip wget yum-plugin-downloadonly

echo "更换yum base、epel源为阿里repo"
echo "安装常用工具"
```

# 二、一键脚本

### 2.1 vsftpd

一键安装vsftpd

```sh
#!/usr/bin/env bash

# 安装vsftp
installVsftpd() {
  yum -y install vsftpd ftp
  status=$?
  if [ ${status} != 0 ]; then
    echo "请检查是否能连接网络 or 是否能连接到yum仓库 or 强制退出"
    exit 1
  fi
  # >表示覆盖 >>表示追加
  cat >> /etc/vsftpd/vsftpd.conf <<EOF
#FTP访问目录
local_root=/data/ftp/
# 配置只能访问指定目录，chroot_list文件中列出的用户，可以切换到其他目录；未在文件中列出的用户，不能切换到其他目录。
chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
allow_writeable_chroot=YES
# 配置时区
use_localtime=YES
EOF
  mkdir -p /etc/vsftpd/chroot_list
  mkdir -p /data
  useradd -d /data/ftp/ ftpadmin
  chown -R ftpadmin /data/ftp
  systemctl restart vsftpd
  echo "vsftpd安装成功"
  echo "通过 systemctl [status|start|stop|restart|enable|disable] vsftpd 进行操作"
  echo "成功创建用户ftpadmin，通过 passwd ftpadmin 进行配置密码"
}

# 关闭selinux
disableSeLinux(){
  # -s file　文件大小非0时为真
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    # 将SELINUX=enforcing更换为SELINUX=disabled
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    echo "关闭selinux"
  fi
}


ls /usr/lib/systemd/system/vsftpd.service
status=$?
# 0表示找到了服务 非0表示没有服务 判断相等带空格
if [ $status == 0 ]; then
  echo "vsftpd安装成功"
  echo "通过 systemctl [status|start|stop|restart|enable|disable] vsftpd进行操作"
else
  disableSeLinux
  installVsftpd
fi
```

之后通过如下命令，配置密码。

```sh
passwd ftpadmin
```

然后就可以直接连接了。

```sh
# 连接
ftp 127.0.0.1
# 上传
put 本地文件 远程文件
```

![](https://meethigher.top/blog/2022/onekey-shell/1.jpg)

### 2.2 openjdk

一键安装jdk11

```java
#!/user/bin/env bash
set -e

# 安装jdk 参数为jdk版本
function installJdk() {
yum -y install java-$1-openjdk java-$1-openjdk-devel
cat > /etc/profile.d/java$1.sh <<EOF
# readlink读取到javac软连接，再读取软连接获取到真实链接，然后往上级目录走两次，走一次是java/bin，再走一次是java
export JAVA_HOME=\$(dirname \$(dirname \$(readlink \$(readlink \$(which javac)))))
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
EOF
# 刷新环境变量
source /etc/profile.d/java$1.sh

java -version
javac -version
echo $JAVA_HOME
}

echo "可选java-openJdk版本如下："
echo "java-1.8.0-openjdk              1"
echo "java-11-openjdk                 2"
printf "输入你要安装的openJdk版本"
# 读取键盘输入信息
read -p "(Default: 1):" select
# 默认赋值
[ -z "${select}" ]&&select=1

# 判断选项
if [ "${select}" == 1 ];then
  select="1.8.0"
else
  select="11"
fi
installJdk ${select}
```

### 2.3 mongo

一键安装mongo4.4.14

```sh
#!/usr/bin/env bash
set -e
# >全覆盖写入 \可以进行转义
cat > /etc/yum.repos.d/mongodb-org-4.4.repo <<EOF
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

yum install -y mongodb-org-4.4.14 mongodb-org-server-4.4.14 mongodb-org-shell-4.4.14 mongodb-org-mongos-4.4.14 mongodb-org-tools-4.4.14

if [ -s /etc/mongod.conf ] && grep '127.0.0.1' /etc/mongod.conf; then
   sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
fi

systemctl restart mongod
echo "=================================================================================================================================="
echo "mongo数据库已经启动，命令行输入mongo即可连接"
```

### 2.4 kafka

一键安装kafka

```sh
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
```

### 2.5 postgresql

一键安装psql

```sh
#!/usr/bin/env bash
set -e

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
```

### 2.6 history显示时间

临时添加环境变量history带时间

```sh
export HISTTIMEFORMAT='%F %T '
```

临时取消环境变量

```sh
unset HISTTIMEFORMAT
```

查看环境变量

```sh
env
```

# 三、致谢

[shell中 set 指令的用法_曹灰灰的博客-CSDN博客_set shell](https://blog.csdn.net/cao0507/article/details/82697451)

[强大的一键部署网站架构工具Oneinstack_延瓒@yankerp的博客-CSDN博客_oneinstack](https://blog.csdn.net/qq_39591494/article/details/106594674)

[fengyuhetao/shell: Linux命令行与shell脚本编程大全案例](https://github.com/fengyuhetao/shell)

[hi-dhl/fast_guides: 10分钟入门Shell脚本编程](https://github.com/hi-dhl/fast_guides)

[在IDEA编写Shell脚本_1024GB的博客-CSDN博客_idea编写shell脚本](https://blog.csdn.net/weixin_45831807/article/details/122136038)

[Linux Shell脚本参数传递的2种方法_残风乱了温柔的博客-CSDN博客_shell脚本传递参数命令](https://blog.csdn.net/fitaotao/article/details/123584335)

[Linux shell条件判断if中的-a到-z的意思 - 简书](https://www.jianshu.com/p/fd2b058bedba)

[shell脚本中$0 $1 $# $@ $* $? $$ 的各种符号意义详解 - 一口Linux - 博客园](https://www.cnblogs.com/yikoulinux/p/15387440.html)

[shell local命令_qq_28391549的博客-CSDN博客_local命令](https://blog.csdn.net/qq_28391549/article/details/79202417)

[shell命令之 tr_不是杠杠的博客-CSDN博客_shell命令tr](https://blog.csdn.net/weixin_40026739/article/details/120525293)

[Linux - Shell 脚本中获取本机 ip 地址方法_栗少的博客-CSDN博客_linux获取ip地址shell](https://blog.csdn.net/weixin_38556197/article/details/121134600)

[centos 7 查看所有登录用户的操作历史_代码浪人的博客-CSDN博客_centos7查看登录记录](https://blog.csdn.net/huiguo_/article/details/119682429)

[linux shell中'',""和\`\`的区别 其实\`\`跟$()作用一样](https://blog.csdn.net/lisulong1/article/details/79109296)

[Linux shell 中$() \`\`，${}作用与区别_ai_xiangjuan的博客-CSDN博客_linux shell {}](https://blog.csdn.net/ai_xiangjuan/article/details/82082391)

[liunx 中如何删除export设置的环境变量_weixin_33775582的博客-CSDN博客](https://blog.csdn.net/weixin_33775582/article/details/93513620)

[history 命令带时间显示 - 简书](https://www.jianshu.com/p/1c549a16b57c)


[Linux Shell系列教程之（十三）Shell分支语句case … esac教程 - 走看看](http://t.zoukankan.com/waitig-p-5868332.html)

[Linux Shell case语句_zh521zh的博客-CSDN博客](https://blog.csdn.net/zh521zh/article/details/52232391)

[Linux shell脚本 （十二）case语句_青豆1113的博客-CSDN博客](https://blog.csdn.net/qq_31811537/article/details/81782917)