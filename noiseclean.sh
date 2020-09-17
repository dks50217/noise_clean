#!/usr/bin/env bash

usage ()
{
    echo 'Usage : noiseclean.sh <input video file> <output video file> <start time> <end time> <sensitivity> <ffmpeg> <sox>'
    exit
}

# Tests for requirements
"$6" -version >/dev/null || { echo >&2 "We require 'ffmpeg' but it's not installed. Install it by 'sudo apt-get install ffmpeg' Aborting."; exit 1; }
"$7" --version >/dev/null || { echo >&2 "We require 'sox' but it's not installed. Install it by 'sudo apt-get install sox' Aborting."; exit 1; }

if [ "$#" -ne 7 ]
then
  usage
fi

if [ ! -e "$1" ]
then
    echo "File not found: '$1'"
    exit
fi

if [ -e "$2" ]
then
	echo "File '$2' already exists"
	exit
fi


inBasename=$(basename "$1")
inExt="${inBasename##*.}"

isVideoStr=`ffprobe -v warning -show_streams "$1" | grep codec_type=video`
if [[ ! -z $isVideoStr ]]
then
    isVideo=1
    echo "Detected '$inBasename' as a video file"
else
    isVideo=0
    echo "Detected '$inBasename' as an audio file"
fi

sampleStart="$3"
sampleEnd="$4"
sensitivity="$5"
tmpVidFile="/tmp/noiseclean_tmpvid.$inExt"
tmpAudFile="/tmp/noiseclean_tmpaud.wav"
noiseAudFile="/tmp/noiseclean_noiseaud.wav"
noiseProfFile="/tmp/noiseclean_noise.prof"
tmpAudCleanFile="/tmp/noiseclean_tmpaud-clean.wav"

echo "Cleaning noise on '$1'..."

if [ $isVideo -eq "1" ]; then
    "$6" -v warning -y -i "$1" -qscale:v 0 -vcodec copy -an "$tmpVidFile"
    "$6" -v warning -y -i "$1" -qscale:a 0 "$tmpAudFile"
else
    cp "$1" "$tmpAudFile"
fi
"$6" -v warning -y -i "$1" -vn -ss "$sampleStart" -t "$sampleEnd" "$noiseAudFile"
"$7" "$noiseAudFile" -n noiseprof "$noiseProfFile"
"$7" "$tmpAudFile" "$tmpAudCleanFile" noisered "$noiseProfFile" "$sensitivity"
if [ $isVideo -eq "1" ]; then
    "$6" -v warning -y -i "$tmpAudCleanFile" -i "$tmpVidFile" -vcodec copy -qscale:v 0 -qscale:a 0 "$2"
else
    cp "$tmpAudCleanFile" "$2"
fi

if [ -f "$noiseProfFile" ] ; then
    rm "$noiseProfFile"
fi

echo "Done"
