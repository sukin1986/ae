#!/bin/sh
################################################################################
##0.平台兼容处理
################################################################################
#1.计算字符串长度 -- Darwin:苹果系统
function length
{
if [ $(uname) = "Darwin" ];then
awk -v str="$1" 'BEGIN{print length(str)}'
else
expr length "$1"
fi
}

#2.获取系统ip
function getip
{
local t1=""
t1=$(who am i|awk '{print $NF}'|sed 's/(//'|sed 's/)//')
if [ $(echo "$t1"|awk -F. '{print NF}') -ne 4 ];then
t1=$(ifconfig en1|awk '{if($1=="inet"){print $2}}'|head -1|sed 's/ //g')
fi
if [ $(echo "$t1"|awk -F. '{print NF}') -ne 4 ];then
t1=$(ifconfig en0|awk '{if($1=="inet"){print $2}}'|head -1|sed 's/ //g')
fi
if [ $(echo "$t1"|awk -F. '{print NF}') -ne 4 ];then
t1="0.0.0.0"
fi
echo "$t1"
}
################################################################################
##1.全局变量 -- 第1栏必须配置,第2栏可选配置
################################################################################
#1.部署环境信息配置:脚本文件存放位置 -- 部署的时候只需要修改这里即可 -- t_toolmode:ip/session
t_basedir=$HOME/priv
t_tooldir=$t_basedir/zsp/shbin
t_toolmode=session
t_admin=zhangsuping
t_rm=/bin/rm
################################################################################
t_dbname=root
t_dbpass=free2016
t_dbsid=ssms
################################################################################
t_name=$t_tooldir/autoeasy.sh
u_zfile=$t_tooldir/autoeasy.txt
t_zfile=$t_tooldir/.autoeasy.txt
################################################################################
if [ ! -f "$u_zfile" ];then >$u_zfile; fi
if [ ! -f "$t_zfile" ];then >$t_zfile; fi

t_today=$(date +%Y%m%d)
t_current=$(date +%Y%m%d%H%M%S)
u_srcip=$(getip)
u_sessionid=$(who am i|awk '{print $2}')
if [ "$t_toolmode" != "session" ];then t_toolmode="ip"; fi

#校验全局变量.
if [ ! -d $t_tooldir ];then echo "$t_tooldir is not exist!"; exit 0; fi
if [ ! -f $t_rm      ];then echo "rm exec file not exist! "; exit 0; fi

