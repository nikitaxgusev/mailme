#!/bin/bash

WORK_DIR="/home/pi/mailme" #TODO: discover the path of the work dir

#system
NL=$'\n'
DATE=$(date | cut -d " " -f2-4 | tr " " "-")
LOG_OUT="${WORK_DIR}/log.txt"

#image
IMAGE_DIR="${WORK_DIR}/image"
IMAGE_OUT_FILE="${IMAGE_DIR}/image_${DATE}.jpg"
#video
VIDEO_DIR="${WORK_DIR}/video"
VIDEO_OUT_FILE="${VIDEO_DIR}/video_${DATE}.avi"

reciever="nikitaxgusev@gmail.com"

function CheckCommandExit() {
    val_ret=$1
    str_cmd=$2
    str_ret="$str_cmd - OK"
    if [ $val_ret -ne 0 ]; then
        str_ret="Error: command execution is failed $val_ret - $str_cmd"
    fi
    echo "$str_ret" #return value
}

function CheckFilesCounter() {
	current_count=$1
	PATH_TO_DIR=$2
	
	file_limit_count="5"
	if [ "$current_count" == "$file_limit_count" ]
	then
		str_state="Removing files in $PATH_TO_DIR"
		rm -rf $PATH_TO_DIR/*
	else
    	str_state="Current quantity of files: $current_count -  dir: $PATH_TO_DIR"
	fi
	echo $str_state
}

fswebcam -r 1280x720 --no-banner ${IMAGE_OUT_FILE} &>> $LOG_OUT
str_ret=$(CheckCommandExit $? "fswebcam")
str_ret="$str_ret${NL}"
ffmpeg -f v4l2 -r 25 -y -t 00:00:10 -s 640x480 -i /dev/video0 ${VIDEO_OUT_FILE} &>> $LOG_OUT
str_ret="$str_ret$(CheckCommandExit $? "ffmpeg")${NL}"

#checking storage
image_count=$(ls -A $IMAGE_DIR | wc -l)
video_count=$(ls -A $VIDEO_DIR | wc -l)

if [ "$video_count" == "$file_count" ]
then
	rm -rf $VIDEO_DIR
fi
msg_image=$(CheckFilesCounter $image_count $IMAGE_DIR)
msg_video=$(CheckFilesCounter $video_count $VIDEO_DIR)

# Sending mail
SUBJECT="Check the room state"
MESSAGE="Status of executable functions:${NL}$str_ret${NL}${NL}$msg_image${NL}$msg_video${NL}"

echo "$MESSAGE" | s-nail -s "$SUBJECT" -a  ${IMAGE_OUT_FILE} -a  ${VIDEO_OUT_FILE}  $reciever

