#!/bin/bash

# Create Resources directory if it doesn't exist
mkdir -p Resources

# Copy localization file to Resources directory
cp -f Resources/Localizations.json "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Localizations.json"

echo "Copied localization files to app bundle" 