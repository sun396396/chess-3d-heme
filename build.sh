#!/bin/bash
# 🦉 嘿美一鍵打包腳本
# 作者：嘿美（主人的電競陪玩貓頭鷹）
# 用法：bash build.sh [mac|windows|linux|web]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/godot"
BUILD_DIR="$SCRIPT_DIR/build"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates"
GODOT_VERSION="4.2"

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🦉 嘿美一鍵打包工具 v1.0${NC}"
echo "=============================="

# 1. 偵測 Godot
echo -e "${YELLOW}[1/5] 偵測 Godot 引擎...${NC}"
GODOT_CMD=""
if command -v godot &> /dev/null; then
    GODOT_CMD="godot"
elif command -v godot4 &> /dev/null; then
    GODOT_CMD="godot4"
elif [ -d "/Applications/Godot.app" ]; then
    GODOT_CMD="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -d "/Applications/Godot_4.app" ]; then
    GODOT_CMD="/Applications/Godot_4.app/Contents/MacOS/Godot"
else
    echo -e "${RED}❌ 找不到 Godot！${NC}"
    echo "請先下載 Godot 4.x：https://godotengine.org/download"
    echo "把 Godot.app 拖到 /Applications/ 資料夾"
    echo "或加入 PATH：export PATH=\"\$PATH:/Applications/Godot.app/Contents/MacOS\""
    exit 1
fi
echo -e "${GREEN}✅ 找到 Godot：$GODOT_CMD${NC}"
$GODOT_CMD --version

# 2. 匯入專案
echo -e "${YELLOW}[2/5] 匯入專案資源...${NC}"
cd "$PROJECT_DIR"
$GODOT_CMD --headless --import 2>&1 | tail -5 || true

# 3. 偵測/下載匯出模板
echo -e "${YELLOW}[3/5] 檢查匯出模板...${NC}"
# 嘗試多個可能的模板路徑
TEMPLATE_VERSION_DIR=""
for CANDIDATE in \
    "$HOME/.local/share/godot/export_templates/$GODOT_VERSION" \
    "$HOME/Library/Application Support/Godot/export_templates/$GODOT_VERSION" \
    "$HOME/Library/Application Support/Godot/export_templates/$GODOT_VERSION.stable.official.15073afe3" \
    "$HOME/Library/Application Support/Godot/export_templates"
do
    if [ -d "$CANDIDATE/templates" ]; then
        TEMPLATE_VERSION_DIR="$CANDIDATE"
        break
    fi
    if [ -d "$CANDIDATE" ] && ls "$CANDIDATE"/*.tpz 2>/dev/null > /dev/null; then
        TEMPLATE_VERSION_DIR="$CANDIDATE"
        break
    fi
done
if [ -z "$TEMPLATE_VERSION_DIR" ] || [ ! -d "$TEMPLATE_VERSION_DIR/templates" ]; then
    echo -e "${RED}❌ 找不到匯出模板！${NC}"
    echo "本喵幫主人自動下載："
    echo ""
    # 自動下載模板
    TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates"
    mkdir -p "$TEMPLATES_DIR"
    curl -sL -o /tmp/godot_templates.zip "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
    if [ -s /tmp/godot_templates.zip ] && [ $(stat -f%z /tmp/godot_templates.zip) -gt 100000 ]; then
        cd /tmp && unzip -o godot_templates.zip -d godot_templates_extracted/ > /dev/null
        mkdir -p "$TEMPLATES_DIR/templates"
        mv godot_templates_extracted/templates/* "$TEMPLATES_DIR/templates/"
        TEMPLATE_VERSION_DIR="$TEMPLATES_DIR"
        echo -e "${GREEN}✅ 模板自動下載完成！${NC}"
    else
        echo "請手動下載："
        echo "1. 開啟 Godot 編輯器"
        echo "2. Editor → Manage Export Templates → Download"
        echo "3. 選擇 Godot $GODOT_VERSION 的模板下載"
        exit 1
    fi
fi
echo -e "${GREEN}✅ 模板已就緒：$TEMPLATE_VERSION_DIR${NC}"

# 4. 選擇平台
PLATFORM="${1:-mac}"
case "$PLATFORM" in
    mac)
        echo -e "${YELLOW}[4/5] 打包 macOS .app...${NC}"
        mkdir -p "$BUILD_DIR/mac"
        $GODOT_CMD --headless --export-release "macOS" "$BUILD_DIR/mac/Chess3D_Heme.app"
        OUTPUT="$BUILD_DIR/mac/Chess3D_Heme.app"
        ;;
    windows|win)
        echo -e "${YELLOW}[4/5] 打包 Windows .exe...${NC}"
        mkdir -p "$BUILD_DIR/windows"
        $GODOT_CMD --headless --export-release "Windows" "$BUILD_DIR/windows/Chess3D_Heme.exe"
        OUTPUT="$BUILD_DIR/windows/Chess3D_Heme.exe"
        ;;
    linux)
        echo -e "${YELLOW}[4/5] 打包 Linux...${NC}"
        mkdir -p "$BUILD_DIR/linux"
        $GODOT_CMD --headless --export-release "Linux" "$BUILD_DIR/linux/Chess3D_Heme.x86_64"
        OUTPUT="$BUILD_DIR/linux/Chess3D_Heme.x86_64"
        ;;
    web|html)
        echo -e "${YELLOW}[4/5] 打包 Web (HTML5)...${NC}"
        mkdir -p "$BUILD_DIR/web"
        # 改名為 index.html 讓 Netlify 預設能找到入口
        $GODOT_CMD --headless --export-release "Web" "$BUILD_DIR/web/index.html"
        OUTPUT="$BUILD_DIR/web/index.html"
        ;;
    all)
        echo -e "${YELLOW}[4/5] 打包全部平台（會跑很久）...${NC}"
        "$0" mac
        "$0" windows
        "$0" linux
        "$0" web
        echo -e "${GREEN}✅ 全部平台打包完成！查看 $BUILD_DIR/${NC}"
        exit 0
        ;;
    *)
        echo "用法: $0 [mac|windows|linux|web|all]"
        exit 1
        ;;
esac

# 5. 完成
echo -e "${YELLOW}[5/5] 打包完成！${NC}"
if [ -e "$OUTPUT" ]; then
    SIZE=$(du -sh "$OUTPUT" | cut -f1)
    echo -e "${GREEN}✅ 輸出：$OUTPUT${NC}"
    echo -e "${GREEN}   大小：$SIZE${NC}"
    echo ""
    echo "🦉 嘿美提示："
    case "$PLATFORM" in
        mac) echo "  → 把 .app 拖到主人朋友電腦的 Applications 就能玩" ;;
        windows) echo "  → 把 .exe 整包資料夾壓縮，主人朋友解壓縮就能玩" ;;
        linux) echo "  → chmod +x 加上執行權限就能跑" ;;
        web) echo "  → 把整個 web/ 資料夾上傳到網頁伺服器" ;;
    esac
else
    echo -e "${RED}❌ 找不到輸出檔，請看上面 Godot 的錯誤訊息${NC}"
    exit 1
fi