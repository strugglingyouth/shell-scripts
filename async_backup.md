#异地备份文件并检查完整性

客户端程序：

	#!/bin/bash
	 
	remote_host=192.168.1.27    #备份服务器ip
	remote_path=/backup           #备份服务器的备份目录
	 
	local_backup_path=/backup
	local_file_path=/usr/html
	 
	[ -d $local_backup_path ] || mkdir -p $local_backup_path 
	 
	cd ${local_file_path} && \
	tar zcf $local_backup_path/www_tianfeiyu-$(date +%F).tar.gz htdocs && \
	tar zcf $local_backup_path/www_17linux8-$(date +%F).tar.gz linux8 && \
	find /backup -type f -name "*.tar.gz" | xargs md5sum > $local_backup_path/flag_$(date +%F)
	 
	#copy file
	rsync -avz  $local_backup_path/*  $remote_host:$remote_path 
	 
	#del backup file
	find $local_backup_path -type f -name "*.tar.gz" -mtime +7 | xargs rm -f

设置定时任务：

	0 4 * * *  /bin/bash /root/shell/www_backup.sh &> /dev/null

备份服务器上运行的程序：
	
	#!/bin/bash
	 
	local_backup_path=/backup
	md5_file=flag_$(date +%F)
	 
	cd $local_backup_path 
	 
	if [ $? -eq 0 ];then
	    if [ -e $md5_file ];then
	        md5sum -c ${md5_file} >> mail.txt
	        if [ $? -eq 0 ];then
	            mail -s "Success ! The backup task is ok !" xxxxxx@qq.com < mail.txt
	        else 
	            mail -s "Failed ! The backup task is failed !" xxxxxx@qq.com < mail.txt        
	        fi  
	    else 
	        ls > mail.txt
	        mail -s "Failed ! The md5_file is not exists!" xxxxxx@qq.com < mail.txt 
	fi

定时任务：
	0 5 * * *  /bin/bash /root/shell/flag_check.sh &> /dev/null



