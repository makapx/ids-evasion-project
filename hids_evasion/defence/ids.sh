# !/bin/bash

# Find susplicious files in /tmp directory
find_sus_path() {
    # Find all files that have been modified in the last 5 minutes in tmp directory
    # Exclude files that are owned by root
    find /tmp -mmin -5 -type f ! -user root
}

# Log susplicious files in /var/log/ids.log
log_sus_path() {
    echo "Searching for affected files..."
    find_sus_path > /var/log/ids.log

    # If there are no affected files, exit
    if [ ! -s /var/log/ids.log ]; then
        echo "No affected files found"
        exit 0
    fi

    echo "Affected files found."

    # Start monitoring affected files
    echo "Starting monitoring of affected files..."
    while read -r file_path; do
        analyze_file_size_change "$file_path" &
    done < /var/log/ids.log

   # For each file in the log file, get the last writer
    while read -r file_path; do
        analyze_file_size_change "$file_path"
    done < /var/log/ids.log
}

# Analyze file size change
analyze_file_size_change( ) {
    file_path="$1"
    # Dimensione iniziale del file
    initial_size=$(wc -c < "$file_path")

    echo "Looking for $file_path changes..."
    while true; do

    current_size=$(wc -c < "$file_path")

    # If file size has changed, send alert
    if [ "$initial_size" != "$current_size" ]; then
        echo "File $file_path has changed size"
    fi
    sleep 1
    done
}

# Analyze path
analyze_path(){
    echo "Analyzing path $1"

    # Inspect all files in the path and subpaths
    # Send alert if at least one row of file contains one of the string in the /var/log/ids file
    find "$1" -type f -exec grep -q -f /var/log/ids.log {} \; -print

    # If there are no affected files, exit
    if [ ! -s /var/log/ids.log ]; then
        echo "No affected files found"
        exit 0
    fi

    echo "Affected files found."
}

start() {
    echo "Starting IDS"
    log_sus_path
}

stop() {
    echo "Stopping IDS"
    exit 0
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    scan)
        analyze_path "$2"
        ;;
    *)
        echo "Usage: $0 {start|stop|scan <path>}"
        exit 1
esac