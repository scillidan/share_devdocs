#!/bin/bash

# Change directory to the location of docs.json
cd ./devdocs/public/docs/ || { echo "Directory not found"; exit 1; }

# Convert docs.json to docs.md markdown table
jq -r '
  ["slug", "release", "type", "name", "db_size", "home", "code", "attribution"],
  ["-","-","-","-","-","-","-","-"],
  (.[] |
    [
      .slug,
      .release // "",
      .type,
      .name,
      ((.db_size / (1024*1024)) | tostring + " MB"),
      ("[🔗](" + .links.home + ")"),
      ("[🔗](" + .links.code + ")"),
      (.attribution | gsub("<br>|\n|<br />"; "<br />"))
    ]
  )
  | @tsv
' docs.json | column -t -s $'\t' > docs.md

# Check if the conversion was successful
if [ $? -eq 0 ]; then
    echo "Conversion successful: docs.md created."
else
    echo "Conversion failed."
fi