#!/bin/sh

#curl https://j.mp/spf13-vim3 -L > spf13-vim.sh && sh spf13-vim.sh

passwd='auditor_1982'

db='ifcheung'
dbsuper='root'
dbrootpwd='123456'


installdb()
{
	echo "this script will download mysql and self config,and then make && make install mysql"
	sleep 2
	echo $passwd | sudo -S groupadd mysql
	echo $passwd | sudo -S useradd -s /sbin/nologin -g mysql -M mysql
	mkdir ~/tools
	cd ~/tools
	tail -l /etc/passwd
	wget http://mysql.ntu.edu.tw/Downloads/MySQL-5.1/mysql-5.1.62.tar.gz
	tar zxf mysql-5.1.62.tar.gz

	cd mysql-5.1.62/

	./configure --prefix=/usr/local/mysql --with-unix-socket-path=/usr/local/mysql/tmp/mysql.sock --localstatedir=/usr/local/mysql/data --enable-assembler --enable-thread-safe-client --with-mysqld-user=mysql --with-big-tables --without-debug --with-pthread --enable-assembler --with-extra-charsets=complex --with-readline --with-ssl --with-embedded-server --enable-local-infile --with-plugins=partition,innobase --with-plugin-PLUGIN
	make
	echo $passwd | sudo -S make install

	[ $? -eq 0 ] || exit 1
	echo $passwd | sudo -S chown -R mysql /usr/local/mysql
	echo "succeed install mysql"
}


configDb() {
	echo "########init default mysql config  #####################"
	sleep 2
	cd /tmp
	echo $passwd | sudo cp /etc/profile ~
	echo $passwd | sudo chmod 777 profile
	echo "export PATH=$PATH:/usr/local/mysql/bin" >> profile
	echo $passwd | sudo chmod 644 profile
	echo $passwd | sudo /bin/mv profile /etc/

	wget https://github.com/ifcheung2012/zifshellorconfig/blob/master/vmScripts4VM/koding/mysql/mysqld
	echo $passwd | sudo -S mv mysqld /etc/init.d/
	echo $passwd | sudo -S chmod 755 /etc/init.d/mysqld
	[ $? -eq 0 ] || exit 1
	echo "succeed config mysql"
}



configDbinstance() {
	echo $passwd | sudo -S mkdir -p /data/mysql/3306/data

	cd /data/mysql/3306/
	wget https://github.com/ifcheung2012/zifshellorconfig/blob/master/vmScripts4VM/koding/mysql/instance/my.cnf
	wget https://github.com/ifcheung2012/zifshellorconfig/blob/master/vmScripts4VM/koding/mysql/instance/mysqld
	echo $passwd | sudo chmod 755 my.cnf mysqld

	echo $passwd | sudo chown -R mysql /data
	echo $passwd | sudo sed -i "s/mysql_user=/mysql_user=${dbsuper}/g"  mysqld
	echo $passwd | sudo sed -i "s/mysql_pwd=/mysql_pwd=${dbrootpwd}/g"  mysqld


	echo $passwd | sudo -S chown -R mysql mysqld
	echo $passwd | sudo -S chmod u+x mysqld
	echo $passwd | sudo -S /usr/local/mysql/bin/mysql_install_db --datadir='/data/mysql/3306/data/'

	[ $? -eq 0 ] || exit 1
	echo "succeed config mysql"
}


startNinitDB() {
	echo "start..mysql...and initial   database. ;and remove verbose users.."
	sleep 1
	echo $passwd | sudo -S /etc/init.d/mysqld start
	echo "initial mysql root password...."

	mysqladmin -u root password $dbrootpwd
	[ $? -eq 0 ] || exit 1
	mysql -u root -p123456 -e "create database $db"
	mysql -u root -p123456 -e "drop database test;delete from mysql.user where user='';"

	[ $? -eq 0 ] || exit 1
	echo "ok succeed initial database"
}



configPython() {
	echo "########### initial python package config######"
	sleep 2
	echo $passwd | sudo -S apt-get install python-pip python-mysqldb
	echo $passwd | sudo -S pip install tornado sqlalchemy mako
	[ $? -eq 0 ] || exit 1
	echo "ok succeed initial python package config"
}

initialWebpath() {
	sleep 1
}

installRedis() {
	echo "############# install redis ####################"
	cd ~/tools/
	wget http://redis.googlecode.com/files/redis-2.2.13.tar.gz
	tar -zxf redis-2.2.13.tar.gz
	cd redis-2.2.13/
	make
	echo $passwd | sudo -S make install
	[ $? -eq 0 ] || exit 1

	#cp redis.conf /etc/
	#cp redis-benchmark redis-cli redis-server /usr/bin/
	#启动服务并验证：
	#redis-server /etc/redis.conf

	wget https://github.com/ijonas/dotfiles/raw/master/etc/init.d/redis-server
	wget https://github.com/ijonas/dotfiles/raw/master/etc/redis.conf
	echo $passwd | sudo -S mv redis-server /etc/init.d/redis-server
	echo $passwd | sudo -S chmod ug+x /etc/init.d/redis-server
	echo $passwd | sudo -S mv redis.conf /etc/redis.conf
	echo $passwd | sudo -S useradd redis
	echo $passwd | sudo -S mkdir -p /var/{log,lib}/redis

	echo $passwd | sudo -S chown redis.redis /var/{log,lib}/redis

	echo $passwd | sudo -S update-rc.d redis-server defaults


	which redis-cli

	echo "ok succeed install redis"
}


installdb
configDb
startNinitDB
configPython
initialWebpath
installRedis



