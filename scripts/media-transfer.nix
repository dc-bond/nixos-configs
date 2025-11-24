{ 
  pkgs, 
  lib,
  configVars,
  config,
  ... 
}:

let

  chrisEmailPasswd = "/run/secrets/chrisEmailPasswd";
  hostData = configVars.hosts.${config.networking.hostName};
  storage = hostData.hardware.storageDrives.data;

  mediaTransferScript = pkgs.writeShellScriptBin "mediaTransfer" ''
    #!/bin/bash

    # Configuration
    DIR_A="/var/lib/nextcloud/data/Chris Bond/files/Bond Family/media-transfer"  # Directory containing original files to be processed
    DIR_B="${storage.mountPoint}/media/media-transfer-review"  # Directory for manual review after processing
    DIR_C="${storage.mountPoint}/media/family-media"  # Directory for final disposition of processed photos and videos
    EMAIL_CONTENT_FILE="${storage.mountPoint}/media/email_content.txt"
    > "$EMAIL_CONTENT_FILE"  # Clear email content file

    # Logging functions (for email summary)
    log_error() { echo "[ERROR] $1" >&2; }
    log_info() { echo "$1"; }  # Do not append individual log entries to email file
    
    # Summary variables
    MOVED_COUNT=0
    RENAMED_COUNT=0
    DELETED_DUPLICATES=0
    
    # Check if directories exist and are writable
    log_info "Checking if directories exist and are writable..."
    for DIR in "$DIR_A" "$DIR_B" "$DIR_C"; do
        if [ ! -d "$DIR" ]; then
            log_error "Directory $DIR does not exist. Exiting."
            exit 1
        elif [ ! -w "$DIR" ]; then
            log_error "Directory $DIR is not writable. Exiting."
            exit 1
        fi
    done 
    
    # Set permissions and ownership in bulk
    FILE_COUNT=$(find "$DIR_A" -type f | wc -l)
    log_info "Setting permissions and ownership for $FILE_COUNT files in $DIR_A..."
    find "$DIR_A" -type f -exec chmod 777 {} + -exec chown chris:users {} +
    
    # Define file types that are typically video files
    VIDEO_EXTENSIONS="mp4|mkv|mov|avi|flv|webm|mpg|mpeg|m4v|wmv|vob|ogv|3gp|h264|ts|asf|rm|rmvb|f4v|dat|divx|xvid|swf|tsv|drc|mp2"
    
    # Define file types that are typically photo/image files
    PHOTO_EXTENSIONS="jpg|jpeg|png|gif|bmp|tiff|tif|webp|heif|heic|raw|cr2|nef|orf|sr2|arw|dng|raf|pef|svg|psd|ai|eps"
    
    # Move non-video and non-photo files to DIR_B
    log_info "Moving non-video and non-photo files to $DIR_B..."
    
    while IFS= read -r -d ''' FILE; do
        BASE_NAME=$(basename -- "$FILE")
        
        # Remove suffixes like `.~1~` from the filename (if any)
        CLEAN_BASE_NAME=$(echo "$BASE_NAME" | sed -E 's/(\.~[0-9]+~)$//')
        
        # Extract the last valid extension from the cleaned filename
        EXTENSION=$(echo "$CLEAN_BASE_NAME" | sed -E 's/.*\.([a-zA-Z0-9]+)$/\1/' | tr '[:upper:]' '[:lower:]')
        
        # If the extension is valid for video or photo, keep the file in DIR_A
        if [[ "$VIDEO_EXTENSIONS" =~ (^|[|])"$EXTENSION"($|[|]) || "$PHOTO_EXTENSIONS" =~ (^|[|])"$EXTENSION"($|[|]) ]]; then
            continue
        fi
        
        # If the file is neither a video nor a photo, move it to DIR_B
        mv -- "$FILE" "$DIR_B/" && ((MOVED_COUNT++)) || log_error "Failed to move: $FILE"
    done < <(find "$DIR_A" -type f -print0)
    
    log_info "$MOVED_COUNT non-media files moved to $DIR_B."
    
    # Renaming files based on their type (video or photo)
    log_info "Renaming files in $DIR_A..."
    
    while IFS= read -r -d $'\0' FILE; do
        DIR_PATH=$(dirname -- "$FILE")
        BASE_NAME=$(basename -- "$FILE")
        
        # Remove suffixes like `.~1~` from the filename (if any)
        CLEAN_BASE_NAME=$(echo "$BASE_NAME" | sed -E 's/(\.~[0-9]+~)$//')
        
        # Extract the last valid extension from the cleaned filename
        EXTENSION=$(echo "$CLEAN_BASE_NAME" | sed -E 's/.*\.([a-zA-Z0-9]+)$/\1/' | tr '[:upper:]' '[:lower:]')
        
        if [[ -z "$EXTENSION" ]]; then
            continue  # Skip if no valid extension found
        fi
        
        # Handle .jpg files to be renamed to .jpeg
        if [[ "$EXTENSION" == "jpg" ]]; then
            EXTENSION="jpeg"
        fi
        
        # Determine the type of file (video or photo) and generate a new name
        NEW_FILEPATH=""
        while [[ -z "$NEW_FILEPATH" || -e "$DIR_C/$NEW_FILENAME" ]]; do
            if [[ "$VIDEO_EXTENSIONS" =~ (^|[|])"$EXTENSION"($|[|]) ]]; then
                # It's a video file
                NEW_FILENAME="video-$(${pkgs.openssl}/bin/openssl rand -hex 4).$EXTENSION"
            elif [[ "$PHOTO_EXTENSIONS" =~ (^|[|])"$EXTENSION"($|[|]) ]]; then
                # It's a photo file
                NEW_FILENAME="photo-$(${pkgs.openssl}/bin/openssl rand -hex 4).$EXTENSION"
            else
                continue 2  # Skip unsupported extensions, continue the next iteration of the outer loop
            fi
            
            # Check if the generated filename already exists in DIR_C
            if [[ -e "$DIR_C/$NEW_FILENAME" ]]; then
                log_info "Filename $NEW_FILENAME already exists in $DIR_C. Generating a new filename..."
                # If it does, continue the loop to generate a new name
                continue
            else
                # If it doesn't, set the new_filepath
                NEW_FILEPATH="$DIR_PATH/$NEW_FILENAME"
            fi
        done
        
        # Rename the file
        log_info "Renaming: $FILE → $NEW_FILENAME"
        
        if mv -- "$FILE" "$NEW_FILEPATH"; then
            ((RENAMED_COUNT++))
        else
            log_error "Failed to rename: $FILE"
        fi
    done < <(find "$DIR_A" -type f -print0)
    
    log_info "$RENAMED_COUNT files renamed."
    log_info "Renaming process completed!"
    
    # Move remaining files from DIR_A to DIR_C
    log_info "Moving remaining media files from $DIR_A to $DIR_C..."
    find "$DIR_A" -type f -exec mv -- {} "$DIR_C/" \; && log_info "Files moved successfully." || log_error "Files could not be moved."
    
    # Run rdfind to find and remove duplicate files in DIR_C
    log_info "Identifying duplicate files using rdfind in $DIR_C..."
    RDFIND_OUTPUT=$(${pkgs.rdfind}/bin/rdfind -deleteduplicates true "$DIR_C")
    
    # Extract the number of deleted duplicate files by looking for the line starting with 'Deleted'
    DELETED_DUPLICATES=$(echo "$RDFIND_OUTPUT" | ${pkgs.gawk}/bin/awk '/^Deleted/{print $2}')
    
    # Validate the number extracted is an integer; defaulting to 0 if it's not
    if ! [[ "$DELETED_DUPLICATES" =~ ^[0-9]+$ ]]; then
        DELETED_DUPLICATES=0
    fi
    
    # Remove the results.txt file after rdfind step
    if [ -f "results.txt" ]; then
        log_info "Removing the results.txt file..."
        rm "results.txt"
        if [ $? -eq 0 ]; then
            log_info "results.txt has been successfully removed."
        else
            log_error "Failed to remove results.txt."
        fi
    else
        log_info "results.txt does not exist or has already been removed."
    fi

    # Update nextcloud database to ensure deleted files are accounted for
    log_info "Updating Nextcloud database to ensure deleted files are accounted for..."
    ${lib.getExe config.services.nextcloud.occ} files:scan --all

    # Generate a date-time string for email subject
    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

    # Final email summary - Only send if files were processed
    if [[ "$FILE_COUNT" -gt 0 ]]; then
        {
            echo "Subject: Bond Media-Transfer Processing Report - $CURRENT_DATETIME"
            echo "To: ${configVars.users.chris.email}, dmiller208@gmail.com"
            echo "From: ${configVars.users.chris.email}"
            echo ""
            echo "Summary of Media Transfer Actions:"
            echo "---------------------------------------------"
            echo "Total files processed: $FILE_COUNT"
            echo "Non-media files moved: $MOVED_COUNT"
            echo "Media files renamed: $RENAMED_COUNT"
            echo "Duplicate files deleted: $DELETED_DUPLICATES"
        } > "$EMAIL_CONTENT_FILE"
    
        # Send email summary
        ${pkgs.msmtp}/bin/msmtp \
        --host=mail.privateemail.com \
        --port=587 \
        --auth=on \
        --user="${configVars.users.chris.email}" \
        --passwordeval "cat ${chrisEmailPasswd}" \
        --tls=on \
        --tls-starttls=on \
        --from="${configVars.users.chris.email}" \
        -t < "$EMAIL_CONTENT_FILE"
    
        # Clean up
        rm -f "$EMAIL_CONTENT_FILE"
        log_info "Processing complete! Summary email sent."
    else
        log_info "No files were processed. No email will be sent."
    fi
  '';

in

 {

  sops.secrets.chrisEmailPasswd = {};

   systemd = {
     services."mediaTransfer" = {
       description = "Transfer media files to PhotoPrism";
       after = [ "network-online.target" ];
       wants = [ "network-online.target" ];
       serviceConfig = {
         ExecStart = "${mediaTransferScript}/bin/mediaTransfer";
         StandardOutput = "journal";
         StandardError = "journal";
       };
     };
   
     timers."mediaTransfer" = {
       description = "Timer for transferring media to PhotoPrism every day at 12:05 AM";
       wantedBy = [ "timers.target" ];
       timerConfig = {
         OnCalendar = "*-*-* 00:05:00";
         Persistent = true; # ensure job runs if missed due to system downtime
       };
     };
   };
 
  environment.systemPackages = with pkgs; [ mediaTransferScript ];

}