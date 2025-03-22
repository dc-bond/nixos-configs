{ 
  pkgs, 
  config,
  ... 
}:

let

  mediaTestScript = pkgs.writeShellScriptBin "mediaTest" ''
    #!/bin/bash

    # Configuration
    DIR_A="${config.drives.storageDrive1}/media/videos-test"  # Directory containing original video files
    DIR_B="${config.drives.storageDrive1}/media/processing-manual-review"  # Directory for failed conversions and non-video files
    EMAIL="chris@dcbond.com"  # Email recipient
    EMAIL_CONTENT_FILE="${config.drives.storageDrive1}/media/family-photos-videos/email_content.txt"
    > "$EMAIL_CONTENT_FILE"  # Clear email content file
    
    # Logging functions (for email)
    log_error() { echo "[ERROR] $1" >&2; }
    log_info() { echo "$1" | tee -a "$EMAIL_CONTENT_FILE"; }
    
    # Check if directories exist and are writable
    log_info "Checking if directories exist and are writable..."
    for dir in "$DIR_A" "$DIR_B"; do
        if [ ! -d "$dir" ]; then
            log_error "Directory $dir does not exist. Exiting."
            exit 1
        elif [ ! -w "$dir" ]; then
            log_error "Directory $dir is not writable. Exiting."
            exit 1
        fi
    done
    
    # Ensure all files in DIR_A have read, write, and execute permissions for everyone and are owned by chris:users
    log_info "Setting permissions and ownership for all files in $DIR_A..."
    file_count=$(find "$DIR_A" -type f | wc -l)
    log_info "$file_count files found in $DIR_A. Setting permissions and ownership..."
    
    find "$DIR_A" -type f -print0 | while IFS= read -r -d ''' file; do
        chmod 777 "$file" || log_error "Failed to set permissions for: $file"
        chown chris:users "$file" || log_error "Failed to change ownership for: $file"
    done
    log_info "Permissions and ownership set successfully!"
    
    # Define file types that are typically video files
    video_extensions="mp4|mkv|mov|avi|flv|webm|mpg|mpeg|m4v|wmv|vob|ogv|3gp|h264|ts|asf|rm|rmvb|f4v|dat|divx|xvid|swf|tsv|drc|mp2"
    
    # Move non-video files to DIR_B
    log_info "Moving non-video files to $DIR_B..."
    moved_count=0
    find "$DIR_A" -type f -print0 | while IFS= read -r -d ''' file; do
        if ! echo "$file" | grep -i -qE ".*($video_extensions).*"; then
            mv "$file" "$DIR_B/" || log_error "Failed to move: $file"
            ((moved_count++))
            continue
        fi
        if ! ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$file" 2>/dev/null | grep -q "video"; then
            mv "$file" "$DIR_B/" || log_error "Failed to move: $file"
            ((moved_count++))
        fi
    done
    log_info "$moved_count non-video files moved to $DIR_B."
    
    # Convert remaining video files to .mkv format
    log_info "Converting non-MKV video files in $DIR_A to .mkv format..."
    converted_count=0
    find "$DIR_A" -type f -print0 | while IFS= read -r -d ''' input_file; do
        if [[ "$input_file" =~ \.mkv$ ]]; then
            continue
        fi
        output_file="''${input_file%.*}.mkv"
        ffmpeg -i "$input_file" -c copy "$output_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            rm "$input_file" || log_error "Failed to remove original file: $input_file"
            ((converted_count++))
        else
            mv "$input_file" "$DIR_B/" || log_error "Failed to move failed conversion: $input_file"
        fi
    done
    log_info "$converted_count files converted to MKV."
    
    # Rename all remaining files in DIR_A to the format: video-(date processed)-(random hash).mkv
    log_info "Renaming all MKV files in $DIR_A..."
    renamed_count=0
    current_date=$(date +"%Y%m%d")
    find "$DIR_A" -type f -iname "*.mkv" -print0 | while IFS= read -r -d ''' file; do
        random_hash=$(openssl rand -hex 4)
        new_filename="video-''${current_date}-''${random_hash}.mkv"
        new_filepath="''${DIR_A}/''${new_filename}"
        mv "$file" "$new_filepath" || log_error "Failed to rename: $file"
        ((renamed_count++))
    done
    log_info "$renamed_count files renamed."
    
    # Final summary for email
    log_info "Processing complete!"
    log_info "Summary of Processing Steps:" >> "$EMAIL_CONTENT_FILE"
    log_info "----------------------------------------------------" >> "$EMAIL_CONTENT_FILE"
    log_info "Files processed and actions:" >> "$EMAIL_CONTENT_FILE"
    log_info "Permissions and ownership: $file_count files" >> "$EMAIL_CONTENT_FILE"
    log_info "Moved to $DIR_B: $moved_count files" >> "$EMAIL_CONTENT_FILE"
    log_info "Converted to MKV: $converted_count files" >> "$EMAIL_CONTENT_FILE"
    log_info "Renamed files: $renamed_count files" >> "$EMAIL_CONTENT_FILE"
    
    # Email the terminal output using msmtp
    log_info "Sending terminal output via email..."
    {
        echo "Subject: Video Processing Report"
        echo "To: $EMAIL"
        echo "From: chris@dcbond.com"
        echo ""
        cat "$EMAIL_CONTENT_FILE"
    } | msmtp -a default -t
    
    # Clean up the temporary email content file
    rm -f "$EMAIL_CONTENT_FILE"
  '';

in

{
  environment.systemPackages = with pkgs; [
    mediaTestScript
  ];
}