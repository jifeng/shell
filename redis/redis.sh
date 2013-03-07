#!/bin/bash
if [ `echo $OSTYPE | grep -c 'darwin'` -eq 1 ]; then
	ME=`stat -f "%Y" $0`
	if [ "1$ME" == "1" ]; then
		ME=$0
	fi
elif [ `echo $OSTYPE | grep -c 'linux'` -eq 1 ]; then
	ME=`readlink -f $0`
else
	echo 'not support'
	exit 1;
fi

code_dir=$(cd "$(dirname "$ME")"; pwd)
cd $code_dir

if [ "1$2" == "1" ]; then
	cmd='help'
else
	cmd=$2
fi

port=$1

PATH=$PWD/bin/:$PATH
bin_server='/usr/bin/env redis-server'
bin_client='/usr/bin/env redis-cli'
conf='redis.conf'
if [ $(basename $PWD) == 'dxpredis' ]; then
	dir=`echo $PWD | sed 's/\//\\\\\//g'`
elif [ "$USER" == "admin" -o "$USER" == "dxpwebtest" -o "$USER" == "dxpwebbuild" ]; then
	dir=`echo $(dirname $(dirname $(dirname $PWD)))/redis | sed 's/\//\\\\\//g'`
else
	dir=`echo $PWD | sed 's/\//\\\\\//g'`
fi
 # -o $USER -eq "dxpwebtest" -o $USER -eq "dxpwebbuild" ]

password=`cat $conf | sed "s/#PWD#/$dir/g" | sed "s/#PORT#/$port/g" | grep '^requirepass' | cut -f 2 -d "'"`
db_dir=`cat $conf | sed "s/#PWD#/$dir/g" | sed "s/#PORT#/$port/g" | grep '^dir' | cut -f 2 -d " "`
pid_file=`cat $conf | sed "s/#PWD#/$dir/g" | sed "s/#PORT#/$port/g" | grep '^pidfile' | cut -f 2 -d " "`
pid_dir=$(dirname $pid_file)

shift 2

check_pid() {
	if [ -f $pid_file ]; then
		pid=`cat $pid_file`
	else
		return 1
	fi
	if [ `ps -A -o 'pid' | grep -c "^ *$pid"` -eq 1 ]; then
		return 0
	fi
	return 2
}

start() {
	check_pid;
	if [ $? -eq 0 ]; then
		echo "Redis is running.";
		return 11;
	fi
	mkdir -p $db_dir >/dev/null 2>&1
	mkdir -p $pid_dir >/dev/null 2>&1

	echo -n "Redis start."
	cat $conf | sed "s/#PWD#/$dir/g" | sed "s/#PORT#/$port/g" | $bin_server -

	for ((i=0; i<20; i++)); do
		check_pid;
		if [ $? -eq 0 ]; then
			echo
			echo "started."
			return 0
		fi
		echo -n '.'
		sleep 0.5
	done
	echo ''
	echo "Start Redis Timeout."
	return 3
}

stop() {
	check_pid;
	if [ $? -ne 0 ]; then
		echo "Redis is not running.";
		return 21;
	fi

	echo -n "Redis stop."

	$bin_client -a "$password" SHUTDOWN NOSAVE

	for ((i=0; i<20; i++)); do
		check_pid;
		if [ $? -ne 0 ]; then
			echo
			echo "Stopped."
			return 0
		fi
		echo -n '.'
		sleep 0.5
	done
	echo ''
	echo "Stop Redis Timeout."
	return 3
}

cmd(){
	check_pid;
	if [ $? -ne 0 ]; then
		echo "Redis is not running.";
		return 31;
	fi
	$bin_client -a "$password" $*
	return $?
}

status(){
	cmd INFO;
	return $?
}

help() {
	echo "Usage: $0 listen_port start|stop|restart|status|cmd|help [redis_cmds]"
}

case $cmd in
	start)
		start;
		exit $?;
	;;
	stop)
		stop;
		exit $?;
	;;

	restart)
		stop;
		start;
		exit $?;
	;;
	status)
		status;
		exit $?;
	;;
	cmd)
		cmd $*;
		exit $?;
	;;
	help)
		help;
		exit 0;
	;;
	*)
		help;
		exit 0;
	;;
	esac
