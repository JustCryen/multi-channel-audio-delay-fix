#! /bin/bash

filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"
directory=$(basename $(pwd))
video_duration="$(ffprobe -i "$filename.$extension" -show_entries format=duration -v quiet -of csv="p=0")"
a_count="$(ffprobe -loglevel error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$filename.$extension" | wc -l)"

offset="0"
start_time="0"
end_time="$video_duration"

if [ $directory == "ReplaySorcery" ]; then
	offset="1.50"
	start_time="$offset"
	end_time="$(($video_duration-$offset))"
elif [ $directory == "GpuScreenRecorder" ]; then
	offset="-0.90"
	# offset="5"
fi

#if [ "$2" == "-o" ]; then
#	offset="$3"
#fi

if [ "$3" == "--start" ]; then
	start_time=$(($start_time+$4))
fi
if [ "$5" == "--end" ]; then
	#printf -v int %.0f "$end_time"
	int=${end_time%.*}
	end_time="$(($int-$start_time-$6))"
fi

echo -e "Start time = $start_time"
echo -e "End time = $end_time"

if [[ $a_count != "0" && $a_count != "1" && "$2" == "--merge" ]]; then
	# audio_mode="-ac 2 -filter_complex amerge=inputs=$a_count"
	limiter="alimiter=level_in=1:level_out=1:limit=0.5:attack=7:release=100:level=disabled"
	hi_lo_pass="highpass=f=200,lowpass=f=15000"
	audio_mode="-filter_complex [0:1]volume=2[a1];[0:2]volume=0.75,$limiter[mic];[a1][mic]amix=duration=shortest[a] -map [a]"
else
	audio_mode=" -map 0:a -c:a copy"
	# audio_mode=""
fi
echo $directory
ffmpeg -i "$filename.$extension" -itsoffset "$offset" -i "$filename.$extension" -map 1:v -ss "$start_time" -c:v copy -t "$end_time" $audio_mode "$filename-fixed.$extension"
# -ss "$start_time" -c copy -t "$end_time"
#-filter_complex amerge=inputs=2 