#3.用户运行模式:0-普通运行模式,1-指定非本人用户模式,2-登录本人模式. -- session模式下0表示未绑定用户,2表示已绑定用户 -- 最后一条记录确定工作用户
t_usemode="0"
if [ "$t_toolmode" = "session" ];then
u_srcid="$u_sessionid"
else
u_srcid="$u_srcip"
fi
u_stat=$(sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#:"|awk '$1=="'$t_today'" && $3=="'$u_srcid'" '|tail -1|awk '{print $5}')
if [ "$u_stat" = "1" ];then
  u_srcip=$(sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#:"|awk '$1=="'$t_today'" && $3=="'$u_srcid'"'|tail -1|awk '{print $4}')
  t_usemode="2"
fi
if [ "$1" = "user" -a $# -ge 2 -a "$2" != "modify" -a "$2" != "login" -a "$2" != "new" -a "$2" != "out" ];then
  u_srcip2=$u_srcip
  if [ "$2" = "self" ];then
    u_loginstring=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$1=="'$u_srcip2'"'|tail -1)
  else
    u_loginstring=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$3=="'$2'"'|tail -1)
  fi
  if [ "$u_loginstring" = "" ];then echo "err!74:user not exist!1[$2]"; exit 1; fi
  if [ "$t_toolmode" = "session" ];then
    if [ $# -eq 2 -a "$t_usemode" != "0" ];then echo $u_loginstring|awk '{printf "%s %s %s xxxxxx %s %s\n",$1,$2,$3,$5,$6}'; fi
    if [ $# -eq 2 -a "$t_usemode" != "0" -a "$2" = "self" ];then exit 0; fi
  else
    if [ $# -eq 2 ];then echo $u_loginstring|awk '{printf "%s %s %s xxxxxx %s %s\n",$1,$2,$3,$5,$6}'; exit 0; fi
  fi
  u_srcip=$(echo  "$u_loginstring"|awk '{print $1}')
  if [ "$u_srcip" != "$u_srcip2" ];then
    t_usemode="1"
  fi
  if [ $# -gt 2 ];then
    shift
    shift
  fi
fi

#4.获取用户id及登陆信息
if [ $(length "$u_srcip") -eq 15 ];then
u_ipstring=$(echo "$u_srcip"|awk -F. '{printf "%04d%02d%02d%04d",$1,$2,$3,$4}')
else
u_ipstring=$(echo "$u_srcip"|awk -F. '{printf "%03d%03d%03d%03d",$1,$2,$3,$4}')
fi
if [ $(length "$u_ipstring") -ne 12 ];then
echo "err!118:serious sys err!"
exit 1
fi

if [ -f $u_zfile ];then
  u_loginstring=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$2=="'$u_ipstring'"'|tail -1)
  u_loginname=$(echo  "$u_loginstring"|awk '{print $3}')
  u_loginpass=$(echo  "$u_loginstring"|awk '{print $4}')
  u_loginphone=$(echo "$u_loginstring"|awk '{print $5}')
  u_logindir=$(echo   "$u_loginstring"|awk '{print $6}')
fi

#5.获取用户文件名
t_tooladminname=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$3=="'$t_admin'"'|tail -1|awk '{print $3}')
u_homedir=$u_logindir
if [ "$u_homedir" = "" ];then
u_homedir=$t_tooldir
fi
if [ ! -d $u_homedir ];then 
echo "err!137:$u_homedir is not exist!";
exit 1
fi
u_sfile=$u_homedir/s$u_ipstring.txt
u_afile=$u_homedir/a$u_ipstring.txt
u_dfile=$u_homedir/d$u_ipstring.txt
u_bfile=$u_homedir/b$u_ipstring.txt
u_ffile=$u_homedir/f$u_ipstring.txt
u_cfile=$u_homedir/c$u_ipstring.txt
u_pfile=$u_homedir/p$u_ipstring.txt
u_gfile=$u_homedir/g$u_ipstring.sh

t_sfile=$u_homedir/.s$u_ipstring.txt
t_afile=$u_homedir/.a$u_ipstring.txt
t_dfile=$u_homedir/.d$u_ipstring.txt
t_bfile=$u_homedir/.b$u_ipstring.txt
t_ffile=$u_homedir/.f$u_ipstring.txt
t_cfile=$u_homedir/.c$u_ipstring.txt
t_pfile=$u_homedir/.p$u_ipstring.txt
t_gfile=$u_homedir/.g$u_ipstring.sh

u_homebakdir=$u_homedir/toolbak
t_toolbakdir=$t_tooldir/toolbak
mkdir -p $u_homebakdir
mkdir -p $t_toolbakdir

################################################################################
##2.工具使用说明
################################################################################
function Tooluse
{
clear
cat <<menu
ae工具使用指引:(首次使用带除user以外的任何参数则会进入注册流程)
--------------------------------------------------------------------------------
ae user     :用户信息管理            |详细用法:[ae help user    ]
ae home     :查看个人工作目录        |详细用法:[ae help home    ]
ae bak      :用户文件备份            |详细用法:[ae help bak     ]
ae tool     :查看ae工具的全路径文件名|详细用法:[ae help tool    ]
ae toolmode :查看ae工具的安装模式    |详细用法:[ae help toolmode] -- new
ae usemode  :查看ae指令的运行模式    |详细用法:[ae help tooluse ] -- new
ae whoami   :查看当前用具指令的调用者|详细用法:[ae help whoami  ]
ae uname    :查看ae工具系统名        |详细用法:[ae help uname   ]
ae load     :分享或者下载标签(应用)  |详细用法:[ae help load    ]
--------------------------------------------------------------------------------
ae s        :查看聊件全路径          |详细用法:[ae help file    ]
ae s type   :查看文件类型            |详细用法:[ae help type    ]
ae s vi     :用vi编辑器打开文件      |详细用法:[ae help vi      ]
ae s view   :用view编辑器打开文件    |详细用法:[ae help view    ]
ae s trun   :清空文件                |详细用法:[ae help trun    ]
ae s ord    :让文件内容按域对齐      |详细用法:[ae help ord     ]
ae s echo   :输出文件反向镜像脚本    |详细用法:[ae help echo    ]
ae s cat    :查看文件内容            |详细用法:[ae help cat     ]
ae s cal    :计算s文件中所有数字之和 |详细用法:[ae help cal     ]
ae s sh     :执行文件文本            |详细用法:[ae help sh      ]
ae s d      :文件拷贝(s<--d)         |详细用法:[ae help cp      ]
ae s d diff :比较两个临时文件文本异同|详细用法:[ae help diff    ]
ae b label  :将标签内容提取到s文件   |详细用法:[ae help label   ]
ae b s      :将标签内容保存到库文件  |详细用法:[ae help label   ]
ae b lab del:删除指定标签            |详细用法:[ae help label   ]
ae b lab sh :执行库文件标签脚本      |详细用法:[ae help sh      ]
ae b lab pg :查看指定标签的子标签    |详细用法:[ae help pg      ]
--------------------------------------------------------------------------------
ae para 1 1 :获取动态参数            |详细用法:[ae help para    ]
--------------------------------------------------------------------------------
ae 0 format :字符串格式化处理        |详细用法:[ae help format  ]
ae 1 format :字符串格式化处理        |详细用法:[ae help format  ]
ae 0 cal    :计算s文件中所有数字之和 |详细用法:[ae help cal     ]
ae 1 cal    :计算s文件第1列数字之和  |详细用法:[ae help cal     ]
--------------------------------------------------------------------------------
ae sql sqlstr:[sql]运行数据库语句    |详细用法:[ae help sql     ]
ae sql tbname:[sql]查询表结构信息    |详细用法:[ae help sql     ]
ae cal 1+1   :计算数学表达式         |详细用法:[ae help cal     ]
--------------------------------------------------------------------------------
menu
}

################################################################################
##3.库函数
################################################################################
#1.是否为数字 0-否,1-是
function isdigit
{
local f1=$(echo "$1"|sed 's/[0-9]//g')
if [ "$f1" = "" -a "$1" != "" ];then
echo 1
else
echo 0
fi
}

#2.是否为数字、字符、下划线组合.0-否,1-是
function islabel
{
local f1=$(echo "$1"|sed 's/[0-9a-zA-Z_]//g')
if [ "$f1" = "" -a ! "$1" = "" ];then
echo 1
else
echo 0
fi
}

#3.echo 文本还原 f1-一行文本
function dealecho
{
local f1=""
cat $1|sed 's/\\/<nnnn>/g'|sed 's/ //g'|sed 's/    //g'|while read f1
do
f1=$(echo "$f1"|sed 's/\"/\\\"/g'|sed 's/\$/\\\$/g'|sed 's/<nnnn>/\\\\\\\\\\\\\\\\/g'|sed 's// /g'|sed 's//    /g')
echo "echo \"""$f1""\""
done
exit 0;
}

#4.让源文件变整齐 f1-长度字符串,f2-输出一行文本,f3-长度字符串的一段,f4-临时变量
function dealorder
{
local s=$(cat $1|awk '{for(i=1;i<=NF;i++)if(a[i]<length($i))a[i]=length($i)}END{i=1;while(a[i]!=""){printf "%d ",a[i++]}}')
cat $1|awk -v s="$s" 'BEGIN{split(s,a)}{for(i=1;i<=NF;i++){j=a[i]-length($i)+1;printf "%s",$i;while(j-->0){printf " "}}print ""}'|sed 's/ *$//'
}

#5.计算临时文件的所有数字之和
function dealcal
{
if [ $(isdigit "$1") -eq 1 ];then
if [ "$1" = "0" ];then
cat $u_sfile|sed 's/[^0-9.-]/ /g'|sed 's/-/ -/g'|awk 'BEGIN{j=0.00}{i=0;while(i++<NF){j+=$i}}END{print j}'
else
cat $u_sfile|awk -v f="$1" '{print $f}'|sed 's/[^0-9.-]/ /g'|sed 's/-/ -/g'|awk 'BEGIN{j=0.00}{i=0;while(i++<NF){j+=$i}}END{print j}'
fi
else
cat $1|sed 's/[^0-9.-]/ /g'|sed 's/-/ -/g'|awk 'BEGIN{j=0.00}{i=0;while(i++<NF){j+=$i}}END{print j}'
fi
}

################################################################################
##4.应用函数
################################################################################
#1.获取虚拟ip -- 虚拟ip用日期加顺序号来表示
function getvirip
{
local t1=""
t2=$(date +%Y.%m.%d)
i=1
while [ $i -le 9999 ]
do
t3=$(echo "$i"|awk '{printf "%04d",$1}')
t1=$t2.$t3
if [ $(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v ^#|awk -v t1="$t1" '{if($1==t1){print $2}}'|wc -l|awk '{print $1}') -le 0 ];then
break
fi
i=$(expr $i + 1)
done
echo "$t1"
}

#2.将指定文件格式化输出,$1源文件,$2-0/1/2,$3格式字符串,$4特殊处理标识-0-字段不对其
#mode:1-普通,2-条件格式字符串(每行使用了不同的条件,这一块儿不好改动--使用的情况非常少)
function FormatFile
{
mode=1
condition="<!if()then{}elif()then{}else{}!>"
head=$(echo $condition|awk -F '{print $1}')
tail=$(echo $condition|awk -F '{print $NF}')
head2=$(echo "$3"|cut -c1-$(length $head))
tail2=$(echo "$3"|cut -c$(expr $(length "$3") - $(length $tail) + 1)-$(length "$3"))
if [ $tail = "$tail2" -a $head = "$head2" ];then
  mode=2
fi
format=`echo "$3"|sed 's/ //g'`
format=`echo "$format"|sed 's/%%s/\\$\\$/g'`
if [ $2 -gt 0 ]; then
  format=`echo "$format"|sed 's/%s/\\$'$2'/g'`
else
  i=1
  irep=$(echo "$3"|sed 's/%s//g'|awk -F '{print NF}')
  while [ $i -le $irep ]
  do
    format=$(echo "$format"|sed 's/%s/$'$i'/')
    i=$(expr $i + 1)
  done
fi
if [ $mode -eq 2 ];then
  tt=$(echo "$format"|sed 's// /g'|\
  sed 's/^<!if(/t2=\"\";if(/'|sed 's/)then{/){t2=\"/g'|sed 's/}elif(/\";}else if(/g'|sed 's/}else{/\";}else{t2=\"/'|sed 's/}!>$/\";};/')
  s=$(cat $1|awk '{for(i=1;i<=NF;i++)if(a[i]<length($i))a[i]=length($i)}END{i=1;while(a[i]!=""){printf "%d ",a[i++]}}')
  if [ "$4" = "0" ];then
    echo "cat $1|awk -v s=\"$s\" 'BEGIN{split(s,a)}{$tt;for(i=1;i<=NF;i++){k=\$i;\
    gsub(\">\\\\\\\\$\" i \">\",toupper(k),t2);gsub(\"<\\\\\\\\$\" i \"<\",tolower(k),t2);gsub(\"\\\\\\\\$\" i,k,t2);};print t2}'"|sh
  else
    echo "cat $1|awk -v s=\"$s\" 'BEGIN{split(s,a)}{$tt;for(i=1;i<=NF;i++){j=a[i]-length(\$i);k=\$i;while(j-->0){k=k \" \"};\
    gsub(\">\\\\\\\\$\" i \">\",toupper(k),t2);gsub(\"<\\\\\\\\$\" i \"<\",tolower(k),t2);gsub(\"\\\\\\\\$\" i,k,t2);};print t2}'"|sh
  fi
  exit 0
fi
if [ $mode -eq 1 ];then
  format=$(echo "$format"|sed 's// /g')
  s=$(cat $1|awk '{for(i=1;i<=NF;i++)if(a[i]<length($i))a[i]=length($i)}END{i=1;while(a[i]!=""){printf "%d ",a[i++]}}')
  if [ "$4" = "0" ];then
	cat $1|awk -v s="$s" -v t="$format" 'BEGIN{split(s,a)}{t2=t;for(i=1;i<=NF;i++){gsub(">\\$" i ">",toupper($i),t2);\
	gsub("<\\$" i "<",tolower($i),t2);gsub("\\$" i,$i,t2);};print t2}'
  else
	cat $1|awk -v s="$s" -v t="$format" \
	'BEGIN{split(s,a)}{t2=t;for(i=1;i<=NF;i++){j=a[i]-length($i);k=$i;while(j-->0){k=k " "};gsub(">\\$" i ">",toupper(k),t2);\
	gsub("<\\$" i "<",tolower(k),t2);gsub("\\$" i,k,t2);};print t2}'
  fi
  exit 0
fi
}

#3.获取文件的tag到sfile,1-file,2-tag
function getfiletag
{
sed -n '/^'#:$2:'/,/^#:/'p $1 >$t_sfile
head -1 $t_sfile
sed -n '/^'#:$2:'/,/^#:/'p $t_sfile|grep -v "^#:"
>$t_sfile
}

#4.删除文件tag,1-tagfile(libfile),2-tag,3-null/0(no yes) 0-不给提示直接删除标签
function delfiletag
{
getfiletag $1 $2 >$t_dfile
local t1=$(wc -l $1|awk '{print $1}')
local t2=$(wc -l $t_dfile|awk '{print $1}')
local t3=$(grep -n "^#:$2:" $1|awk -F: '{print $1}')
local t4=$(head -1 $t_dfile|awk -F: '{print $3}')
local t5=""
if [ $t2 -le 0 ];then echo "err!364:no tag find";exit 1;fi
if [ "$t4" = "const" ];then echo "err!365:you cannot del const tag!";exit 1;fi
if [ "$3" != "0" ];then
  echo "--------------------------------------------------------------------------------"
  cat $t_dfile
  echo "--------------------------------------------------------------------------------"
  echo "$2"|awk '{printf "confirm delete tag %s?(y/n):",$1}'
  read t5
  if [ "$t5" != "y" ];then echo "you give up!";exit 0;fi
fi
>$t_cfile
if [ $(expr $t3 - 1) -gt 0 ];then
head -$(expr $t3 - 1) $1 >>$t_cfile
fi
if [ $(expr $t1 - $t3 - $t2 + 1) -gt 0 ];then
tail -$(expr $t1 - $t3 - $t2 + 1) $1 >>$t_cfile
fi
if [ $(expr $t1 - $t2) -ne $(wc -l $t_cfile|awk '{print $1}') ];then
  echo "err!377:del err!please check the file system space!"
  exit 1
fi
cp $t_cfile $1
if [ $? -ne 0 ];then 
  if [ $t1 -ne $(wc -l $1|awk '{print $1}') ];then
    echo "err!383:recover $1 err!"
    echo "please recover it by hand!"
    echo "command:[cp $t_cfile $1]"
    exit 1
  fi
  echo "err!388:del err!please check the file system space!";
  exit 1;
fi
if [ "$3" != "0" ];then echo "del tag $2 success!";fi
>$t_dfile
>$t_cfile
}

#5.保存标签 1-tagfile,2-处理方式:0-安静的,1-普通的,2-如果标签存在则报错退出.
function savefiletag
{
cp $t_sfile $t_afile
if [ $(wc -m $t_afile|awk '{print $1}') -lt $(length "#:a:") ];then echo "err!400:sfile format err!";exit 1;fi
if [ $(head -1 $t_afile|cut -c1-2)x != "#:x" -o \
     $(head -1 $t_afile|awk -F: '{print NF}') -lt 3 -o \
     $(grep "^#:" $t_afile|wc -l|awk '{print $1}') -ne 1 ];then
  echo "err!404:the data in t_afile format err!"
  exit 1
fi
local t1=$(head -1 $t_afile|awk -F: '{print $2}')
if [ $(islabel "$t1") -ne 1 ];then echo "err!408:tag name format err!use:[0-9a-zA-Z_]";fi
getfiletag $1 $t1 >$t_dfile
local t2=$(wc -l $1|awk '{print $1}')
local t3=$(wc -l $t_dfile|awk '{print $1}')
local t4=$(grep -n "^#:$t1:" $1|awk -F: '{print $1}')
local t5=$(wc -l $t_afile|awk '{print $1}')
local t6=$(echo "$1"|awk -F\/ '{print $NF}'|cut -c1-1)
if [ $t3 -le 0 -a $2 = "2"  ];then cat $t_afile >>$1;echo "upload [$t1] success!";exit 0;fi
if [ $t3 -le 0 -a $2 != "2" ];then cat $t_afile >>$1;echo "save success!"        ;exit 0;fi
if [ $2 = "2" ];then echo "the tag is exist!please check the name!";exit 1;fi
if [ $2 != "0" ];then
  echo "diff "$t6"file.$t1 sfile"
  echo "--------------------------------------------------------------------------------"
  diff $t_dfile $t_afile
  if [ $? -eq 0 ];then
    echo "sfile is same to "$t6"file.$t1!"
    exit 0
  fi
  echo "--------------------------------------------------------------------------------"
  echo "$t6,$t1"|awk -F, '{printf "confirm using sfile to replace %sfile.%s!(y/n):",$1,$2}'
  read flag2
  if [ "$flag2" != "y" ];then echo "you give up!";exit 0;fi
fi
>$t_cfile
if [ $(expr $t4 - 1) -gt 0 ];then
head -$(expr $t4 - 1) $1 >$t_cfile
fi
cat $t_afile >>$t_cfile
if [ $(expr $t2 - $t4 - $t3 + 1) -gt 0 ];then
tail -$(expr $t2 - $t4 - $t3 + 1) $1 >>$t_cfile
fi
if [ $(expr $t2 - $t3 + $t5) -ne $(wc -l $t_cfile|awk '{print $1}') ];then
  echo "err!434:del err!please check the file system space!"
  exit 1
fi
cp $t_cfile $1
if [ $? -ne 0 ];then
  if [ $t2 -ne $(wc -l $1|awk '{print $1}') ];then
    echo "err!440:recover $tagfile err!"
    echo "please recover it by hand!"
    echo "command:[cp $t_cfile $1]"
    exit 1
  fi
  echo "err!445:del err!please check the file system space!";
  exit 1;
fi
if [ "$2" != "0" ];then echo "save tag $t1 success!";fi
>$t_afile
>$t_dfile
>$t_cfile
}

#6.已存在用户登录 aelogininfo:20170428 093030 198.30.1.51 198.30.1.57 0/1(0-登录,1-登出)
function dealsecondlogin
{
if [ "$t_toolmode" = "session" ];then
var1="$u_sessionid"
else
var1=$(getip)
fi
var2=$(sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|awk '$1=="'$t_today'" && $3=="'$var1'"'|tail -1)
if [ "$var2" != "" ];then
  var21=$(echo $var2|awk '{print $4}')
  var22=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$1=="'$var21'"'|tail -1|awk '{print $3}')
  var23=$(echo $var2|awk '{print $5}')
  echo "t_current aelogininfo:"
  echo "登录日期 登录时间 自己IP 登录IP 登录用户名 当前状态"|awk '{printf "%-8s %-8s %-15s %-15s %-12s %s\n",$1,$2,$3,$4,$5,$6}'
  echo "$var2(1-登录/2-登出) $var22"|awk '{printf "%-8s %-8s %-15s %-15s %-12s %s\n",$1,$2,$3,$4,$6,$5}'
else
  echo "今天尚未登录过其他用户!"
fi
echo "input:(1-登录/2-登出):"|awk -F, '{printf "%s",$1}'
read var
if [ "$var" != "1" -a "$var"  != "2" ];then echo "err!475:input err![$var]"                      ;exit 1;fi
if [ "$var"  = "2" -a "$var2"  = ""  ];then echo "err!476:今天尚未登录过,不需要登出!"            ;exit 1;fi
if [ "$var"  = "2" -a "$var23" = "2" ];then echo "err!477:当前状态已经为登出状态![$var][$var23]" ;exit 1;fi
if [ "$var"  = "1" -a "$var23" = "1" ];then echo "err!478:当前为登录状态,请先登出再登陆其他用户!";exit 1;fi
echo "input login user name:"|awk -F, '{printf "%s",$1}'
read var3
if [ "$var"  = "2" -a "$var3" != "$var22" ];then echo "err!481:用户名输入错误![$var3]"  ;exit 1;fi
var32=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$3=="'$var3'"'|tail -1|awk '{print $1}')
if [ "$var1" = "$var32" ];then echo "err!483:没必要用自己的IP手动登录自己的用户![$var1]";exit 1;fi
echo "input login user pass:"|awk -F, '{printf "%s",$1}'
read var31
var4=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$3=="'$var3'" && $4=="'$var31'"'|tail -1|awk '{print $1}')
if [ "$var4" = "" ];then echo "err!487:login failed!wrong name or password![$var3/$var31]";exit 1;fi
var5=$(grep "^#:aelogininfo:" $t_zfile|wc -l|awk '{print $1}')
var6=$(date +%H%M%S)
if [ $var5 -eq 0 ];then
  echo "#:aelogininfo:const:用户登录信息表" >$t_sfile
  echo "$t_today $var6 $var1 $var4 $var" >>$t_sfile
elif [ $var5 -eq 1 ];then
  sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|head -1 >$t_sfile
  sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#:" >>$t_sfile
  echo "$t_today $var6 $var1 $var4 $var" >>$t_sfile
elif [ $var5 -gt 1 ];then
  echo "err!498:more than one tag in file![$var6]"
  exit 1
fi
savefiletag $t_zfile 0
echo "deal login success!"
$t_rm $t_sfile 2>/dev/null
exit 0
}

#7.绑定当前会话id aelogininfo:20170428 093030 pts/56 198.30.1.57 1/2(1-登录,2-登出)
function dealsessionlogin
{
var3=$(who am i|awk '{print $2}')
var4=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk -v name="$1" '$3==name'|tail -1|awk '{print $1}')
if [ "$var4" = "" ];then
echo "err!499:用户不存在![$1]"
return
fi
var66=$(sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#"|awk '$1=="'$t_today'" && $3=="'$var3'" '|tail -1|awk '{print $0}')
var6=$(echo "$var66"|awk '{print $4}')
var7=$(echo "$var66"|awk '{print $5}')
if [ "$var6" = "$var4" -a "$var7" = "1" ];then
return
fi
var5=$(grep "^#:aelogininfo:" $t_zfile|wc -l|awk '{print $1}')
var2=$(date +%H%M%S)
if [ $var5 -eq 0 ];then
echo "#:aelogininfo:const:用户登录信息表" >$t_sfile
echo "$t_today $var2 $var3 $var4 1" >>$t_sfile
elif [ $var5 -eq 1 ];then
sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|head -1 >$t_sfile
sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#:" >>$t_sfile
echo "$t_today $var2 $var3 $var4 1" >>$t_sfile
elif [ $var5 -gt 1 ];then
echo "err!532:more than one tag in file![aelogininfo]"
exit 1
fi
savefiletag $t_zfile 0
$t_rm $t_sfile 2>/dev/null
exit 0
}

#8.会话模式的登出 -- ae user out
function dealsessionout
{
local t1=$(date +%H%M%S)
sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|head -1 >$t_sfile
sed -n '/^#:aelogininfo:/,/^#:/p' $t_zfile|grep -v "^#:" >>$t_sfile
echo "$t_today $t1 $u_sessionid 0.0.0.0 2" >>$t_sfile
savefiletag $t_zfile 0
exit 0
}

#9.用户注册 ,0-新用户注册,1-修改个人信息,3-new通过虚拟ip注册
function dealfirstlogin
{
logintype=$1
if [ $logintype -eq 1 ];then
  echo "用户信息修改:"
  echo "--------------------------------------------------------------------------------"
  echo "$u_loginstring"|awk '{printf "old info:\nname    :%s\npassword:%s\nphone   :%s\nworkdir :%s\n",$3,$4,$5,$6}'
else
  echo "注册新用户:"
fi
echo "--------------------------------------------------------------------------------"
while true
do
  echo "please input your name"|awk -F, '{printf "%s:",$1}'
  read name
  if [ $logintype -eq 1 -a "$name" = "" ];then name=$(echo "$u_loginstring"|awk '{print $3}');fi
  temp1=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$3=="'$name'"'|wc -l|awk '{print $1}')
  if [ $(length "$name") -lt 2 -o $(length "$name") -gt 24 -o $(echo "$name"|cut -c1-2|sed 's/[a-z]//g')x != "x" -o \
       $(echo "$name"|sed 's/[a-z0-9]//g')x != "x" ];then
    echo "err!571:格式错误,姓名必须为2-24个英文小写字母与数字组合,且前两个字符必须为小写字母!"
  elif [ $temp1 -ge 1 -a "$name" != "$u_loginname" ];then
    echo "err!573:用户名已被占用,请输入新的用户名!"
  else
    break
  fi
done
while true
do
  echo "please input your password(use six digit)"|awk -F, '{printf "%s:",$1}'
  read password
  if [ $logintype -eq 1 -a "$password" = "" ];then password=$(echo "$u_loginstring"|awk '{print $4}');fi
  temp=$(echo "$password"|sed 's/[0-9]//g')
  if [ $(echo "$password"|sed 's/[0-9]//g')x != "x" -o "$password" = "" -o $(length "$password") -ne 6 ];then
    echo "err!585:format err!please input again!"
  else
    break
  fi
done
while true
do
  echo "please input your phone no(use eleven digit)"|awk -F, '{printf "%s:",$1}'
  read phone
  if [ $logintype -eq 1 -a "$phone" = "" ];then phone=$(echo "$u_loginstring"|awk '{print $5}');fi
  temp=$(echo "$phone"|sed 's/[0-9]//g')
  if [ $(echo "$phone"|sed 's/[0-9]//g')x != "x" -o "$phone" = "" -o $(length "$phone") -ne 11 ];then
    echo "err!597:format err!please input again!"
  else
    break
  fi
done
while true
do
  echo "please input your priv work dir(eg:$t_basedir/$name/autoeasy)"|awk -F, '{printf "%s:",$1}'
  read workdir
  mkdir -p $workdir 2>/dev/null
  if [ $logintype -eq 1 -a "$workdir" = "" ];then workdir=$(echo "$u_loginstring"|awk '{print $6}');fi
  workdir=$(echo "$workdir"|sed 's/ //g'|sed 's/\/$//')
  #workdir=$(trimtail "$workdir")
  firstchar=$(echo "$workdir"|cut -c1-1)
  if [ ! -d "$workdir" -o "$firstchar" != "/" -o $(length "$workdir") -le $(length "$HOME/priv/") ];then
    echo "err!612:input err!please input again!"
  elif [ "$workdir" = "$t_tooldir" ];then
    echo "err!614:you can't use this dir!please input again!"
  else
    break
  fi
done
if [ $logintype -eq 1 -a "$name" = "$u_loginname" -a "$password" = "$u_loginpass" -a "$phone" = "$u_loginphone" -a "$workdir" = "$u_logindir" ];then
  echo "err!620:no info modified!"
  exit 0
fi
if [ $(sed -n '/^#:aeuserinfo:/p' $u_zfile|wc -l|awk '{print $1}') -le 0 ];then
  echo "#:aeuserinfo:const:用户信息登记"  >$t_sfile
else
  getfiletag $u_zfile "aeuserinfo" >$t_dfile;cp $t_dfile $t_sfile
  if [ $logintype -eq 1 ];then
    cat $t_sfile >$t_dfile
    cat $t_dfile|awk '$2!="'$u_ipstring'"' >$t_sfile
    >$t_dfile
  fi
fi
#会话模式注册用户都使用虚拟ip -- new
if [ $logintype -eq 3 ];then
  u_srcip=$(getvirip)
  u_ipstring=$(echo "$u_srcip"|awk -F. '{printf "%04d%02d%02d%04d",$1,$2,$3,$4}')
fi
echo "$u_srcip $u_ipstring $name $password $phone $workdir" >>$t_sfile
savefiletag $u_zfile 0
if [ "$workdir" != "$u_homedir" ];then
  mkdir -p $workdir/toolbak
  if [ $logintype -eq 1 ];then
    mv $u_homedir/*$u_ipstring.txt $workdir 1>/dev/null 2>&1
    mv $u_homedir/toolbak/*$u_ipstring.txt.*  $workdir/toolbak 1>/dev/null 2>&1
  fi
fi
echo "--------------------------------------------------------------------------------" 
if [ $logintype -eq 0 ];then
  $t_rm [sdatbpcf]$u_ipstring.txt 2>/dev/null
  $t_rm [g]$u_ipstring.sh 2>/dev/null
  echo "regin success!you can use this tool now!"
fi
if [ $logintype -eq 3 ];then
  $t_rm [sdatbpcf]$u_ipstring.txt 2>/dev/null
  $t_rm [g]$u_ipstring.sh 2>/dev/null
  echo "regin success!you can use it by login in!"
fi
if [ $logintype -eq 1 ];then
  >$t_sfile 
  echo "modify success!you can use this tool now!"
fi
}

#10.运行数据库查询语句
#mysql -uroot -pFree2016 -e "  
#use ssms;
#select count(0) from clazz;
#quit"

function runsql
{
sqlstr="$1"
>$t_sfile
mysql -u$t_dbname -p$t_dbpass -e "
use $t_dbsid;
$sqlstr;
quit" 2>/dev/null
}

function runsql2
{
sqlstr="$1"
>$t_sfile
sqlplus $t_dbname/$t_dbpass@$t_dbsid <<! >>$t_sfile
set lines     3000;
set head      off ;
set feedback  off ;
set heading   off ;
set verify    off ;
set trimspool off ;
select '---begin---' from dual;
$sqlstr;
select '---end---' from dual;
!
totline=$(sed -n '/---begin---/,/---end---/'p $t_sfile|wc -l);
if [ $totline -le 3 ];then return;fi
sed -n '/---begin---/,/---end---/'p $t_sfile|head -$(expr $totline - 2)|tail -$(expr $totline - 4)|sed '/./!d'
>$t_sfile
}

#11.获取动态参数,如果sh不带参数则检测脚本中是否含有参数变量tippara，如果有则动态获取参数 -- 参数放在t_ffile -- p1-tagfile(lidfile/t_dfile),p2-para
function getdynpara
{
tagfile=$1
tag=$2
begin="#:"$tag":sh:"
>$t_ffile
if [ "$tag" = "" ];then
jj=$(cat $tagfile|sed -n '/^tippara=\"/p'|wc -l|awk '{print $1}')
else
jj=$(sed -n '/^'$begin'/,/^#:/'p $tagfile|sed -n '/^tippara=\"/p'|wc -l|awk '{print $1}')
fi
ii=1
while [ $ii -le $jj ]
do
if [ "$tag" = "" ];then
tipparadesc=$(cat $tagfile|sed -n '/^tippara=\"/p'|head -$ii|tail -1|cut -c9-|sed 's/[ ]*$//')
else
tipparadesc=$(sed -n '/^'$begin'/,/^#:/'p $tagfile|sed -n '/^tippara=\"/p'|head -$ii|tail -1|cut -c9-|sed 's/[ ]*$//')
fi
tippara=$(echo "$tipparadesc"|cut -c2-$(expr $(length "$tipparadesc") - 1))
i=1
while [ $i -le $(echo $tippara|awk -F, '{print NF}') ]
do
  tip=$(echo $tippara|awk -F, '{print $('$i')}')
  echo $tip|awk -F, '{printf "%s:",$1}'
  read onetip
  #如果onetip为空并且提示信息含有缺省值则使用缺省值作为参数.(def:hello)
  if [ "$onetip" = "" ];then
    thistip=$(echo $tip|awk -F, '{printf "%s:",$1}')
    left=$(echo "$thistip"|awk -F[\(\)] '{print $(NF-1)}'|awk -F: '{print $1}')
	right=$(echo "$thistip"|awk -F[\(\)] '{print $(NF-1)}'|awk -F: '{print $2}')
	if [ "$left" = "def" -a "$right" != "" ];then
	  onetip="$right"
	fi
  fi
  if [ $i -eq 1 ];then
    tipline="$onetip"
  else
    tipline="$tipline""""$onetip"
  fi
  i=$(expr $i + 1)
done
if [ $(length "$tipline") -eq 0 ];then
  echo "" >>$t_ffile
else
  echo "$tipline" >>$t_ffile
fi
echo "--------------------------------------------------------------------------------"
ii=$(expr $ii + 1)
done
}

#12.获取引用的库函数,p1-工具临时文件名 -- 运行引用库指令,将结果追加到t_gfile
function dealimport
{
tagfile=$1
jj=$(cat $tagfile|sed -n '/^importinfo=\"/p'|wc -l|awk '{print $1}')
ii=1
while [ $ii -le $jj ]
do
importinfodesc=$(cat $tagfile|sed -n '/^importinfo=\"/p'|head -$ii|tail -1|cut -c12-|sed 's/[ ]*$//')
importinfo=$(echo "$importinfodesc"|cut -c2-$(expr $(length "$importinfodesc") - 1))
i=1
while [ $i -le $(echo "$importinfo"|awk -F, '{print NF}') ]
do
  tip=$(echo $importinfo|awk -F, '{print $('$i')}')
  echo "#--------------------------------------------------------------------------------" >>$t_gfile
  echo "#--[$tip]--[user $u_loginname $u_loginphone $t_current]--" >>$t_gfile
  echo "$tip"|sh|sed 's/^-/#-/' >>$t_gfile
  i=$(expr $i + 1)
done
ii=$(expr $ii + 1)
done
}

#13.用户个人tag上传与下载 -- 分享功能 -- para1:1-上传,2-下载
function dealload
{
if [ "$1" = "1" ];then cp $u_sfile $t_sfile;savefiletag $t_zfile 2;exit 0;fi
if [ "$1" = "2" ];then
echo ""|awk '{printf "please input the tagname:"}'
read f1
getfiletag $t_zfile "$f1" >$t_dfile
if [ $(cat $t_dfile|wc -l|awk '{print $1}') -le 0 ];then echo "not find the tag![$f1]";exit 0;fi
cp $t_dfile $u_sfile;
echo "download into sfile success!"
exit 0
fi
}

################################################################################
##5.主函数
################################################################################
#1.先导指令处理
#1.1 打印使用说明
if [ $# -eq 0 ];then Tooluse;exit 0;fi
if [ $# -eq 1 -a "$1" = "toolmode" ];then echo "$t_toolmode";exit 0;fi
if [ $# -eq 1 -a "$1" = "usemode"  ];then echo "$t_usemode" ;exit 0;fi
if [ $# -le 2 -a "$1" = "help"     ];then 
sed -n '/^#:aehelp:/,/^#:/p' $u_zfile|grep -v ^#:|sed -n '/^--:'$2':/,/^--:/p'|sed 's/--:'$2':/'$2':/'|grep -v "^--:";exit 0;
fi

#1.2.user先导指令处理 -- new:虚拟ip注册用户
if [ "$1" = "user" ];then
if [ $# -eq 1 ];then getfiletag $u_zfile "aeuserinfo"|grep -v ^#|grep -v ^$ >$t_afile;dealorder $t_afile;>$t_afile;exit 0;fi
if [ $# -eq 2 -a "$2" = "new"     ];then dealfirstlogin 3; exit 0;fi
if [ $# -eq 2 -a "$2" = "login"   ];then dealsecondlogin ; exit 0;fi
if [ $# -eq 2 -a "$2" = "out"     -a "$t_toolmode" = "session" -a "$t_usemode" = "0"  ];then echo "err!793:会话未绑定!1"; exit 0;fi
if [ $# -eq 2 -a "$2" = "modify"  -a "$t_toolmode" = "session" -a "$t_usemode" = "0"  ];then echo "err!796:会话未绑定!2"; exit 0;fi
if [ $# -eq 2 -a "$2" = "self"    -a "$t_toolmode" = "session" -a "$t_usemode" = "0"  ];then echo "err!797:会话未绑定!3"; exit 0;fi
if [ $# -eq 2 -a "$2" = "out"     -a "$t_toolmode" = "session" -a "$t_usemode" = "2"  ];then dealsessionout             ; exit 0;fi
if [ $# -eq 2 -a "$2" = "modify"  -a "$t_toolmode" = "ip"                             ];then dealfirstlogin 1           ; exit 0;fi
if [ $# -eq 2 -a "$2" = "modify"  -a "$t_toolmode" = "session" -a "$t_usemode" = "2"  ];then dealfirstlogin 1           ; exit 0;fi
if [ $# -eq 2 -a "$2" != "modify" -a "$t_toolmode" = "session"                        ];then dealsessionlogin "$2"      ; exit 0;fi
echo "err!798:para err!=[$2]";exit 1;
fi

#1.3.新用户信息注册 -- 会话模式必须绑定会话,ip模式必须登录或者注册用户 -- 进行后续操作的条件
if [ "$t_toolmode" = "session" -a "$t_usemode" = "0" ];then echo "err!802:会话未绑定!3"; exit 0;fi
if [ "$t_toolmode" = "ip"      -a "$t_usemode" = "0" ];then
t1=$(sed -n '/^#:aeuserinfo:/,/^#:/p' $u_zfile|grep -v "^#"|awk '$1=="'$u_srcip'"'|wc -l|awk '{print $1}')
if [ $t1 -le 0 -a "$u_srcip" =  "0.0.0.0" ];then echo "err!805:获取用户ip错误!";exit 0;fi
if [ $t1 -le 0 -a "$u_srcip" != "0.0.0.0" ];then dealfirstlogin 0              ;exit 0;fi
fi

#1.4.查看系统信息
if [ $# -eq 1 -a "$1"     = "uname"  ];then echo "AESO"        ;exit 0;fi
if [ $# -eq 1 -a "$1"     = "whoami" ];then echo $u_loginname  ;exit 0;fi
if [ $# -eq 3 -a "$1$2$3" = "whoami" ];then echo "$u_loginname $u_logindir $(date +%b) $(date +%d) $(date +%X) ($u_srcip)";exit 0;fi

#1.5 系统文件权限检查 系统文件只能有admin用户才可以修改
if [ "$1" = "z"  -a "$u_loginname" != "$t_admin" ];then
if [ "$2" = "vi" -o "$3" = "del"   -o "$2" = "s" -o $# -eq 1 ];then
echo "err!817:you have no power to edit tool system file!";
echo "please call tool admin to deal it![$t_tooladminname]";
exit 1;
fi
fi

#1.6 获取动态参数,每行动态参数之间用符号分割
if [ $# -eq 3 -a "$1" = "para" -a $(isdigit "$2") -eq 1 -a $(isdigit "$3") -eq 1 ];then
if [ -f $t_ffile ];then
sed -n ''$2','$2''p $t_ffile|awk -F '{print $('$3')}'
fi
exit 0
fi

#1.7 查看文件类型 1-临时文件txt,2-临时文件sh,3-库文件,4-系统库文件,0-非工具文件
if [ $# -eq 2 -a "$2" = "type" ];then
filetype=0
if [ "$1" = "s" -o "$1" = "t" -o "$1" = "d" -o "$1" = "a" ];then filetype=1;fi
if [ "$1" = "g"                                           ];then filetype=2;fi
if [ "$1" = "b" -o "$1" = "f" -o "$1" = "c" -o "$1" = "p" ];then filetype=3;fi
if [ "$1" = "z"                                           ];then filetype=4;fi
echo $filetype
exit 0
fi

#2.文件目录创建备份与查看
if [ ! -f $u_sfile ];then >$u_sfile;fi
if [ ! -f $u_dfile ];then >$u_dfile;fi
if [ ! -f $u_afile ];then >$u_afile;fi
if [ ! -f $u_gfile ];then >$u_gfile;chmod u+x $u_gfile;fi
if [ ! -f $u_bfile ];then >$u_bfile;fi
if [ ! -f $u_ffile ];then >$u_ffile;fi
if [ ! -f $u_cfile ];then >$u_cfile;fi
if [ ! -f $u_pfile ];then >$u_pfile;fi
if [ ! -f $u_zfile ];then >$u_zfile;fi
if [ ! -f $t_sfile ];then >$t_sfile;fi
if [ ! -f $t_dfile ];then >$t_dfile;fi
if [ ! -f $t_afile ];then >$t_afile;fi
if [ ! -f $t_gfile ];then >$t_gfile;chmod u+x $t_gfile;fi
if [ ! -f $t_bfile ];then >$t_bfile;fi
if [ ! -f $t_ffile ];then >$t_ffile;fi
if [ ! -f $t_cfile ];then >$t_cfile;fi
if [ ! -f $t_pfile ];then >$t_pfile;fi
if [ ! -f $t_zfile ];then >$t_zfile;fi

if [ $# -eq 1 ];then
if   [ "$1" = "tool"     ];then echo $t_name   ;exit 0;
elif [ "$1" = "home"     ];then echo $u_homedir;exit 0;
elif [ "$1" = "toolhome" ];then echo $t_tooldir;exit 0;
elif [ "$1" = "bak"      ];then 
cp $u_bfile  $u_bfile.$t_current
cp $u_ffile  $u_ffile.$t_current
cp $u_cfile  $u_cfile.$t_current
cp $u_pfile  $u_pfile.$t_current
mv $u_bfile.$t_current $u_homebakdir
mv $u_ffile.$t_current $u_homebakdir
mv $u_cfile.$t_current $u_homebakdir
mv $u_pfile.$t_current $u_homebakdir
echo "bak success!"
exit 0;
elif [ "$1" = "toolbak" ];then 
cp $t_name   $t_name.$t_current
cp $u_zfile  $u_zfile.$t_current
mv $t_name.$t_current  $t_toolbakdir
mv $u_zfile.$t_current $t_toolbakdir
echo "toolbak success!"
exit 0
fi
fi

#3.标签的上传和下载
if   [ $# -eq 2 -a "$1" = "load" -a "$2" = "cat"  ];then grep ^#: $t_zfile          ;exit 0;
elif [ $# -eq 3 -a "$1" = "load" -a "$2" = "cat"  ];then grep ^#: $t_zfile|grep "$3";exit 0;
elif [ $# -eq 2 -a "$1" = "load" -a "$2" = "up"   ];then dealload 1                 ;exit 0;
elif [ $# -eq 2 -a "$1" = "load" -a "$2" = "down" ];then dealload 2                 ;exit 0;
fi

#数学计算
if [ $# -eq 2 -a $(isdigit "$1") -eq 1 -a "$2" = "cal" ];then dealcal $1  ;exit 0;fi
if [ $# -eq 2 -a "$1" = "cal"                          ];then echo "$2"|bc;exit 0;fi

#4.个人文件查看、编辑、清空、管理(tag 处理)
f1file=""
f1type=0
if   [ "$1" = "s"  ];then f1file=$u_sfile;f1type=1;
elif [ "$1" = "d"  ];then f1file=$u_dfile;f1type=1;
elif [ "$1" = "a"  ];then f1file=$u_afile;f1type=1;
elif [ "$1" = "g"  ];then f1file=$u_gfile;f1type=2;
elif [ "$1" = "b"  ];then f1file=$u_bfile;f1type=3;
elif [ "$1" = "f"  ];then f1file=$u_ffile;f1type=3;
elif [ "$1" = "c"  ];then f1file=$u_cfile;f1type=3;
elif [ "$1" = "p"  ];then f1file=$u_pfile;f1type=3;
elif [ "$1" = "z"  ];then f1file=$u_zfile;f1type=4;
elif [ "$1" = ".s" ];then f1file=$t_sfile;f1type=-1;
elif [ "$1" = ".d" ];then f1file=$t_dfile;f1type=-1;
elif [ "$1" = ".a" ];then f1file=$t_afile;f1type=-1;
elif [ "$1" = ".g" ];then f1file=$t_gfile;f1type=-2;
elif [ "$1" = ".b" ];then f1file=$t_bfile;f1type=-3;
elif [ "$1" = ".f" ];then f1file=$t_ffile;f1type=-3;
elif [ "$1" = ".c" ];then f1file=$t_cfile;f1type=-3;
elif [ "$1" = ".p" ];then f1file=$t_pfile;f1type=-3;
elif [ "$1" = ".z" ];then f1file=$t_zfile;f1type=-4;
fi
f2file=""
f2type=0
if   [ "$2" = "s"  ];then f2file=$u_sfile;f2type=1;
elif [ "$2" = "d"  ];then f2file=$u_dfile;f2type=1;
elif [ "$2" = "a"  ];then f2file=$u_afile;f2type=1;
elif [ "$2" = "g"  ];then f2file=$u_gfile;f2type=2;
elif [ "$2" = "b"  ];then f2file=$u_bfile;f2type=3;
elif [ "$2" = "f"  ];then f2file=$u_ffile;f2type=3;
elif [ "$2" = "c"  ];then f2file=$u_cfile;f2type=3;
elif [ "$2" = "p"  ];then f2file=$u_pfile;f2type=3;
elif [ "$2" = "z"  ];then f2file=$u_zfile;f2type=4;
elif [ "$2" = ".s" ];then f2file=$t_sfile;f2type=-1;
elif [ "$2" = ".d" ];then f2file=$t_dfile;f2type=-1;
elif [ "$2" = ".a" ];then f2file=$t_afile;f2type=-1;
elif [ "$2" = ".g" ];then f2file=$t_gfile;f2type=-2;
elif [ "$2" = ".b" ];then f2file=$t_bfile;f2type=-3;
elif [ "$2" = ".f" ];then f2file=$t_ffile;f2type=-3;
elif [ "$2" = ".c" ];then f2file=$t_cfile;f2type=-3;
elif [ "$2" = ".p" ];then f2file=$t_pfile;f2type=-3;
elif [ "$2" = ".z" ];then f2file=$t_zfile;f2type=-4;
fi

if [ "$1" = "filetype" -a $# -eq 2 -a $f2type -gt 0 ];then echo $f2type;exit 0;fi

if [ $f1type -gt 0 ];then
if   [ $# -eq 1 -a $f1type -ge 1 -a $f1type -le 4                  ];then echo      $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "trun" -a "$t_usemode" != "1" ];then >$f1file  ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "vi"   -a "$t_usemode" != "1" ];then vi $f1file;exit 0;
elif [ $# -eq 2 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "vi"   -a "$t_usemode" != "1" ];then echo "please use view!";exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 4 -a "$2" = "view" ];then view      $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "cat"  ];then cat       $f1file        ;exit 0;
elif [ $# -eq 3 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "cat"  ];then cat       $f1file|grep "$3";exit 0;
elif [ $# -eq 2 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "cat"  ];then grep ^#:  $f1file        ;exit 0;
elif [ $# -eq 3 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "cat"  ];then grep ^#:  $f1file|grep "$3";exit 0;
elif [ $# -eq 2 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "pg"   ];then grep ^#:  $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "s" -a "$t_usemode" =  "1" ];then echo "can't use this usemode to save data!";exit 0;
elif [ $# -eq 2 -a $f1type -ge 3 -a $f1type -le 4 -a "$2" = "s" -a "$t_usemode" != "1" ];then cp $u_sfile $t_sfile;savefiletag $f1file 1 ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "echo" ];then dealecho  $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "ord"  ];then dealorder $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a "$2" = "cal"  ];then dealcal   $f1file        ;exit 0;
elif [ $# -eq 3 -a $f1type -eq 1 -a $f2type -eq 1 -a "$3" = "diff" ];then diff      $f1file $f2file;exit 0;
elif [ $# -eq 2 -a $f1type -ge 2 -a $f1type -le 2 -a "$2" = "sh"   ];then exec      $f1file        ;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 1 -a "$2" = "sh"   ];then getdynpara $f1file "";echo "#!/bin/sh" >$t_gfile;dealimport $f1file;
  cat $f1file|sed 's/^-/#/'|sed 's/^importinfo=/#importinfo=/' >>$t_gfile;echo "exit 0">>$t_gfile;exec $t_gfile;exit 0;
elif [ $# -eq 3 -a $f1type -ge 1 -a $f1type -le 1 -a "$2" = "sh"   ];then echo "$3"|sed 's/,//g' >$t_ffile;echo "#!/bin/sh" >$t_gfile;dealimport $f1file;
  cat $f1file|sed 's/^-/#/'|sed 's/^importinfo=/#importinfo=/' >>$t_gfile;echo "exit 0">>$t_gfile;exec $t_gfile;exit 0;
fi 

if [ "$t_usemode" != "1" ];then
if   [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a $f2type -ge 1 -a $f2type -le 2 -a "$f1file" != "$f2file" ];then cp $f2file $f1file;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a $f2type -lt 0                  ];then cp $f2file $f1file;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a -f $2                          ];then cp $2      $f1file;exit 0;
elif [ $# -eq 3 -a $f1type -ge 1 -a $f1type -le 2 -a -f $2 -a "$3" = "1"            ];then cat $2   >>$f1file;exit 0;
elif [ $# -eq 2 -a $f1type -ge 1 -a $f1type -le 2 -a $f2type -ge 3 -a $f2type -le 4 ];then sed -n '/^#:/ p' $f2file>$f1file;exit 0;
fi
fi

#标签处理,指定用户模式(usemode=1)没有改变他人用户文件的权限
if [ $# -ge 2 -a $f1type -ge 3 -a $f1type -le 4 -a $(islabel "$2") -eq 1 ];then
t3=$(grep "^#:$2:"    $f1file|wc -l|awk '{print $1}')
t4=$(grep "^#:$2:sh:" $f1file|wc -l|awk '{print $1}')
if [ $t3 -eq 0 -a $# -ge 2    ];then echo "err!981:not find the tag![$2]"  ;exit 1;fi
if [ $t3 -gt 1 -a $# -ge 2    ];then echo "err!982:more than one tags![$2]";exit 1;fi
if [ $t4 -le 0 -a "$3" = "sh" ];then echo "err!983:tag type err![$2]"      ;exit 1;fi

if [ $# -eq 2 -a "$t_usemode" != "1" ];then getfiletag $f1file $2 >$u_sfile;cat $u_sfile;exit 0;fi
if [ $# -eq 2 -a "$t_usemode" =  "1" ];then getfiletag $f1file $2;>$t_sfile;exit 0;fi
if [ $# -eq 3 -a "$3"         =  "s" ];then getfiletag $f1file $2;>$t_sfile;exit 0;fi

if [ $# -ge 3 -a $# -le 4 ];then
if [ $# -ge 3 -a $# -le 4 -a "$3" = "del" -a "$t_usemode" =  "1" ];then echo "can't use this usemode to delete data!";exit 0;fi
if [ $# -ge 3 -a $# -le 4 -a "$3" = "del" -a "$t_usemode" != "1" ];then delfiletag $f1file $2 $4;exit 0;fi
if [ $# -ge 3 -a $# -le 4 -a "$3" = "sh"  -a "$t_usemode" =  "1" ];then echo "can't use this usemode to exec data!";exit 0;fi
if [ $# -ge 3 -a $# -le 3 -a "$3" = "sh"  ];then getdynpara $f1file $2;fi
if [ $# -ge 4 -a $# -le 4 -a "$3" = "sh"  ];then echo "$4"|sed 's/,//g' >$t_ffile;fi
if [ $# -ge 3 -a $# -le 4 -a "$3" = "sh"  ];then sed -n '/^'#:$2:'/,/^#:/'p $f1file >$t_afile;echo "#!/bin/sh" >$t_gfile;dealimport $t_afile;
   cat $t_afile|sed 's/^-/#/'|sed 's/^importinfo=/#importinfo=/' >>$t_gfile;echo "exit 0">>$t_gfile;exec $t_gfile;exit 0; fi
fi
if [ $# -ge 3 -a $# -ge 3 -a "$3" = "pg"  ];then
  tagflag=6
  getfiletag $f1file $2 >$t_dfile
  cp $t_dfile $t_sfile
  shift
  shift
  i=3
  flag="-"
  while [ x$1 != x ]
  do
  if [ $(expr $i % 2) -eq 1 ];then
    if [ "$1" != "pg" -a "$1" != "sh" ];then echo "err!1006:para err![$1]";>$t_sfile;>$t_dfile;exit 0; fi
    if [ "$1" = "sh" ];then tagflag=8; break; fi
  else
    flag="$flag""-"
	t4="$1"
    cat $t_sfile|sed -n '/^'$flag:$1:'/,/^'$flag':/'p >$t_dfile
    if [ $(wc -l $t_dfile|awk '{print $1}') -le 0 ];then
  	  echo "err!1012:not find the tag![$flag][$1]";>$t_sfile;>$t_dfile;exit 0;
    fi
    cp $t_dfile $t_sfile
  fi
  i=$(expr $i + 1)
  shift
  done
  if [ $tagflag -eq 8 ];then
    shift
    t3=""
	if [ $(head -1 $t_sfile|awk -F: '{print $3}') != "sh" ];then echo "err!1023:tag type err![$flag][$t4]";exit 0;fi
    if [ "$1" =  "" ];then getdynpara $t_dfile "";fi
    if [ "$1" != "" ];then echo "$1"|sed 's/,//g' >$t_ffile; shift; t3="$1";fi
    if [ "$t3" != "" ];then echo "err!1024:参数错误![$t3]";exit 0;fi
	#执行脚本 t_afile 存储不变化的原始脚本文件 -- 子标签内容获取:f1file-->t_sfile/t_dfile-->t_file/t_gfile
	cp $t_sfile $t_afile;
    echo "#!/bin/sh" >$t_gfile;dealimport $t_afile;
	cat $t_afile|sed 's/^-/#/'|sed 's/^importinfo=/#importinfo=/' >>$t_gfile;echo "exit 0">>$t_gfile;exec $t_gfile;exit 0;
  else
    head -1 $t_sfile
    if [ $(expr $i % 2) -eq 0 ];then
      flag="$flag""-"
      grep "^$flag:" $t_sfile
    else
      cat $t_sfile|grep -v "^$flag:"
    fi
  fi
  >$t_sfile;>$t_dfile;exit 0;
fi
fi
fi

#5.域格式处理
if [ $(isdigit "$1") -eq 1 ];then
format="$2"
if [ $(islabel "$2") -eq 1 ];then
if   [ "$2" = "memset"   ];then format="memset(%s,0x0,sizeof(%s));";
elif [ "$2" = "strcpy"   ];then format="strcpy(%s,%s);";
elif [ "$2" = "strncpy"  ];then format="strncpy(%s,%s,sizeof(\$1)-1);";
elif [ "$2" = "printf"   ];then format="printf(\"%%s\$n\",%s);";
elif [ "$2" = "sprintf"  ];then format="sprintf(%s,\"%%s\",%s);";
fi 
fi
FormatFile $u_sfile "$1" "$format" "$3"
exit 0
elif [ "$1" = "format" -a $# -eq 1 ];then
cat<<format
memset  "memset(%s,0x0,sizeof(%s));"
strcpy  "strcpy(%s,%s);"
strncpy "strncpy(%s,%s,sizeof(\\\$1)-1);"
printf  "printf(\\\"%%s\\\$n\\\",%s);"
sprintf "sprintf(%s,\\\"%%s\\\",%s);"
cond1   "<!if(c1)then{f1}elif([c2])then{f2}else{f3}!>"
cond2   "<!if([ \\\$2~/^c1$/ ]&&[ \\\$2~/^c2$/ ]||[ \\\$2~/^c3$/ ])then{f1}elif(c2)then{f2}else{f3}!>"
format
exit 0;
fi

################################################################################
##6.复核功能扩展
################################################################################
#1 数据库操作
if [ "$1" = "sql" -a $# -eq 2 -a $(islabel "$2") -eq 1 ];then 
#sqlstr="select column_name,data_type,COLUMN_TYPE,nvl(column_comment,'null'),IS_NULLABLE from INFORMATION_SCHEMA.COLUMNS where 1=1 and table_name='$2'"
sqlstr="select column_name,replace(replace(replace(replace(COLUMN_TYPE,'(',' '),')',' '),'datetime','char 14'),'blob','varchar 40000'),replace(nvl(column_comment,'null'),' ',''),replace(replace(IS_NULLABLE,'NO','N'),'YES','Y') from INFORMATION_SCHEMA.COLUMNS where 1=1 and table_name='$2'"
runsql "$sqlstr"|sed 's/-//g'|grep -v column_name >$t_dfile
dealorder $t_dfile
exit 0
fi
if [ "$1" = "sql" -a $# -eq 2 -a $(islabel "$2") -ne 1 ];then runsql "$2";exit 0;fi

echo "err!1083:para err!5[$t_usemode]"
exit 1
