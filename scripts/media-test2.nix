{ 
  pkgs, 
  config,
  ... 
}:

let

  mediaTest2Script = pkgs.writeShellScriptBin "mediaTest2" ''
    #!/bin/bash

    # Define variables
    DIR_A="${config.drives.storageDrive1}/media/family-photos-videos/media-transfer-test"  # Directory containing files to be sorted and imported
    DIR_B="${config.drives.storageDrive1}/media/family-photos-videos/manual-review"  # Directory for manually reviewing sorted files after script is run
    DIR_C="${config.drives.storageDrive1}/media/family-photos-videos/photos-test"  # Directory for processed photos
    DIR_D="${config.drives.storageDrive1}/media/family-photos-videos/videos-test"  # Directory for processed videos
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
    
    # Check if directories exist
    log_info "Checking if directories exist..."
    if [ ! -d "$DIR_A" ] || [ ! -d "$DIR_B" ] || [ ! -d "$DIR_C" ] || [ ! -d "$DIR_D" ]; then
        log_error "One or more of the directories do not exist. Exiting."
        exit 1
    fi
    
    # Count total files for progress tracking
    TOTAL_FILES=$(find "$DIR_A" -type f | wc -l)
    CURRENT_FILE=0
    
    # Initialize counters for moved files
    PHOTO_COUNT=0
    VIDEO_COUNT=0
    DIR_B_COUNT=0  # Counter for files moved to DIR_B
    
    # Scan the directory
    find "$DIR_A" -type f | while read -r file; do
        CURRENT_FILE=$((CURRENT_FILE + 1))
        PERCENT=$((CURRENT_FILE * 100 / TOTAL_FILES))
        printf "\rProcessing: %d%% (%d/%d)" "$PERCENT" "$CURRENT_FILE" "$TOTAL_FILES"
    
        # Check if the file is a valid photo
        if identify "$file" >/dev/null 2>&1; then
            mv "$file" "$DIR_C"  # Move photo to DIR_C
            PHOTO_COUNT=$((PHOTO_COUNT + 1))  # Increment photo counter
            continue  # Skip valid photos
        fi
    
        # Check if the file is a valid video using ffprobe
        if ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$file" 2>/dev/null | grep -q "video"; then
            mv "$file" "$DIR_D"  # Move video to DIR_D
            VIDEO_COUNT=$((VIDEO_COUNT + 1))  # Increment video counter
            continue  # Skip valid videos
        fi
    
        # If it's neither a photo nor a video, move it
        log_info "Moving non-media file: $file → $DIR_B"
        mv "$file" "$DIR_B"
        DIR_B_COUNT=$((DIR_B_COUNT + 1))  # Increment DIR_B counter
    done
    
    # 1) Convert all video files to .mkv
    log_info "Converting all video files to .mkv..."
    video_files=$(find "$DIR_D" -type f ! -iname "*.mkv" | wc -l)
    if [ "$video_files" -gt 0 ]; then
        find "$DIR_D" -type f ! -iname "*.mkv" | pv -l -s "$video_files" | while read -r file; do
            output_file="''${file%.*}.mkv"
            log_info "Converting $file → $output_file"
            
            # Perform video conversion with codec specification
            if ffmpeg -i "$file" -c:v libx264 -c:a aac -strict experimental "$output_file" 2>/dev/null; then
                rm "$file" || log_error "Failed to remove original: $file"
            else
                log_error "Conversion failed for: $file"
                mv "$file" "$DIR_B/" || log_error "Failed to move failed conversion: $file"
                DIR_B_COUNT=$((DIR_B_COUNT + 1))  # Increment DIR_B counter
            fi
        done
    else
        log_info "No video files found to convert."
    fi
    
    # 2) Rename video files to timestamp format
    log_info "Renaming video files..."
    find "$DIR_D" -type f -iname "*.mkv" | while read -r file; do
        timestamp=$(date +%Y.%m.%d@%H:%M:%S)
        new_name="$DIR_D/video-$timestamp.mkv"
    
        # Check for filename conflicts and generate unique names
        counter=1
        while [ -e "$new_name" ]; do
            new_name="''${DIR_D}/video-''${timestamp}_$counter.mkv"
            counter=$((counter + 1))
        done
    
        log_info "Renaming: $file → $new_name"
        mv "$file" "$new_name" || log_error "Failed to rename: $file"
        VIDEO_COUNT=$((VIDEO_COUNT + 1))  # Increment video counter after renaming
    done
    
    # 3) Rename photo files to timestamp format and handle extension case
    log_info "Renaming photo files..."
    find "$DIR_C" -type f | while read -r file; do
        timestamp=$(date +%Y.%m.%d@%H:%M:%S)
        extension="''${file##*.}"
        extension="''${extension,,}"  # Convert to lowercase
    
        new_name="$DIR_C/photo-$timestamp.$extension"
    
        # Check for filename conflicts and generate unique names
        counter=1
        while [ -e "$new_name" ]; do
            new_name="''${DIR_C}/photo-''${timestamp}_$counter.$extension"
            counter=$((counter + 1))
        done
    
        log_info "Renaming: $file → $new_name"
        mv "$file" "$new_name" || log_error "Failed to rename: $file"
        PHOTO_COUNT=$((PHOTO_COUNT + 1))  # Increment photo counter after renaming
    done
    
    # 4) Move failed renames to DIR_B
    log_info "Moving failed renames to manual review..."
    find "$DIR_A" -type f | while read -r file; do
        if [ ! -e "$file" ]; then
            log_error "Failed to rename: $file, moving to $DIR_B"
            mv "$file" "$DIR_B" || log_error "Failed to move failed rename: $file"
            DIR_B_COUNT=$((DIR_B_COUNT + 1))  # Increment DIR_B counter
        fi
    done
    
    # 5) Check for any remaining files in DIR_A and move them to DIR_B
    log_info "Checking for remaining files in $DIR_A and moving them to $DIR_B..."
    remaining_files=$(find "$DIR_A" -type f | wc -l)
    if [ "$remaining_files" -gt 0 ]; then
        find "$DIR_A" -type f | while read -r file; do
            log_info "Moving remaining file: $file → $DIR_B"
            mv "$file" "$DIR_B"
            DIR_B_COUNT=$((DIR_B_COUNT + 1))  # Increment DIR_B counter for each moved file
        done
    fi
    
    log_info "Processing complete!"
    
    # Email the terminal output using msmtp
    if [ -s "$EMAIL_CONTENT_FILE" ]; then
        log_info "Sending terminal output via email..."
        {
            echo "Subject: Media Sort and Import Processing Report"
            echo "To: $EMAIL"
            echo "From: chris@dcbond.com"
            echo ""
            cat "$EMAIL_CONTENT_FILE"
            echo ""
            echo "Files processed:"
            echo "  Photos moved: $PHOTO_COUNT"
            echo "  Videos moved: $VIDEO_COUNT"
            echo "  Files moved to DIR_B: $DIR_B_COUNT"
        } | msmtp -a default -t "$EMAIL"
    fi
    
    # Clean up the temporary email content file
    rm -f "$EMAIL_CONTENT_FILE"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    mediaTest2Script
  ];

}