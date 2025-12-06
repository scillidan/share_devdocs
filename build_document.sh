#!/bin/bash

set -e

# Check disk space before conversion
df -h

# Temporary directories for markdown and html files
md_dir="./_markdown"
html_dir="./public/docs"

# Ensure necessary directories exist
mkdir -p "$md_dir"
mkdir -p "$html_dir"

# Navigate to the devdocs directory where Gemfile is located
cd ./devdocs/ || { echo "Directory not found"; exit 1; }

# List documents to build
DOCS=$(bundle exec thor docs:list)

# Variable to hold latest version docs
declare -A latest_md
declare -A latest_html

# Loop over each document to process
for DOC in $DOCS; do
    echo "Processing document: $DOC"

    # Build the specific document
    bundle exec thor docs:download "$DOC"

    # Convert the built document
    find "$html_dir/" -name "$DOC/*.html" | while read -r filepath; do
        relpath=${filepath#./}
        dirname=$(dirname "$relpath")
        # Ensure the markdown directory structure
        mkdir -p "$md_dir/$dirname"
        outfile="$md_dir/$dirname/$(basename "${filepath%.html}.md")"
        html2markdown < "$filepath" > "$outfile"
    done

    # Clean up the temporary HTML build files
    rm -rf "$html_dir/$DOC"

    # Check disk space
    df -h

    # Determine latest version if necessary (this part may require some adaptation)
    version_dir=$(dirname "$DOC")
    base_doc_name=$(basename "$DOC")

    # Update the latest MD and HTML for the latest versions
    if [ ! -z "${latest_md[$base_doc_name]}" ]; then
        latest_md[$base_doc_name]=$(printf '%s\n' "${latest_md[$base_doc_name]}" "$md_dir/$dirname/*.md" | sort | tail -n 1)
    else
        latest_md[$base_doc_name]="$md_dir/$dirname/*.md"
    fi

    if [ ! -z "${latest_html[$base_doc_name]}" ]; then
        latest_html[$base_doc_name]=$(printf '%s\n' "${latest_html[$base_doc_name]}" "$html_dir/$dirname/*.html" | sort | tail -n 1)
    else
        latest_html[$base_doc_name]="$html_dir/$dirname/*.html"
    fi
done

# Create all markdown and html zip files
zip -r devdocs-md-all.zip "$md_dir"/*.md
zip -r devdocs-html-all.zip "$html_dir/*.html"

# Create latest version zip files
for doc in "${!latest_md[@]}"; do
    zip -r "devdocs-md-latest.zip" ${latest_md[$doc]}
    zip -r "devdocs-html-latest.zip" ${latest_html[$doc]}
done

# Check disk space again
df -h

echo "All processing and zipping completed."