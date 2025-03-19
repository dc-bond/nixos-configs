{ 
  pkgs, 
  config 
}:

let

  photoprismImportScript = pkgs.writeShellScriptBin "photoprismImport" ''
    #!/bin/bash
  
    # Define directories
    DIR_A="/path/to/source"
    DIR_B="/path/to/misc"
    DIR_C="/path/to/photos"
    DIR_D="/path/to/videos"
    
    # Ensure required directories exist
    mkdir -p "$DIR_B" "$DIR_C" "$DIR_D"
    
    # Convert all non-JPG image formats to JPG and remove originals
    find "$DIR_A" -type f ! -iname "*.jpg" \( -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -exec mogrify -format jpg -quality 100 {} \; -exec rm {} \;
    
    # Convert all non-MKV video formats to MKV (lossless remuxing) and remove originals
    find "$DIR_A" -type f ! -iname "*.mkv" \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.mpeg" -o -iname "*.mpg" \) | while read -r file; do
        new_file="${file%.*}.mkv"
        ffmpeg -i "$file" -c:v copy -c:a copy -map 0 "$new_file" && rm "$file"
    done
    
    # Move non-photo/video files to DIR_B
    find "$DIR_A" -type f ! \( -iname "*.jpg" -o -iname "*.mkv" \) -exec mv {} "$DIR_B" \;
    
    # Set permissions and ownership for .jpg and .mkv files
    find "$DIR_A" -type f \( -iname "*.jpg" -o -iname "*.mkv" \) -exec chmod 644 {} \;
    find "$DIR_A" -type f \( -iname "*.jpg" -o -iname "*.mkv" \) -exec chown chris:users {} \;
    
    # Determine highest numbered photo in DIR_C
    highest_photo=$(find "$DIR_C" -type f -name "photo-*.jpg" | sed -E 's/.*photo-([0-9]+)\.jpg/\1/' | sort -nr | head -n1)
    highest_photo=${highest_photo:-0}  # Default to 0 if no files exist
    
    # Rename and move photos from DIR_A to DIR_C
    find "$DIR_A" -type f -name "*.jpg" | while read -r file; do
        highest_photo=$((highest_photo + 1))
        mv "$file" "$DIR_C/photo-$highest_photo.jpg"
    done
    
    # Determine highest numbered video in DIR_D
    highest_video=$(find "$DIR_D" -type f -name "video-*.mkv" | sed -E 's/.*video-([0-9]+)\.mkv/\1/' | sort -nr | head -n1)
    highest_video=${highest_video:-0}  # Default to 0 if no files exist
    
    # Rename and move videos from DIR_A to DIR_D
    find "$DIR_A" -type f -name "*.mkv" | while read -r file; do
        highest_video=$((highest_video + 1))
        mv "$file" "$DIR_D/video-$highest_video.mkv"
    done
    
    echo "Processing complete!"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    photoprismImportScript
  ];

}

  ##!/bin/bash
  #
  ## variables
  #NOW=$(date)
  #SUBJ="Bond Server Media Processing Script $NOW"
  #DIR1="/home/xixor/hdd1/samba/media-processing"
  #DIR2="/home/xixor/hdd1/media/processing-temp"
  #DIR3="/home/xixor/hdd1/media/family-photos-videos/videos"
  #DIR4="/home/xixor/hdd1/media/processing-manual-review"
  #DIR5="/home/xixor/hdd1/media/family-photos-videos/photos"
  #DIR5PATTERN="photo-"
  #
  #{
  #
  #echo STARTING BOND PHOTO/VIDEO PROCESSING SCRIPT
  #
  ## error check to ensure variable-defined directories exist
  #if [[ ! -d "$DIR1" || ! -d "$DIR2" || ! -d "$DIR3" || ! -d "$DIR4" || ! -d "$DIR5" ]]; then
  #    echo "missing environment variables or variables aren't directories...exiting"
  #    exit 1
  #fi
  #
  ## locate all photo, video, and other files in $DIR1 then move to appropriate other directories for further processing
  #num_images=0
  #num_videos=0
  #num_misc=0
  #
  #while IFS= read -r -d $'\0' file; do
  #   mime=$( file -b --mime-type "$file" )
  #   case "\${mime%%/*}" in
  #      image)
  #         output="$DIR2"
  #         ((num_images++))
  #        ;;
  #      video)
  #         output="$DIR3"
  #         ((num_videos++))
  #        ;;
  #      *)
  #         output="$DIR4"
  #         ((num_misc++))
  #        ;;
  #    esac
  #    mv "$file" "$output"
  #done < <( find "$DIR1" -type f -print0 )
  #
  #echo moving files: moved $num_images images, $num_videos videos, and $num_misc other files
  #
  ## delete all empty subdirectories remaining in $DIR1
  #if [ "$(ls -A $DIR1)" ]; then
  #    echo "deleting all empty subdirectories"
  #    find $DIR1/* -type d -empty -delete;
  #else
  #    echo "no empty subdirectories, skipping"
  #fi
  #
  ## convert all non-.jpg image files in $DIR2 to .jpg
  #if [ "$(ls -A $DIR2)" ]; then
  #    echo "converting images to .jpg"
  #    find $DIR2 -type f ! -iname '*.jpg' -exec mogrify -format jpg -quality 100 {} + -exec rm {} +;
  #else
  #    echo "no images to convert to .jpg, skipping"
  #fi
  #
  ### find all duplicate files in $DIR2 and delete
  ##if [ "$(ls -A $DIR2)" ]; then
  ##    echo "eliminating duplicate photos in this batch"
  ##    fdupes -dN $DIR2;
  ##else
  ##    echo "directory empty, skipping photo duplication detection"
  ##fi
  #
  ## move all .jpg files in $DIR2 to $DIR5
  #echo "aggregating database"
  #lNum=$(find $DIR5 -type f -iname "*.jpg" -printf "%f\n" | awk -F'[-.]' '{if($2>m)m=$2}END{print m}')
  #while IFS= read -r -d $'\0' photo; do mv "$photo" "$DIR5/$DIR5PATTERN$((++lNum)).jpg"
  #done < <(find $DIR2 -type f -iname "*.jpg" -print0)
  #
  #echo PROCESSING SCRIPT FINISHED
  #echo "photos & videos available now at https://photos.opticon.dev, username & password saved in Bitwarden under PhotoPrism entry"
  #
  #} | {
  #
  #echo "From: \"Bond Server\"<chris@dcbond.com>"
  #echo "To: \"Bond Server Recipients\"<chris@dcbond.com>"
  #echo "Subject: ${SUBJ}"
  #cat /dev/fd/0
  #
  #} | msmtp -a default chris@dcbond.com, dmiller208@gmail.com