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