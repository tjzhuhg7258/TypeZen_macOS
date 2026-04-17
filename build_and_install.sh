#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 开始构建 TypeZen macOS 应用...${NC}"

# 1. 确定项目路径
PROJECT_DIR="/Users/zhuhongguang/TypeZenMacOS-Native/TypeZenMacOS"
cd "$PROJECT_DIR" || { echo -e "${RED}❌ 无法进入项目目录: $PROJECT_DIR${NC}"; exit 1; }

# 2. 清理并构建应用
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="$PROJECT_DIR/.DerivedData"

echo -e "${BLUE}📦 正在编译 ${CONFIGURATION} 版本...${NC}"
xcodebuild -project TypeZenMacOS.xcodeproj \
           -scheme TypeZenMacOS \
           -configuration "$CONFIGURATION" \
           -derivedDataPath "$DERIVED_DATA_PATH" \
           clean build \
           SYMROOT="./build" \
           -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 构建失败。请检查错误日志。${NC}"
    exit 1
fi

# 3. 安装到应用程序文件夹
APP_SOURCE="./build/${CONFIGURATION}/TypeZenMacOS.app"
INSTALL_DIR="$HOME/Applications"
APP_DEST="$INSTALL_DIR/TypeZenMacOS.app"

# 确保 ~/Applications 存在
mkdir -p "$INSTALL_DIR"

echo -e "${BLUE}📂 正在安装到 $INSTALL_DIR ...${NC}"

# 如果已存在，先删除
if [ -d "$APP_DEST" ]; then
    rm -rf "$APP_DEST"
fi

cp -R "$APP_SOURCE" "$INSTALL_DIR/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 安装成功！${NC}"
    echo -e "${GREEN}🎉 应用已安装到: $APP_DEST${NC}"
    
    # 4. 打开应用位置
    open -R "$APP_DEST"
    
    # 可选：直接启动
    # open "$APP_DEST"
else
    echo -e "${RED}❌ 安装失败 (复制文件出错)${NC}"
    exit 1
fi
