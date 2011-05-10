#!/bin/bash

function setops_cli
{
	echo Username:
	read USERNAME
	echo "Server [http://85.31.187.124:9024] (Leave default unless you know what you're doing.):"
	read SERVER
	if [ -z $SERVER ]
		then SERVER=http://85.31.187.124:9024
	fi
	echo "Task ID (Get from underscor):"
	read TASK
	echo "Configuration options:"
	echo "USERNAME: $USERNAME"
	echo "SERVER: $SERVER"
	echo "TASK: $TASK"
	echo "Is this correct? (y/n)"
	read correct
	if [[ $correct == "n" ]]
		then exit 9
	fi
}

function t1
{
 while true
 do id=`curl "$SERVER/getAnnouncementID/$USERNAME"`
 wget -O a$id.html http://forums.starwars.com/ann.jspa?annID=$id
 scp -i friend a$id.html friendster@85.31.187.124:announcements
 rm a$id.html
 curl "$SERVER/finishAnnouncementID/$USERNAME/$id"
 if [ -e STOP ]; then echo "Stopping";exit 12;fi
 done
}
function t2
{
 while true
 do id=`curl "$SERVER/getProfileID/$USERNAME"`
 wget -O p$id.html http://forums.starwars.com/profile.jspa?userID=$id
# scp -i friend p$id.html friendster@85.31.187.124:profiles
# rm p$id.html
 curl "$SERVER/finishProfileID/$USERNAME/$id"
 if [ -e STOP ]; then echo "Stopping";exit 12;fi
 done
}

function t3
{
 while true
 do id=`curl "$SERVER/getForumID/$USERNAME"`
 q=`curl http://forums.starwars.com/forum.jspa?forumID=$id`
 pages=$(echo $q|grep -o "[0-9]* </span> <span class=\"bidi\"> pages in this forum"|awk '{print $1}'|tail -n1)
 if [ -z $pages ]; then pages=1;fi
 entries=`echo "($pages*15)-1"|bc`
 for i in `seq 0 15 $entries`;
 do wget -O f$id"_"p$i.html "http://forums.starwars.com/forum.jspa?forumID=$id&start=$i"
 q=`cat f$id"_"p$i.html`
 for j in `echo $q|grep -o "threadID=[0-9]*"|sort -u|tr "=" " "|awk '{print $NF}'`; do echo "Adding thread $j";curl "$SERVER/addThreadID/$USERNAME/$j";done
 scp -i friend f$id"_"p$i.html friendster@85.31.187.124:forums
 rm f$id"_"p$i.html
 done
 curl "$SERVER/finishForumID/$USERNAME/$id"
 if [ -e STOP ]; then echo "Stopping";exit 12;fi
 done
}
function t4
{
 while true
 do id=`curl "$SERVER/getThreadID/$USERNAME"`
 mkdir t$id
 cd t$id
 mkdir html
 q=`curl "http://forums.starwars.com/thread.jspa?threadID=$id&tstart=0"`
 title=$(echo $q|grep -o "<p class=\"jive-page-title\">[^a-zA-Z]*Thread: Knights of the old republic movie tell george to make it"|sed 's/<p class="jive-page-title"> Thread: //')
 echo "ThreadID:: $id">t$id.txt
 echo "ThreadTitle:: $title">>t$id.txt
 pages=$(echo "$q"|grep Pages -A 3|tail -n1|grep -o "[0-9]*")
 if [ -z $pages ]; then pages=1;fi
 entries=`echo "($pages*20)-1"|bc`
 for i in `seq 0 20 $entries`;
 do cd html;wget -O t$id"_"p$i.html "http://forums.starwars.com/thread.jspa?threadID=$id&start=$i";cd ..
 q=`cat html/t$id"_"p$i.html`
 echo $q|grep -oP "<div class=\"jive-message-list\">[^<]*<div class=\"jive-table\">[^<]*<div class=\"jive-messagebox\">.*?</div>[^<]*</div>[^<]*</div>[^<]*"|sed 's/<div class=\"jive-message-list\">/\n/g'|sed '/^[ \t]*$/d' > t$id'_'p$i.raw
 while read line
do if [ "$line" != "\n" ]; then
userID=$(echo $line|grep -o "userID=[0-9]*"|tr "=" " "|awk '{print $NF}')
userName=$(echo $line|grep -o "<span class=\"lucas-username lucas-username-basic\">[ 0-9a-zA-Z._-]*</span>"|head -n1|sed -e 's/<span class="lucas-username lucas-username-basic">//' -e 's\</span>\\')
date=$(echo $line|grep -o "<span class=\"jive-description\"> Posted[^&]*M"|sed 's/<span class="jive-description"> Posted: //')
to=$(echo $line|grep -o "alt=\"in response to:[^\"]*"|sed 's/alt="in response to: //')
messageID=$(echo $line|grep -o "<a name=\"[0-9]*"|sort -u|sed 's/<a name="//')
message=$(echo $line|grep -o "<div class=\"jive-message-body\">.*"|sed -e 's/<div class="jive-message-body">//' -e 's\</div> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </div> </div> </div>\\')
echo "userID:: $userID">>t$id.txt
echo "userName:: $userName">>t$id.txt
echo "to:: $to">>t$id.txt
echo "date:: $date">>t$id.txt
echo "messageID:: $messageID">>t$id.txt
echo "message:: $message">>t$id.txt
echo "----------------------------">>t$id.txt
fi
done<t$id'_'p$i.raw
rm t$id'_'p$i.raw
done
cd ..
scp -r -i friend t$id friendster@85.31.187.124:threads
rm -fr t$id
curl "$SERVER/finishThreadID/$USERNAME/$id"
if [ -e STOP ]; then echo "Stopping";exit 12;fi
done
}

setops_cli

case $TASK in
1)
	t1
;;
2)
	t2
;;
3)
	t3
;;
4)
	t4
;;
esac


