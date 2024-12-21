#!/bin/bash

# This script its based off a script generated using ChatGPT

# Assign input argument to variable
new_file=$1

# Calculate checksum
new_file_checksum=$(sha256sum "$new_file" | awk '{ print $1 }')

# Get current file checksum stored in file
current_file_checksum=$(cat checksums/put_item.txt)

# Compare checksums
if [ "$new_file_checksum" != "$current_file_checksum" ]; then
    # Update file containing current file checksum
    echo $new_file_checksum > checksums/put_item.txt
    # Move to where the test file is
    cd src
    # Run test. Redirect output as its not nedeed at this point.
    python3 -m unittest test_put_item.py > /dev/null 2>&1
fi