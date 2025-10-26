#!/bin/bash

# 📁 1. Lucide icons 폴더 경로
SOURCE_ICONS_DIR="./icons"

# 📁 2. Xcode에서 사용할 xcassets 폴더 경로
DEST_ASSETS_DIR="./output/Icons.xcassets"

# 📄 3. Swift 파일 생성 경로
OUTPUT_SWIFT_FILE="./output/LucideIcons+Generated.swift"

# 🔄 기존 xcassets 제거 후 새로 생성
rm -rf "$DEST_ASSETS_DIR"
mkdir -p "$DEST_ASSETS_DIR"

# 📄 xcassets 루트 Contents.json 생성
cat > "$DEST_ASSETS_DIR/Contents.json" <<EOF
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF

# 스위프트 파일용 코드 시작
swift_code_header='// 🛠️ Auto-generated. Do not edit manually.

public enum LucideIcon: String, CaseIterable {
'
swift_code_enum_footer='}

#if canImport(UIKit)
import UIKit
extension Lucide {
'
swift_code_footer_ios='}
#elseif canImport(AppKit)
import AppKit
extension Lucide {
'
swift_code_footer_common='}
#endif
'

# 아이콘 enum 케이스 누적용 변수
icon_enum_cases=""
# UIKit / AppKit 속성 누적용 변수
icon_entries_ui=""
icon_entries_appkit=""

# 아이콘 파일 목록 저장
svg_files=($(find "$SOURCE_ICONS_DIR" -type f -name "*.svg"))

# 파이프 없이 for 루프 사용
for svg_file in "${svg_files[@]}"; do
    filename=$(basename "$svg_file")
    name="${filename%.*}"

    # Swift-safe 변수명 (a-arrow-down → aArrowDown) - camelCase로 변경
    swift_var_name=$(echo "$name" | tr '-' '_' | sed 's/^[0-9]/num&/')

    # enum case 생성
    icon_enum_case="    case ${swift_var_name} = \"$name\""

    # UIKit 선언
    icon_entry_ui="    public static let \`${swift_var_name}\`: UIImage = UIImage(named: \"$name\", in: Bundle.module, with: nil)!"

    # AppKit 선언 (macOS에선 Bundle.module 없이 사용하는 경우 많음)
    icon_entry_appkit="    public static let \`${swift_var_name}\`: NSImage = Bundle.module.image(forResource: \"$name\")!"

    # 누적
    icon_enum_cases+="$icon_enum_case"$'\n'
    icon_entries_ui+="$icon_entry_ui"$'\n'
    icon_entries_appkit+="$icon_entry_appkit"$'\n'

    # 1. .imageset 생성
    imageset_dir="$DEST_ASSETS_DIR/${name}.imageset"
    mkdir -p "$imageset_dir"
    cp "$svg_file" "$imageset_dir/$filename"

    cat > "$imageset_dir/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "$filename",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    echo "✅ Created imageset for: $name"
done

# 디버깅용: 변수 내용 확인
echo "Enum 케이스 수: $(echo "$icon_enum_cases" | wc -l)"
echo "UIKit 항목 수: $(echo "$icon_entries_ui" | wc -l)"
echo "AppKit 항목 수: $(echo "$icon_entries_appkit" | wc -l)"

# 📦 Swift 파일 최종 조합
{
  echo "$swift_code_header"
  echo "$icon_enum_cases"
  echo "$swift_code_enum_footer"
  echo "$swift_code_footer_ios"
  echo "$icon_entries_ui"
  echo "$swift_code_footer_ios"
  echo "$icon_entries_appkit"
  echo "$swift_code_footer_common"
} > "$OUTPUT_SWIFT_FILE"

echo "🎉 완료: Swift 아이콘 코드 자동 생성 → $OUTPUT_SWIFT_FILE"