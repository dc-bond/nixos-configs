{ 
  pkgs, 
  config,
  ... 
}:

let

  mediaTestScript = pkgs.writeShellScriptBin "mediaTest" ''
    #!/bin/bash

    # Configuration
    DIR_A="${config.drives.storageDrive1}/media/family-photos-videos/videos-test2"  # Directory containing original video files
    DIR_B="${config.drives.storageDrive1}/media/family-photos-videos/media-processing"  # Directory for non-video files
    EMAIL="chris@dcbond.com"  # Email recipient
    
    # Start terminal output and email content capture
    EMAIL_CONTENT_FILE="${config.drives.storageDrive1}/media/family-photos-videos/media-processing/email_content.txt"
    > "$EMAIL_CONTENT_FILE"
    
    # Function for error logging
    log_error() {
        echo "[ERROR] $1"
        echo "[ERROR] $1" >> "$EMAIL_CONTENT_FILE"
    }
    
    # Function for logging actions
    log_info() {
        echo "[INFO] $1"
        echo "[INFO] $1" >> "$EMAIL_CONTENT_FILE"
    }
    
    # 1) Check if directories exist
    log_info "Checking if directories exist..."
    if [ ! -d "$DIR_A" ] || [ ! -d "$DIR_B" ]; then
        log_error "One or both of the directories do not exist. Exiting."
        exit 1
    fi
    
    # 2) Identify and move non-video files
    log_info "Scanning $DIR_A for non-video files..."
    non_video_files=$(find "$DIR_A" -type f | wc -l)
    if [ "$non_video_files" -gt 0 ]; then
        find "$DIR_A" -type f | pv -l -s "$non_video_files" | while read -r file; do
            if ! ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$file" 2>/dev/null | grep -q "video"; then
                log_info "Moving non-video file: $file → $DIR_B"
                mv "$file" "$DIR_B" || log_error "Failed to move: $file"
            fi
        done
    else
        log_info "No non-video files found."
    fi
    
    # 3) Convert all videos to .mkv losslessly
    log_info "Converting all video files to .mkv..."
    video_files=$(find "$DIR_A" -type f ! -iname "*.mkv" | wc -l)
    if [ "$video_files" -gt 0 ]; then
        find "$DIR_A" -type f ! -iname "*.mkv" | pv -l -s "$video_files" | while read -r file; do
            output_file="''${file%.*}.mkv"
            log_info "Converting $file → $output_file"
            if ffmpeg -i "$file" -c copy "$output_file" 2>/dev/null; then
                rm "$file" || log_error "Failed to remove original: $file"
            else
                log_error "Conversion failed for: $file"
                mv "$file" "$DIR_B/" || log_error "Failed to move failed conversion: $file"
            fi
        done
    else
        log_info "No video files found to convert."
    fi
    
    # 4) Check for duplicate files and remove them
    log_info "Checking for duplicate .mkv files..."
    declare -A seen
    mkv_files=$(find "$DIR_A" -type f -iname "*.mkv" | wc -l)
    if [ "$mkv_files" -gt 0 ]; then
        find "$DIR_A" -type f -iname "*.mkv" | pv -l -s "$mkv_files" | while read -r file; do
            checksum=$(md5sum "$file" | awk '{print $1}')
            if [[ -n "''${seen[$checksum]}" ]]; then
                log_info "Duplicate found: $file → Removing duplicate."
                rm "$file" || log_error "Failed to delete duplicate: $file"
            else
                seen[$checksum]="$file"
            fi
        done
    else
        log_info "No .mkv files found to check for duplicates."
    fi
    
    # 5) Rename .mkv files to "video-(date).mkv"
    log_info "Renaming .mkv files..."
    mkv_rename_files=$(find "$DIR_A" -type f -iname "*.mkv" | wc -l)
    if [ "$mkv_rename_files" -gt 0 ]; then
        find "$DIR_A" -type f -iname "*.mkv" | pv -l -s "$mkv_rename_files" | while read -r file; do
            timestamp=$(date +%Y.%m.%d@%H:%M:%S)
            new_name="$DIR_A/video-$timestamp.mkv"
            log_info "Renaming: $file → $new_name"
            mv "$file" "$new_name" || log_error "Failed to rename: $file"
            sleep 1  # Ensure unique timestamps for different files
        done
    else
        log_info "No .mkv files found to rename."
    fi
    
    log_info "Processing complete!"
    
    # 6) Email the terminal output using msmtp
    log_info "Sending terminal output via email..."
    
    {
        echo "Subject: Video Processing Report"
        echo "To: $EMAIL"
        echo "From: chris@dcbond.com"
        echo ""
        cat "$EMAIL_CONTENT_FILE"
    } | msmtp -a default -t "$EMAIL"
    
    # Clean up the temporary email content file
    rm -f "$EMAIL_CONTENT_FILE"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    mediaTestScript
  ];

}