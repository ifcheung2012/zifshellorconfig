#!/bin/sh

#curl https://j.mp/spf13-vim3 -L > spf13-vim.sh && sh spf13-vim.sh

mysqlbase=/usr/local/mysql

dbsuper='root'
dbrootpwd='123456'
db='ifcheung'

isrmSetupPkg=1

instancePort='3307'

if [ `whoami` != 'root' ]; then
    echo "you must run this script as root!!!!!!`whoami`"
    exit 1
fi

installdb()
{
	echo "#######this script will download mysql and self config,and then make && make install mysql"
	sleep 2
	groupadd mysql
	useradd -s /sbin/nologin -g mysql -M mysql
	mkdir ~/tools
	cd ~/tools
	tail -l /etc/passwd
	sleep 5
	wget http://mysql.ntu.edu.tw/Downloads/MySQL-5.1/mysql-5.1.62.tar.gz
	tar zxf mysql-5.1.62.tar.gz

	cd mysql-5.1.62/
	
	./configure --prefix=/usr/local/mysql --with-unix-socket-path=$mysqlbase/tmp/mysql.sock --localstatedir=$mysqlbase/data --enable-assembler --enable-thread-safe-client --with-mysqld-user=mysql --with-big-tables --without-debug --with-pthread --enable-assembler --with-extra-charsets=complex --with-readline --with-ssl --with-embedded-server --enable-local-infile --with-plugins=partition,innobase --with-plugin-PLUGIN
	make 
	make install
	
	[ $? -eq 0 ] || exit 1 
	chown -R mysql $mysqlbase
	echo "#######succeed install mysql"
}

rmsetuppkg()
{
    if [ $isrmSetupPkg -eq 1 ]; then
        /bin/rm -rf  ~/tools/*  
        [ $? -eq 0 ] || exit 1 
        echo "####all setup source packages has been removed!!!####"
    else
        echo "###no need to remove setup source packages#####"
    fi
    
}

configDb() {
	echo "########init default mysql config  #####################"
	sleep 2
	echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile

	cd ~/tools
	wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/mysql/mysqld
	/bin/mv mysqld /etc/init.d/
	chmod 755 /etc/init.d/mysqld
	

	wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/mysql/my.cnf
    chmod 755 my.cnf
    /bin/mv my.cnf /etc/

    cd $mysqlbase
    mkdir data
    chown -R mysql data

    $mysqlbase/bin/mysql_install_db --datadir="/usr/local/mysql/data" --user=mysql

	[ $? -eq 0 ] || exit 1
	echo "#######succeed config primary mysql"
	sleep 2
}






startNinitDB() {
	echo "#######start..mysql...and initial   database. ;and remove verbose users.##########."
	sleep 1
	/etc/init.d/mysqld start
	echo "#######initial mysql root password...."
	sleep 5
	$mysqlbase/bin/mysqladmin -u root  password $dbrootpwd
	[ $? -eq 0 ] || exit 1
	$mysqlbase/bin/mysql -u root -p123456 -e "create database $db"
	$mysqlbase/bin/mysql -u root -p123456 -e "drop database test;delete from mysql.user where user='';"
	
	[ $? -eq 0 ] || exit 1
	echo "#######ok succeed initial database"
	sleep 3
}

configDbinstance() {
	echo "########init  mysql second instance config  #####################"
	mkdir -p /data/mysql/${instancePort}/data
	cd /data/mysql/${instancePort}/

	wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/mysql/instance/my.cnf
    wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/mysql/instance/mysqld
    chmod 755 my.cnf mysqld
	chown -R mysql /data
	chmod u+x mysqld
	sed -i "s/mysql_user=/mysql_user=${dbsuper}/g"  mysqld
	sed -i "s/mysql_pwd=/mysql_pwd=${dbrootpwd}/g"  mysqld


	$mysqlbase/bin/mysql_install_db --datadir="/data/mysql/${instancePort}/data/"
	
	[ $? -eq 0 ] || exit 1 
	echo "#######succeed config second mysql instance!!"
	sleep 3
}

configPython() {
	echo "########### initial python package config######"
	sleep 2
	echo y | apt-get install python-pip python-mysqldb
	pip install tornado sqlalchemy mako
	[ $? -eq 0 ] || exit 1
	echo "#######ok succeed initial python package config"
	sleep 3
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
	make install
	[ $? -eq 0 ] || exit 1
	

	wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/redis/redis-server
	wget https://raw.github.com/ifcheung2012/zifshellorconfig/master/vmScripts4VM/koding/redis/redis.conf
	mv redis-server /etc/init.d/redis-server
	chmod ug+x /etc/init.d/redis-server 
	mv redis.conf /etc/redis.conf
	useradd redis
	mkdir -p /var/{log,lib}/redis

	chown redis.redis /var/{log,lib}/redis

	update-rc.d redis-server defaults
	
    
	which redis-cli

	echo "#######ok succeed install redis"
}

echo "##some problems like this:http://www.binghe.org/2012/05/mysql-error-couldnot-find-mysql-manager-or-server/"

installdb
rmsetuppkg
configDb
startNinitDB
configDbinstance
configPython
initialWebpath
installRedis

echo "#######all packages has been installed,pls check###"
