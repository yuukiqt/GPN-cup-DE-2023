#!/bin/bash
# Task - 1
# get all info about files in folder
# input: [path];datetime;path_route_out_csv
# default path is current folder
# output: path_route_out_csv
# csv output: scan_date;path_folder;path_folder/file_name;edit_date;access_date;file_size;row_count

# format start command "./search_by_path.sh [path] "YYYY-MM-DD HH:mm:SS" out_file_name.csv
# example start command "./search_by_path.sh . "2023-11-02 23:01:42" out.csv

# get mb_size [0.xxxx]
function get_file_size {
    local file="$1"
    local size_in_b=$(ls -la "$file" | awk '{print $5}')
    local size_in_mb=$(echo "scale=4; $size_in_b/(1024*1024)" | bc | awk '{printf "%.4f\n", $0}')
    echo "$size_in_mb"
}

function print_file_info {
    local file="$1"
    local file_path=$(realpath "$file")
    local file_name=$(basename -- "$file")
    local file_extension="${file_name##*.}"
    echo "$file_path;$file_name;$file_extension"
}

# get attributes for csv
function get_file_attributes {
    local file="$1"
    local scan_date=$(date +"%Y-%m-%dT%H:%M:%S%z")
    local file_path=$(realpath "$file")
    local file_name=$(basename -- "$file")
    local file_last_modified=$(date -r "$file" +"%Y-%m-%dT%H:%M:%S%z")

    #macos
    if [[ "$OSTYPE" == "darwin"* ]]; then
        formatted_time=$(ls -lTu "$file" | awk '{print $6, $7, $8}' | while read date time
            do
                date -j -f "%b %e %H:%M:%S %Y" "$date $time" "+%Y-%m-%dT%H:%M:%S%z"
            done)

    #linux
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        formatted_time=$(ls -l --time-style="+%b %e %H:%M:%S %Y" -u "$file" | awk '{print $6, $7, $8}' | while read date time
            do
                date -d "$date $time" "+%Y-%m-%dT%H:%M:%S%z"
            done)
    else
        echo "error unsupported platform"
        exit 1
    fi

    local file_last_accessed=$formatted_time
    local file_size=$(get_file_size "$file")
    local line_count=$(wc -l < "$file")
    echo "$scan_date,$file_path,$file_name,$file_last_modified,$file_last_accessed,$file_size,$line_count"
}

# check args
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 [<path>] <datetime> <output_file>"
    exit 1
fi


# get value from args
if [ "$#" -eq 3 ]; then
    path="$1"
    datetime="$2"
    # remove 1 second in datetime for include current datime files
    datetime=$(date -j -f "%Y-%m-%d %H:%M:%S" -v-1S "$datetime" +%Y-%m-%dT%H:%M:%S)
    output_file="$3"
else
    path="."
    datetime="$1"
    output_file="$2"
fi



# search *.txt files
find "$path" -type f -name "*.txt" -newerct "$datetime" |
while IFS= read -r file; 
do 
    get_file_attributes "$file" >> "$output_file"
    print_file_info "$file"
done
