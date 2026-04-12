###Define Functions#######

generate_unique_log_filename() {
    local path=$1
    local base_filename=$2
    local extension=$3
    local counter=1

    if [ ! -f "${path}/${base_filename}${extension}" ]; then
        echo "${base_filename}${extension}"
        return
    fi

    while [ -f "${path}/${base_filename}_${counter}${extension}" ]; do
        counter=$((counter + 1))
    done

    echo "${base_filename}_${counter}${extension}"
}

print_japan_time() {
	echo $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S %Z')
}

log_start() {
	local process_name=$1
	local log_file=$2

	echo "Starting $process_name processing at $(print_japan_time)" 1>> "$log_file"
	echo "$(date +%s)" 
}

log_and_exit_if_error() {
	local error_message=$1
	local log_file=$2

	if [ $? -ne 0 ]; then
		echo "$error_message" 1>> "$log_file"
		exit 1
	fi
}

check_file_exists() {
	local file_path=$1
	local log_file=$2

	if [ ! -f "$file_path" ] || [ ! -s "$file_path" ]; then
		echo "The file $file_path is either missing or its size is 0 byte. Job terminated." >> "$log_file"
		exit 1
	fi
}

log_duration() {
	local start_time=$1
	local log_file=$2
	local process_name=$3

	end=$(date +%s)
	duration=$(( (end - start_time) / 60 ))
	echo "$process_name run time: $duration minutes" 1>> "$log_file"
}

log_end() {
	local process_name=$1
	local log_file=$2
	local error_log=$3

	echo "Completed $process_name processing." 1>> "$log_file"
	echo "------------------------------------------------------------------------" >> "$error_log"
	echo "------------------------------------------------------------------------" >> "$log_file"
}

finalize_process() {
	local process_name=$1
	local start_time=$2
	local output_log=$3
	local error_log=$4
	local file_to_check=$5

	log_and_exit_if_error "Error occurred during ${process_name} processing. Aborting." "${output_log}"
	check_file_exists "${file_to_check}" "${output_log}"
	log_duration "${start_time}" "${output_log}" "${process_name}"
	log_end "${process_name}" "${output_log}" "${error_log}"
}

