#!/bin/bash

# List all folders in the current directory
echo "Available folders:"
folders=()
index=1
for dir in */; do
    if [ -d "$dir" ]; then
        folders+=("$dir")
        echo "$index) $dir"
        ((index++))
    fi
done

# Check if folders were found
if [ ${#folders[@]} -eq 0 ]; then
    echo "No folders found in the current directory."
    exit 1
fi

# Prompt the user to select a folder
read -p "Select a folder by number: " choice

# Validate the user's input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#folders[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

# Get the selected folder
folder="${folders[$choice-1]}"

# Find and make all .sh scripts in the selected folder and subfolders executable
find "$folder" -type f -name "*.sh" -exec chmod +x {} \;
echo "All .sh scripts in '$folder' and its subfolders are now executable."
