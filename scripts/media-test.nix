{ 
  pkgs, 
  config 
}:

let

  mediaTestScript = pkgs.writeShellScriptBin "mediaTest" ''
    #!/bin/bash
    
    # Set directory to scan
    SRC_DIR="${config.drives.storageDrive1}/media/family-photos-videos/photos"
    
    # Set log file path
    LOG_FILE="/home/chris/non_photos.log"
    
    # Ensure log file is empty before starting
    > "$LOG_FILE"
    
    # Scan the directory
    find "$SRC_DIR" -type f | while read -r file; do
        # Check if ImageMagick recognizes the file as a valid image
        if ! identify "$file" >/dev/null 2>&1; then
            echo "Not a photo: $file" | tee -a "$LOG_FILE"
        fi
    done
    
    echo "Scan complete. Non-photo files are logged in: $LOG_FILE"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    mediaTestScript
  ];

}