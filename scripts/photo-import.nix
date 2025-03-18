{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "renumberPhotos" ''
  #!/bin/sh
  cd ${config.drives.storageDrive1}/media/family-photos-videos/photos
  find $test -type f -print0 | xargs -0 chmod 644
  
  counter=1
  
  find ${config.drives.storageDrive1}/media/family-photos-videos/photos -type f -name '*.jpg' |
      sort -nk2 -t- | while read -r file; do
      ext=${file##*[0-9]} filename=${file%-*}
      [ ! -e  "$filename-$counter$ext" ] &&
      mv -v "$file" "$filename-$counter$ext"
      counter=$((counter+1))
  done # 2>&1 | tee log.txt
'';

pkgs.writeShellScriptBin "photosort" ''
  #!/bin/bash
  
  # variables
  NOW=$(date)
  SUBJ="Bond Server Media Processing Script $NOW"
  DIR1="/home/xixor/hdd1/samba/media-processing"
  DIR2="/home/xixor/hdd1/media/processing-temp"
  DIR3="/home/xixor/hdd1/media/family-photos-videos/videos"
  DIR4="/home/xixor/hdd1/media/processing-manual-review"
  DIR5="/home/xixor/hdd1/media/family-photos-videos/photos"
  DIR5PATTERN="photo-"
  
  {
  
  echo STARTING BOND PHOTO/VIDEO PROCESSING SCRIPT
  
  # error check to ensure variable-defined directories exist
  if [[ ! -d "$DIR1" || ! -d "$DIR2" || ! -d "$DIR3" || ! -d "$DIR4" || ! -d "$DIR5" ]]; then
      echo "missing environment variables or variables aren't directories...exiting"
      exit 1
  fi
  
  # locate all photo, video, and other files in $DIR1 then move to appropriate other directories for further processing
  num_images=0
  num_videos=0
  num_misc=0
  
  while IFS= read -r -d $'\0' file; do
     mime=$( file -b --mime-type "$file" )
     case "\${mime%%/*}" in
        image)
           output="$DIR2"
           ((num_images++))
          ;;
        video)
           output="$DIR3"
           ((num_videos++))
          ;;
        *)
           output="$DIR4"
           ((num_misc++))
          ;;
      esac
      mv "$file" "$output"
  done < <( find "$DIR1" -type f -print0 )
  
  echo moving files: moved $num_images images, $num_videos videos, and $num_misc other files
  
  # delete all empty subdirectories remaining in $DIR1
  if [ "$(ls -A $DIR1)" ]; then
      echo "deleting all empty subdirectories"
      find $DIR1/* -type d -empty -delete;
  else
      echo "no empty subdirectories, skipping"
  fi
  
  # convert all non-.jpg image files in $DIR2 to .jpg
  if [ "$(ls -A $DIR2)" ]; then
      echo "converting images to .jpg"
      find $DIR2 -type f ! -iname '*.jpg' -exec mogrify -format jpg -quality 100 {} + -exec rm {} +;
  else
      echo "no images to convert to .jpg, skipping"
  fi
  
  ## find all duplicate files in $DIR2 and delete
  #if [ "$(ls -A $DIR2)" ]; then
  #    echo "eliminating duplicate photos in this batch"
  #    fdupes -dN $DIR2;
  #else
  #    echo "directory empty, skipping photo duplication detection"
  #fi
  
  # move all .jpg files in $DIR2 to $DIR5
  echo "aggregating database"
  lNum=$(find $DIR5 -type f -iname "*.jpg" -printf "%f\n" | awk -F'[-.]' '{if($2>m)m=$2}END{print m}')
  while IFS= read -r -d $'\0' photo; do mv "$photo" "$DIR5/$DIR5PATTERN$((++lNum)).jpg"
  done < <(find $DIR2 -type f -iname "*.jpg" -print0)
  
  echo PROCESSING SCRIPT FINISHED
  echo "photos & videos available now at https://photos.opticon.dev, username & password saved in Bitwarden under PhotoPrism entry"
  
  } | {
  
  echo "From: \"Bond Server\"<chris@dcbond.com>"
  echo "To: \"Bond Server Recipients\"<chris@dcbond.com>"
  echo "Subject: ${SUBJ}"
  cat /dev/fd/0
  
  } | msmtp -a default chris@dcbond.com, dmiller208@gmail.com
  
'';