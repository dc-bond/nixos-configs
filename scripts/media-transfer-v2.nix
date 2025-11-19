{ 
  pkgs, 
  lib,
  configVars,
  config,
  ... 
}:

let

  chrisEmailPasswd = "/run/secrets/chrisEmailPasswd";

  v2mediaTransferScript = pkgs.writeShellScriptBin "v2mediaTransfer" ''
    #!/bin/bash

    # Configuration
    DIR_A="${config.hostSpecificConfigs.storageDrive1}/samba/media-uploads"  # Samba share for mobile uploads
    DIR_B="${config.hostSpecificConfigs.storageDrive1}/media/media-transfer-review"  # Directory for manual review after processing
    DIR_C="${config.hostSpecificConfigs.storageDrive1}/media/family-media"  # Directory for final disposition of processed photos and videos
    EMAIL_CONTENT_FILE="${config.hostSpecificConfigs.storageDrive1}/media/email_content.txt"
    LOCKFILE="/tmp/mediaTransfer.lock"
    RDFIND_RESULTS="$DIR_C/results.txt"
    
    # Logging functions
    log_error() { echo "[ERROR] $1" >&2; }
    log_info() { echo "$1"; }
    
    # Summary variables
    MOVED_COUNT=0
    RENAMED_COUNT=0
    DELETED_DUPLICATES=0
    MOVE_ERRORS=0
    
    # Email notification function
    send_email() {
        local subject="$1"
        local body="$2"
        
        {
            echo "Subject: $subject"
            echo "To: ${configVars.chrisEmail}, dmiller208@gmail.com"
            echo "From: ${configVars.chrisEmail}"
            echo ""
            echo "$body"
        } | ${pkgs.msmtp}/bin/msmtp \
            --host=mail.privateemail.com \
            --port=587 \
            --auth=on \
            --user="${configVars.chrisEmail}" \
            --passwordeval "cat ${chrisEmailPasswd}" \
            --tls=on \
            --tls-starttls=on \
            --from="${configVars.chrisEmail}" \
            -t
    }
    
    # Error email notification
    send_error_email() {
        local error_msg="$1"
        local body="Media transfer script failed!
        Error: $error_msg
        Please check the system logs: journalctl -u mediaTransfer"
        send_email "[FAILED] Bond Media-Transfer Processing - $(date '+%Y-%m-%d %H:%M:%S')" "$body"
    }
    
    # Set up error handling
    trap 'send_error_email "Script terminated unexpectedly at line $LINENO"' ERR
    
    # Establish file lock to prevent concurrent runs
    if ! mkdir "$LOCKFILE" 2>/dev/null; then
        log_error "Script already running (lockfile exists). Exiting."
        exit 1
    fi
    trap 'rmdir "$LOCKFILE" 2>/dev/null' EXIT
    
    # Clear email content file
    > "$EMAIL_CONTENT_FILE"
    
    # Define file types
    VIDEO_EXTENSIONS="mp4|mkv|mov|avi|flv|webm|mpg|mpeg|m4v|wmv|vob|ogv|3gp|h264|ts|asf|rm|rmvb|f4v|dat|divx|xvid|swf|tsv|drc|mp2"
    PHOTO_EXTENSIONS="jpg|jpeg|png|gif|bmp|tiff|tif|webp|heif|heic|raw|cr2|nef|orf|sr2|arw|dng|raf|pef|svg|psd|ai|eps"
    
    # Helper functions for file type checking
    is_video() {
        local ext="$1"
        [[ "$VIDEO_EXTENSIONS" =~ (^|[|])"$ext"($|[|]) ]]
    }
    
    is_photo() {
        local ext="$1"
        [[ "$PHOTO_EXTENSIONS" =~ (^|[|])"$ext"($|[|]) ]]
    }
    
    is_media() {
        local ext="$1"
        is_video "$ext" || is_photo "$ext"
    }
    
    # Normalize extension variations
    normalize_extension() {
        local ext="$1"
        case "$ext" in
            jpg) echo "jpeg" ;;
            heif) echo "heic" ;;
            tif) echo "tiff" ;;
            *) echo "$ext" ;;
        esac
    }
    
    # Check if directories exist and are writable
    log_info "Checking if directories exist and are writable..."
    REQUIRED_DIRS=("$DIR_A" "$DIR_B" "$DIR_C")
    for DIR in "''${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$DIR" ]]; then
            log_error "Directory $DIR does not exist. Exiting."
            exit 1
        fi
        if [[ ! -w "$DIR" ]]; then
            log_error "Directory $DIR is not writable. Exiting."
            exit 1
        fi
    done
    
    # Count files to process
    FILE_COUNT=$(find "$DIR_A" -type f | wc -l)
    
    # Exit early if no files to process
    if [[ "$FILE_COUNT" -eq 0 ]]; then
        log_info "No files to process. Exiting."
        exit 0
    fi
    
    log_info "Found $FILE_COUNT files to process."
    
    # Check available disk space
    log_info "Checking available disk space..."
    REQUIRED_SPACE=$(du -sb "$DIR_A" 2>/dev/null | cut -f1)
    AVAILABLE_SPACE=$(df -B1 "$DIR_C" | tail -1 | awk '{print $4}')
    
    if [[ $AVAILABLE_SPACE -lt $((REQUIRED_SPACE * 2)) ]]; then
        log_error "Insufficient disk space in $DIR_C. Required: $((REQUIRED_SPACE * 2)) bytes, Available: $AVAILABLE_SPACE bytes"
        send_error_email "Insufficient disk space: need $((REQUIRED_SPACE * 2)) bytes, have $AVAILABLE_SPACE bytes"
        exit 1
    fi
    
    # Process all files in a single pass
    log_info "Processing files..."
    
    while IFS= read -r -d $'\0' FILE; do
        # Set permissions and ownership
        chmod 777 "$FILE" 2>/dev/null || log_error "Failed to chmod: $FILE"
        chown chris:users "$FILE" 2>/dev/null || log_error "Failed to chown: $FILE"
        
        DIR_PATH=$(dirname -- "$FILE")
        BASE_NAME=$(basename -- "$FILE")
        
        # Remove suffixes like .~1~ and extract extension
        BASE_NAME="''${BASE_NAME%.~[0-9]~}"
        EXTENSION="''${BASE_NAME##*.}"
        EXTENSION="''${EXTENSION,,}"  # Lowercase
        
        # Skip if no valid extension
        if [[ -z "$EXTENSION" || "$EXTENSION" == "$BASE_NAME" ]]; then
            log_info "Skipping file with no extension: $FILE"
            continue
        fi
        
        # Normalize extension
        EXTENSION=$(normalize_extension "$EXTENSION")
        
        # If not media, move to review directory
        if ! is_media "$EXTENSION"; then
            if mv -- "$FILE" "$DIR_B/"; then
                ((MOVED_COUNT++))
                log_info "Moved non-media file to review: $BASE_NAME"
            else
                log_error "Failed to move non-media file: $FILE"
            fi
            continue
        fi
        
        # Determine prefix based on file type
        if is_video "$EXTENSION"; then
            PREFIX="video"
        elif is_photo "$EXTENSION"; then
            PREFIX="photo"
        else
            log_error "Unexpected state: $FILE passed is_media but not is_video or is_photo"
            continue
        fi
        
        # Generate unique filename with limited retries
        NEW_FILEPATH=""
        for attempt in {1..10}; do
            NEW_FILENAME="$PREFIX-$(${pkgs.openssl}/bin/openssl rand -hex 4).$EXTENSION"
            NEW_FILEPATH="$DIR_PATH/$NEW_FILENAME"
            
            # Check if filename already exists in destination
            if [[ ! -e "$DIR_C/$NEW_FILENAME" ]]; then
                break
            fi
            
            if [[ $attempt -eq 10 ]]; then
                log_error "Could not generate unique filename after 10 attempts for: $FILE"
                continue 2
            fi
            
            log_info "Filename collision detected, retrying... (attempt $attempt)"
        done
        
        # Rename the file
        if mv -- "$FILE" "$NEW_FILEPATH"; then
            ((RENAMED_COUNT++))
            log_info "Renamed: $BASE_NAME → $NEW_FILENAME"
        else
            log_error "Failed to rename: $FILE"
        fi
        
    done < <(find "$DIR_A" -type f -print0)
    
    log_info "Processing complete: $RENAMED_COUNT media files renamed, $MOVED_COUNT non-media files moved to review."
    
    # Move renamed files from DIR_A to DIR_C
    if [[ $RENAMED_COUNT -gt 0 ]]; then
        log_info "Moving renamed media files from $DIR_A to $DIR_C..."
        
        while IFS= read -r -d $'\0' FILE; do
            if ! mv -- "$FILE" "$DIR_C/"; then
                log_error "Failed to move: $FILE"
                ((MOVE_ERRORS++))
            fi
        done < <(find "$DIR_A" -type f -print0)
        
        log_info "Files moved to final destination."
        
        # Run rdfind to identify and remove duplicates
        log_info "Identifying duplicate files using rdfind in $DIR_C..."
        RDFIND_OUTPUT=$(${pkgs.rdfind}/bin/rdfind -deleteduplicates true "$DIR_C" 2>&1)
        
        # Extract the number of deleted duplicate files
        DELETED_DUPLICATES=$(echo "$RDFIND_OUTPUT" | ${pkgs.gawk}/bin/awk '/^Deleted/{print $2}')
        
        # Validate the number extracted is an integer
        if ! [[ "$DELETED_DUPLICATES" =~ ^[0-9]+$ ]]; then
            DELETED_DUPLICATES=0
        fi
        
        log_info "Deleted $DELETED_DUPLICATES duplicate files."
        
        # Remove the results.txt file after rdfind
        if [[ -f "$RDFIND_RESULTS" ]]; then
            rm "$RDFIND_RESULTS" && log_info "Removed rdfind results.txt" || log_error "Failed to remove results.txt"
        fi
    else
        log_info "No media files to move or deduplicate."
        DELETED_DUPLICATES=0
    fi
    
    # Generate final summary email
    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
    
    EMAIL_BODY="Summary of Media Transfer Actions:
    ---------------------------------------------
    Total files processed: $FILE_COUNT
    Non-media files moved to review: $MOVED_COUNT
    Media files renamed: $RENAMED_COUNT
    Files failed to move: $MOVE_ERRORS
    Duplicate files deleted: $DELETED_DUPLICATES
    
    Upload location: $DIR_A
    Review location: $DIR_B
    Final location: $DIR_C"
    
    send_email "Bond Media-Transfer Processing Report - $CURRENT_DATETIME" "$EMAIL_BODY"
    
    log_info "Processing complete! Summary email sent."
    
    # Clean up
    rm -f "$EMAIL_CONTENT_FILE" 
  '';

in

 {

  sops.secrets.chrisEmailPasswd = {};

   systemd = {
     services."v2mediaTransfer" = {
       description = "transfer media files to photoprism";
       after = [ "network-online.target" ];
       wants = [ "network-online.target" ];
       serviceConfig = {
         ExecStart = "${mediaTransferScript}/bin/v2mediaTransfer";
         StandardOutput = "journal";
         StandardError = "journal";
       };
     };
     #timers."mediaTransfer" = {
     #  description = "Timer for transferring media to PhotoPrism every day at 12:05 AM";
     #  wantedBy = [ "timers.target" ];
     #  timerConfig = {
     #    OnCalendar = "*-*-* 00:05:00";
     #    Persistent = true; # ensure job runs if missed due to system downtime
     #  };
     #};
   };
 
  environment.systemPackages = with pkgs; [ v2mediaTransferScript ];

}