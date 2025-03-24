{ 
  pkgs, 
  config,
  ... 
}:

let

  mediaTestScript = pkgs.writeShellScriptBin "mediaTest" ''
   #!/bin/bash

   # Configuration
   DIR_A="${config.drives.storageDrive1}/media/media-transfer-test"  # Directory containing original files to be processed
   DIR_B="${config.drives.storageDrive1}/media/processing-manual-review"  # Directory for manual review after processing
   DIR_C="${config.drives.storageDrive1}/media/photos-test"  # Directory for final disposition of processed photos
   DIR_D="${config.drives.storageDrive1}/media/videos-test"  # Directory for final disposition of processed videos
   EMAIL="chris@dcbond.com"  # Email recipient
   EMAIL_CONTENT_FILE="${config.drives.storageDrive1}/media/email_content.txt"
   > "$EMAIL_CONTENT_FILE"  # Clear email content file
   
   # Logging functions (for email summary)
   log_error() { echo "[ERROR] $1" >&2; }
   log_info() { echo "$1"; }  # Do not append individual log entries to email file
   
   # Summary variables
   moved_count=0
   renamed_count=0
   deleted_duplicates=0
   
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
   
   # Set permissions and ownership in bulk
   file_count=$(find "$DIR_A" -type f | wc -l)
   log_info "Setting permissions and ownership for $file_count files in $DIR_A..."
   find "$DIR_A" -type f -exec chmod 777 {} + -exec chown chris:users {} +
   
   # Define file types that are typically video files
   video_extensions="mp4|mkv|mov|avi|flv|webm|mpg|mpeg|m4v|wmv|vob|ogv|3gp|h264|ts|asf|rm|rmvb|f4v|dat|divx|xvid|swf|tsv|drc|mp2"
   
   # Define file types that are typically photo/image files
   photo_extensions="jpg|jpeg|png|gif|bmp|tiff|tif|webp|heif|heic|raw|cr2|nef|orf|sr2|arw|dng|raf|pef|svg|psd|ai|eps"
   
   # Move non-video and non-photo files to DIR_B
   log_info "Moving non-video and non-photo files to $DIR_B..."
   
   while IFS= read -r -d ''' file; do
       base_name=$(basename -- "$file")
       
       # Remove suffixes like `.~1~` from the filename (if any)
       clean_base_name=$(echo "$base_name" | sed -E 's/(\.~[0-9]+~)$//')
   
       # Extract the last valid extension from the cleaned filename
       extension=$(echo "$clean_base_name" | sed -E 's/.*\.([a-zA-Z0-9]+)$/\1/' | tr '[:upper:]' '[:lower:]')
   
       # If the extension is valid for video or photo, keep the file in DIR_A
       if [[ "$video_extensions" =~ (^|[|])"$extension"($|[|]) || "$photo_extensions" =~ (^|[|])"$extension"($|[|]) ]]; then
           continue
       fi
   
       # If the file is neither a video nor a photo, move it to DIR_B
       mv -- "$file" "$DIR_B/" && ((moved_count++)) || log_error "Failed to move: $file"
   done < <(find "$DIR_A" -type f -print0)
   
   log_info "$moved_count non-media files moved to $DIR_B."
   
   # Renaming files based on their type (video or photo)
   log_info "Renaming files in $DIR_A..."
   
   while IFS= read -r -d ''' file; do
       dir_path=$(dirname -- "$file")
       base_name=$(basename -- "$file")
       
       # Remove suffixes like `.~1~` from the filename (if any)
       clean_base_name=$(echo "$base_name" | sed -E 's/(\.~[0-9]+~)$//')
   
       # Extract the last valid extension from the cleaned filename
       extension=$(echo "$clean_base_name" | sed -E 's/.*\.([a-zA-Z0-9]+)$/\1/' | tr '[:upper:]' '[:lower:]')
   
       if [[ -z "$extension" ]]; then
           continue  # Skip if no valid extension found
       fi
   
       # Handle .jpg files to be renamed to .jpeg
       if [[ "$extension" == "jpg" ]]; then
           extension="jpeg"
       fi
   
       # Determine the type of file (video or photo) and generate a new name
       if [[ "$video_extensions" =~ (^|[|])"$extension"($|[|]) ]]; then
           # It's a video file
           new_filename="video-$(openssl rand -hex 4).$extension"
       elif [[ "$photo_extensions" =~ (^|[|])"$extension"($|[|]) ]]; then
           # It's a photo file
           new_filename="photo-$(openssl rand -hex 4).$extension"
       else
           continue  # Skip unsupported extensions
       fi
   
       # Construct the new filepath
       new_filepath="''${dir_path}/''${new_filename}"
   
       # Rename the file
       log_info "Renaming: $file → $new_filename"
   
       if mv -- "$file" "$new_filepath"; then
           ((renamed_count++))
       else
           log_error "Failed to rename: $file"
       fi
   done < <(find "$DIR_A" -type f -print0)
   
   log_info "$renamed_count files renamed."
   log_info "Renaming process completed!"
   
   # Run rdfind to find and remove duplicate files
   log_info "Identifying duplicate files using rdfind..."
   rdfind_output=$(rdfind -deleteduplicates true "$DIR_A")
   
   # Extract the number of deleted duplicate files
   deleted_duplicates=$(echo "$rdfind_output" | grep -c "Deleting duplicate")
   
   # Final email summary
   {
       echo "Subject: Media-Transfer Processing Report"
       echo "To: $EMAIL"
       echo "From: chris@dcbond.com"
       echo ""
       echo "Summary of Processing Steps:"
       echo "---------------------------------------------"
       echo "Total files processed: $file_count"
       echo "Non-media files moved: $moved_count"
       echo "Media files renamed: $renamed_count"
       echo "Duplicate files deleted: $deleted_duplicates"
   } > "$EMAIL_CONTENT_FILE"
   
   # Send email summary
   msmtp -a default -t "$EMAIL" < "$EMAIL_CONTENT_FILE"
   
   # Clean up
   rm -f "$EMAIL_CONTENT_FILE"
   log_info "Processing complete! Summary email sent."
  '';

in

{
  environment.systemPackages = with pkgs; [
    mediaTestScript
    openssl
    rdfind
  ];
}