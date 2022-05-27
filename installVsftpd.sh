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
