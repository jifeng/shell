#!/bin/bash

# Custom the application name, this is managing the mongodb
PROJECT_NAME="manage_mongodb"

#check wheter the user is admin
checkuser() {
  user=`id -nu`
  if [ ${user} != 'admin' ]
  then
    echo "Stop! Only admin can run this script!"
    exit 3
  fi
}

PROG_NAME=$0
ACTION=$1

# tell the user how to use the shell script 
usage() {
  echo "Usage: $PROG_NAME {start|stop|status|restart}"
  exit 1;
}

checkuser

if [ $# -lt 1 ]; then
  usage
fi

#get process id
function get_pid {
  # for example
  #PID=`ps ax | grep /home/admin/apps/mongodb/bin/mongod | grep u01/data/meta_datacube/data | awk '{print $1}'`
}


    
start()
{
   get_pid
   if [ -z $PID ]; then
      echo "Starting $PROJECT_NAME ..."
      # start mongodb
      # for example
      #nohup /home/admin/apps/mongodb/bin/mongod --dbpath=/u01/data/meta_datacube/data -port 9999 --logpath=/home/admin/logs/mongo_logs/mongo_log.log > /home/admin/logs/mongo_logs/mongo_log_manage.log & 
      get_pid
      echo "Done. PID=$PID"
   else
      echo "$PROJECT_NAME is already running, PID=$PID"
   fi
}

stop()
{
  get_pid
  if [ ! -z "$PID" ]; then
    echo "Please wait $PROJECT_NAME stop for 5s ..."
    kill -s SIGTERM $PID
    sleep 5
    # store the log before
    #mv -f /home/admin/logs/mongo_logs/mongo_log_manage.log "/home/admin/logs/mongo_logs/mongo_log_manage.log.`date '+%Y%m%d%H%M%S'`"
  else
    echo "$PROJECT_NAME is not running"
  fi
}

status()
{
  get_pid
  if [ ! -z $PID ]; then
    echo "PID: $PID"
    ps -ef | grep $PID
  else
    echo "$PROJECT_NAME is not running"
  fi
}


case "$ACTION" in
  start)
    start
  ;;
  status)
	  status
  ;;
  stop)
      stop
  ;;
  restart)
    stop
    start
  ;;
  *)
    usage
  ;;
esac
