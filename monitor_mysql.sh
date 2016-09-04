#!/bin/bash
#
#check_mysql_slave_replication_status
#
#
#
parasum=2
help_msg(){
 
cat << help
+---------------------+
+Error Cause:
+you must input $parasum parameters!
+1st : Host_IP
+2st : Host_Port
help
exit 
}
 
[ $# -ne ${parasum} ] && help_msg  #若参数不够打印帮助信息并退出
 
export HOST_IP=$1
export HOST_PORt=$2
MYUSER="root"           
MYPASS="123456"
 
MYSQL_CMD="mysql -u$MYUSER -p$MYPASS"
MailTitle=""                #邮件主题
Mail_Address_MysqlStatus="root@localhost.localdomain"   #收件人邮箱    
 
time1=$(date +"%Y%m%d%H%M%S")
time2=$(date +"%Y-%m-%d %H:%M:%S")
 
SlaveStatusFile=/tmp/salve_status_${HOST_PORT}.${time1}   #邮件内容所在文件
echo "--------------------Begin at: "$time2 > $SlaveStatusFile
echo "" >> $SlaveStatusFile
 
#get slave status
${MYSQL_CMD} -e "show slave status\G" >> $SlaveStatusFile #取得salve进程的状态
 
#get io_thread_status,sql_thread_status,last_errno   取得以下状态值
 
IOStatus=$(cat $SlaveStatusFile|grep Slave_IO_Running|awk '{print $2}')
SQLStatus=$(cat $SlaveStatusFile|grep Slave_SQL_Running |awk '{print $2}')
    Errno=$(cat $SlaveStatusFile|grep Last_Errno | awk '{print $2}')
   Behind=$(cat $SlaveStatusFile|grep Seconds_Behind_Master | awk '{print $2}')
 
echo "" >> $SlaveStatusFile
 
if [ "$IOStatus" == "No" ] || [ "$SQLStatus" == "No" ];then   #判断错误类型
       if [ "$Errno" -eq 0 ];then   #可能是salve线程未启动
            $MYSQL_CMD -e "start slave io_thread;start slave sql_thread;"
            echo "Cause slave threads doesnot's running,trying start slsave io_thread;start slave sql_thread;" >> $SlaveStatusFile
            MailTitle="[Warning] Slave threads stoped on $HOST_IP $HOST_PORT"
        elif [ "$Errno" -eq 1007 ] || [ "$Errno" -eq 1053 ] || [ "$Errno" -eq 1062 ] || [ "$Errno" -eq 1213 ] || [ "$Errno" -eq 1032 ]\
            || [ "Errno" -eq 1158 ] || [ "$Errno" -eq 1159 ] || [ "$Errno" -eq 1008 ];then  #忽略此些错误
            $MYSQL_CMD -e "stop slave;set global sql_slave_skip_counter=1;start slave;"
            echo "Cause slave replication catch errors,trying skip counter and restart slave;stop slave ;set global sql_slave_skip_counter=1;slave start;" >> $SlaveStatusFile
            MailTitle="[Warning] Slave error on $HOST_IP $HOST_PORT! ErrNum: $Errno"
        else
            echo "Slave $HOST_IP $HOST_PORT is down!" >> $SlaveStatusFile
            MailTitle="[ERROR]Slave replication is down on $HOST_IP $HOST_PORT ! ErrNum:$Errno"
        fi
fi
if [ -n "$Behind" ];then 
        Behind=0
fi
echo "$Behind" >> $SlaveStatusFile
 
#delay behind master 判断延时时间
if [ $Behind -gt 300 ];then
    echo `date +"%Y-%m%d %H:%M:%S"` "slave is behind master $Bebind seconds!" >> $SlaveStatusFile
    MailTitle="[Warning]Slave delay $Behind seconds,from $HOST_IP $HOST_PORT"
fi
 
if [ -n "$MailTitle" ];then  #若出错或者延时时间大于300s则发送邮件
        cat ${SlaveStatusFile} | /bin/mail -s "$MailTitle" $Mail_Address_MysqlStatus
fi
 
#del tmpfile:SlaveStatusFile
> $SlaveStatusFile