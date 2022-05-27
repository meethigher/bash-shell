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