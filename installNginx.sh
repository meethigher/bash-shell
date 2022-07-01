#!/usr/bin/env bash
# 参考1：[LINUX安装nginx详细步骤_大蛇王的博客-CSDN博客_linux安装nginx](https://blog.csdn.net/t8116189520/article/details/81909574)
# 参考2：[CentOS7设置nginx开机自启动 - 简书](https://www.jianshu.com/p/ca5ee5f7075c)


set -e

appname="nginx1.22.0"


# 下载nginx
function downloadNginx() {
  yum -y install wget gcc zlib zlib-devel pcre-devel openssl openssl-devel
  wget --no-check-certificate https://nginx.org/download/nginx-1.22.0.tar.gz -O nginx.tgz
}

# 解压nginx
function decompressNginx() {
    if [ -s $1 ]; then
    tar -zxvf $1 > tar.log
    cat tar.log|head -n 1|tr -d "/"
  fi
}

# 编译nginx
function makeNginx() {
  cd $1
  # 执行命令 考虑到后续安装ssl证书 添加两个模块
  ./configure --with-http_stub_status_module --with-http_ssl_module
  # 执行make命令
  make
  # 执行make install命令
  make install
}

# 配置nginx环境变量
function configNginx() {
  if [ -s $1 ]; then
    cat > /usr/lib/systemd/system/nginx.service <<EOF
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=$1
ExecReload=$1 -s reload
ExecStop=$1 -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  fi
}
root=$(pwd)
downloadNginx
package=$(decompressNginx "${root}/nginx.tgz")
makeNginx ${package}
configNginx "/usr/local/nginx/sbin/nginx"

echo "nginx安装成功 版本号1.22.0"
echo "nginx运行命令："
echo "--启动/关闭/重启: systemctl start|stop|restart nginx"
echo "--自启动/非自启动: systemctl enable|disable nginx"