#!/bin/bash
if [ $# -ne 2 ]; then
    echo "This script removes the Windows carriage return character (^M) from input_file & saves it into output_file"
    echo "Usage: $0 input_file output_file"
    exit 1
fi

input_file="$1"
output_file="$2"

# Use 'tr' to remove the Windows carriage return characters (^M)
tr -d '\r' < "$input_file" > "$output_file"

echo "Removed carriage return characters from: $input_file"
echo "                           and saved to: $output_file"
