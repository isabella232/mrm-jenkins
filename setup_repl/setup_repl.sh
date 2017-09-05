#!/bin/bash

set -x

export node_N=4

x=`expr $node_N - 1`
for i in $(seq 0 $x)
do
        num=`printf "%03d" $i`
        sshkey_var=node_"$num"_keyfile
        user_var=node_"$num"_whoami
        IP_var=node_"$num"_network

        sshkey=${!sshkey_var}
        user=${!user_var}
        IP=${!IP_var}

	ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP "sudo service mysql stop" 
	sleep 5
	ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP 'sudo sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf'
	ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP 'sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/usr.sbin.mysqld; sudo service apparmor restart'

	ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP "sudo mysql_install_db; sudo chown -R mysql:mysql /var/lib/mysql"
	ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP "sudo service mysql start" 

	sleep 15
        scp -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/mrm-jenkins/setup_repl/create_*_user.sql $user@$IP://home/$user/
        ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP "sudo mysql < /home/$user/create_repl_user.sql"
        ssh -i $sshkey -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$IP "sudo mysql < /home/$user/create_skysql_user.sql"
done


for i in $(seq 1 $x)
do
        num=`printf "%03d" $i`
        IP_var=node_"$num"_network
        IP=${!IP_var}

	echo "CHANGE MASTER TO MASTER_HOST='$node_000_network',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_PORT=3306,MASTER_USE_GTID=Slave_pos; START SLAVE;" | mysql -uskysql -pskysql -P 3306 -h $IP 
	if [ $? != 0 ] ; then
		echo "Error configuring slave, node_$num"
		exit 1
	fi
done
