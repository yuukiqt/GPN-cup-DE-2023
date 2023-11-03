#!/bin/bash

filename="case02_file.txt" 
grep -o '\[ID: [^]]*\]' "$filename" | awk -F '[:\\[\\]]' '{gsub(/^[ \t]+/, "", $3); print $3}' > id_filtered.txt
