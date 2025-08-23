#!/bin/bash

# 1024x1024のアイコンファイルパス
SOURCE_ICON="/Users/midorikawahikaru/Desktop/repo/DayStock/DayStock/Assets.xcassets/AppIcon.appiconset/DayStock.png"
OUTPUT_DIR="/Users/midorikawahikaru/Desktop/repo/DayStock/DayStock/Assets.xcassets/AppIcon.appiconset"

# 必要なサイズを生成
echo "Generating app icons..."

# iPhone Notification - 20pt
sips -z 40 40 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-20@2x.png"
sips -z 60 60 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-20@3x.png"

# iPhone Settings - 29pt  
sips -z 58 58 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-29@2x.png"
sips -z 87 87 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-29@3x.png"

# iPhone Spotlight - 40pt
sips -z 80 80 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-40@2x.png"
sips -z 120 120 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-40@3x.png"

# iPhone App - 60pt (必須)
sips -z 120 120 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-60@2x.png"
sips -z 180 180 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-60@3x.png"

# iPad Notification - 20pt
sips -z 40 40 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-20@2x~ipad.png"

# iPad Settings - 29pt
sips -z 58 58 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-29@2x~ipad.png"

# iPad Spotlight - 40pt
sips -z 80 80 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-40@2x~ipad.png"

# iPad App - 76pt (必須)
sips -z 152 152 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-76@2x.png"

# iPad Pro App - 83.5pt
sips -z 167 167 "$SOURCE_ICON" --out "$OUTPUT_DIR/Icon-83.5@2x.png"

echo "Icon generation complete!"