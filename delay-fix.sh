#! /bin/bash
############################################################
# Help                                                     #
############################################################
Help() {
	echo -e "\tFix misaligned microphone track and optionally merge primary and secondary audio tracks"
	echo -e "\n\tThis script automatically selects a preset based on the parent folder"
	echo -e "\tand makes a new file <filename>-fixed (original file remains untouched)"
	echo -e "\n\tAutomatic path detection available for:"
	echo -e "\t\t\t\t\t\t[…]/ReplaySorcery/<filename>\n\t\t\t\t\t\t[…]/GpuScreenRecorder/<filename>"
	echo -e "\nUsage:"
	echo -e "\tdelay-fix.sh <filename> [-h] [-o <float>] [-m] [-s <int>] [-e <int>]"
	echo -e "\nOptions:"
	echo -e "\t-h\t\tThis help"
	echo -e "\t-o <float>\toffset - Manual offset provided in seconds"
	echo -e "\t-m\t\tmerge  - Make an output file with a single merged audio track"
	echo -e "\t-s <int>\tstart  - Skip first couple of seconds"
	echo -e "\t-e <int>\tend    - Remove last couple of seconds"
	echo -e "\nExample:"
	echo -e "\t./delay-fix.sh Replay.mkv -m -s 6 -e 6"
	exit 0
}


filename=$(basename -- "$1"); shift
extension="${filename##*.}"
filename="${filename%.*}"
directory=$(basename $(pwd))
video_duration="$(ffprobe -i "$filename.$extension" -show_entries format=duration -v quiet -of csv="p=0")"
a_count="$(ffprobe -loglevel error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$filename.$extension" | wc -l)"

merge="0"
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

start_flag="0"
end_flag="0"

while getopts ":ho:ms:e:" option; do
	case $option in
		h) # display Help
			Help
			;;
		o)	offset="$OPTARG"
			;;
		m)	merge="1"
			;;
		s)	start_flag="$OPTARG"
			;;
		e)	end_flag="$OPTARG"
			;;
		:) # No argument
			echo "Option -${OPTARG} requires an argument."
			exit 1
			;;
		\?) # Invalid option
			echo "Error: Invalid option: -${OPTARG}"
			exit 1
			;;
	esac
done

int_val=${end_time%.*}
start_time=$(($start_time+$start_flag))
end_time="$(($int_val-$start_time-$end_flag))"

echo -e "Offset = $offset"
echo -e "Start time = $start_time"
echo -e "End time = $end_time"
echo -e "Merge status = $merge"
echo -e ""

if [[ $a_count != "0" && $a_count != "1" && $merge == "1" ]]; then
	# audio_mode="-ac 2 -filter_complex amerge=inputs=$a_count"
	limiter="alimiter=level_in=1:level_out=4:limit=0.5:attack=7:release=100:level=disabled"
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
