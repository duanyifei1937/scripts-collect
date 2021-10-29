#!/usr/bin/env bash
# 脚本在remote host执行

get_file_info(){
    # 只在首次实行
    if [ ! -f "$3" ]; then
        # 判断是否存在log info file:
        echo "init file info no exist" >> $5
        find $1 -maxdepth 1 -type f | xargs ls -l --time-style=+%s | awk '{print $7, $6, $5}' >> $3
    fi

    # 间隔拉取new info
    find $1 -maxdepth 1 -type f | xargs ls -l --time-style=+%s | awk '{print $7, $6, $5}' >> $2

    # 轮询new file info
    cat $2 | while read line
    do
        file_path=`echo $line | awk '{print $1}'`
        new_file_size=`echo $line | awk '{print $NF}'`
        # 判断文件内容在之前是否存在
        if grep -q "$line" $3
        then
            # line存在，说明整行未变
            echo "$localtime $file_path no change" >> $5
        else
            # 区分file change or file create
            if grep -q "$file_path" $3
            then
                echo "$localtime $file_path exist"  >> $5

            else
                echo "$localtime $file_path new log" >> $5
                # file new create
                echo "$file_path 0 0" >> $3
            fi

            # 新文件也参数panic匹配
            # file_path存在，说明file info改变
            # 获取diff size
            file_size=`grep $file_path $3 | awk '{print $NF}'`

            echo "$localtime $file_path old_file_size: $file_size" >> $5
            echo "$localtime $file_path new_file_size: $new_file_size" >> $5


            if [ $new_file_size -gt $file_size ]
            then
                let diff_size=$new_file_size-$file_size
                echo "$localtime $file_path diff_size: $diff_size" >> $5

                # 判断追加的log有无panic
                if tail -c "$diff_size" $file_path | grep -E ' panic | panic\(|panic:|runtime error|fatal error' | grep -v '0,0' | grep -v 'registration conflicts' | grep -v 'PANIC:0' | grep -v 'INFO' | grep -v 'release will panic on' | grep -v -i 'not panic' >> /dev/null
                then
                    file_name=`echo "$file_path" | awk -F '/' '{print $NF}' | awk -F '.' '{print $(NF-1)}'`
                    echo "$file_name" >> $5
                    # 存在panic log
                    echo "$localtime $file_path" >> $4_${file_name}
                    # 追加panic 相关的上下文log
                    tail -c "$diff_size" $file_path | grep -i -E 'panic|runtime error' -A 100 | grep -E -i 'go:|panic|runtime' | grep -v 'PANIC:0' | head -35 >> $4_${file_name}
                else
                    # 不存在panic log
                    echo "$localtime $file_path new log not hava panic" >> $5
                fi
            else
                # new_size !> old_size, 适用于清空log情况，将new log info 追加到 file info;
                continue
            fi
        fi
    done
    # 删除临时存储log
    mv -f $2 $3
    # 清空exec.log, debug开启
    #echo > $5
}

localtime=`date +"%Y-%m-%d %H:%M:%S"`
log_path_data=`date +"%Y-%m-%d" -u`
# $1: log path
# $2: new log info: 作为临时存储file info;
# $3: log info
# $4: alert log
# $5: exec log
get_file_info "/data/servicelog/wread0/panic/${log_path_data}" 'new_file_info.log' 'file_info.log' 'alert.log' 'exec.log'