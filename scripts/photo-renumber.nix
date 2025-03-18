{ 
  pkgs, 
  config,
  configVars,
  ...
}:

let

  photoRenumberScript = writeShellScriptBin "photoRenumber" ''
    #!/bin/sh
  
    BASE_DIR="${config.drives.storageDrive1}/media/family-photos-videos/photos-test"
    LOG_FILE="/home/chris/rename_log.txt"

    cd "$BASE_DIR" || { echo "Error: Directory not found" | tee -a "$LOG_FILE"; exit 1; } 
    
    find "$BASE_DIR" -type f -print0 | xargs -0 chmod 644
    
    counter=1
    
    find "$BASE_DIR" -type f -name '*.jpg' | sort -V | while IFS= read -r file; do
        # Extract filename and extension
        filename="''${file%.*}"
        ext="''${file##*.}"
    
        base_name=$(echo "$filename" | sed -E 's/-[0-9]+$//')
    
        new_name="''${base_name}-$counter.$ext"
    
        if [ ! -e "$new_name" ]; then
            mv -v "$file" "$new_name"
        else
            echo "Skipping: $new_name already exists" >> "$LOG_FILE"
        fi
    
        counter=$((counter+1))
    done | tee -a "$LOG_FILE"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    photoRenumberScript
  ];

}
