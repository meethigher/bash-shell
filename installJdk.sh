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