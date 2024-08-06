nvenchevc() {
    # Define video formats
    VIDEO_FORMATS="mp4|avi|mkv|mov|wmv|flv|webm|m4v|mpg|mpeg|m2v|3gp|3g2|mxf|ts|mts|m2ts|vob|ogv|drc|gifv|mng|qt|yuv|rm|rmvb|asf|amv|m4p|f4v|f4p|f4a|f4b"

    # Function to check if a file is HEVC encoded
    is_hevc() {
        ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$1" | grep -q "hevc"
    }

    # Function to process a single file
    process_file() {
        local input_file="$1"
        local output_file="${input_file%.*}_temp.mp4"

        if [ ! -f "$input_file" ]; then
            echo "Error: File not found: $input_file"
            return 1
        fi

        if is_hevc "$input_file"; then
            echo "Skipping $input_file (already HEVC)"
        else
            echo "Processing $input_file"
            stdbuf -oL ffmpeg -nostdin -i "$input_file" -c:v hevc_nvenc -qp 28 -c:a copy -c:s copy "$output_file" 2>&1 | stdbuf -oL tr '\r' '\n' | tail -n 1
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                mv "$output_file" "$input_file"
                echo "Completed processing $input_file"
            else
                echo "Error processing $input_file"
                rm -f "$output_file"
            fi
        fi
    }

    # Main script
    find . -type f -regextype posix-extended -regex ".*\.($VIDEO_FORMATS)$" -print0 | while IFS= read -r -d '' file; do
        process_file "$file"
    done
}
