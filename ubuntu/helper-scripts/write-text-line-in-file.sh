#!/bin/bash
# Writes a line of text inside the specified file, if line does not already exist in the file.

# Check args
if [ "$#" -ne 2 ]; then
    echo "Usage: ./write-text-line-in-file.sh <filename> '<text to write>'"
    exit 1
fi

filename=$1
text_to_write=$2

# Check if text already exists
if grep -Fxq "$text_to_write" "$filename"; then
    echo "$text_to_write already exists in $filename. No changes made."
else
    # Append the line to the specified file
    echo "$text_to_write" >> "$filename"
    echo "Line appended to $filename."
fi
