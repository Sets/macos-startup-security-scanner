#!/bin/bash

echo "🔐 Starting macOS Security Check..."
echo "----------------------------------------"

check_signature() {
    local path_to_check="$1"
    local executable_path="$path_to_check"

    # --- Step 1: Find the actual executable file (especially for .app bundles) ---
    if [[ -d "$path_to_check" && "$path_to_check" == *.app ]]; then
        local plist_path="$path_to_check/Contents/Info.plist"
        if [ -f "$plist_path" ]; then
            local exec_name=$(plutil -extract CFBundleExecutable raw -o - "$plist_path" 2>/dev/null)
            if [ -n "$exec_name" ]; then
                executable_path="$path_to_check/Contents/MacOS/$exec_name"
            fi
        fi
    fi

    # --- Step 2: Pre-flight check ---
    if [ ! -e "$executable_path" ]; then
        return
    fi
    
    # --- Step 3: Assess with Gatekeeper and interpret the result intelligently ---
    local spctl_output
    spctl_output=$(spctl --assess -vv "$executable_path" 2>&1)

    if echo "$spctl_output" | grep -q "accepted"; then
        local origin=$(echo "$spctl_output" | grep "origin=" | cut -d'=' -f2-)
        echo "✅ Gatekeeper Approved: $origin → $executable_path"
    else
        # It was rejected, let's analyze WHY to avoid false alarms.
        if echo "$spctl_output" | grep -q "rejected (the code is valid but does not seem to be an app)"; then
            # This is a helper tool, not a full app. It's signed and safe.
            local origin=$(echo "$spctl_output" | grep "origin=" | cut -d'=' -f2-)
            echo "✅ Signed Helper Tool: $origin → $executable_path"
        elif echo "$spctl_output" | grep -q "invalid API object reference"; then
            # This is a socket, pipe, or other non-code file.
            echo "🤔 INFO: Path is a non-executable type (e.g., socket). This is expected. → $executable_path"
        else
            # If it's rejected for any other reason, it's a genuine warning.
            echo "🚨 WARNING: Gatekeeper Rejected. Reason: $(echo $spctl_output | head -n1) → $executable_path"
        fi
    fi
}

# Extracts the program/binary path from a plist file.
extract_program_path() {
    local plist="$1"
    local path
    path=$(plutil -extract ProgramArguments.0 raw -o - "$plist" 2>/dev/null) || path=$(plutil -extract Program raw -o - "$plist" 2>/dev/null)
    [ -n "$path" ] && echo "$path" && return 0
    return 1
}

# Scans a directory for .plist files and checks their binaries.
scan_directory() {
    local path="$1"
    echo ""
    echo "📂 Scanning Directory: $path"
    echo "----------------------------------------"
    for plist in "$path"/*.plist; do
        [ -e "$plist" ] || continue
        # Handle cases where plist points to a non-existent file after an uninstall
        if ! bin_path=$(extract_program_path "$plist"); then
            # Optionally, uncomment the next line to see which plists are skipped
            # echo "🤔 INFO: Could not find program path in $plist, skipping."
            continue
        fi
        check_signature "$bin_path"
    done
}

# Checks all user-defined login items.
scan_login_items() {
    echo ""
    echo "📌 Checking User Login Items"
    echo "----------------------------------------"
    local login_items
    login_items=$(osascript -l JavaScript -e 'Application("System Events").loginItems().map(i => i.path()).join("\n")' 2>/dev/null)
    
    while IFS= read -r path; do
        [ -n "$path" ] && check_signature "$path"
    done <<< "$login_items"
}

# --- Main script execution ---
echo "✅ Scan started. Using macOS Gatekeeper for verification."

scan_directory "$HOME/Library/LaunchAgents"
scan_directory "/Library/LaunchAgents"
scan_directory "/Library/LaunchDaemons"

scan_login_items

echo ""
echo "✅ Scan complete. All startup items have been reviewed."
