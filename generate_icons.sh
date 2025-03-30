#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "使用方法: $0 <源图像路径>"
    exit 1
fi

SOURCE_IMAGE="$1"

# 检查源图像是否存在
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "错误: 源图像文件 '$SOURCE_IMAGE' 不存在"
    exit 1
fi

# 检查ImageMagick是否安装
if ! command -v convert &> /dev/null; then
    echo "错误: 需要安装ImageMagick (convert命令)"
    exit 1
fi

# 创建临时目录
mkdir -p temp_icons

# 生成所有尺寸的图标
echo "开始生成所有尺寸的图标..."

# 图标尺寸定义
ICON_SIZES=(
    "29 AppIcon29x29.png"
    "58 AppIcon29x29@2x.png"
    "87 AppIcon29x29@3x.png"
    "40 AppIcon40x40.png"
    "80 AppIcon40x40@2x.png"
    "120 AppIcon40x40@3x.png"
    "50 AppIcon50x50.png"
    "100 AppIcon50x50@2x.png"
    "57 AppIcon57x57.png"
    "114 AppIcon57x57@2x.png"
    "171 AppIcon57x57@3x.png"
    "60 AppIcon60x60.png"
    "120 AppIcon60x60@2x.png"
    "180 AppIcon60x60@3x.png"
    "72 AppIcon72x72.png"
    "144 AppIcon72x72@2x.png"
    "76 AppIcon76x76.png"
    "152 AppIcon76x76@2x.png"
)

for ICON in "${ICON_SIZES[@]}"; do
    SIZE=$(echo $ICON | cut -d' ' -f1)
    FILENAME=$(echo $ICON | cut -d' ' -f2)
    
    echo "生成 $FILENAME (${SIZE}x${SIZE})..."
    convert "$SOURCE_IMAGE" -resize ${SIZE}x${SIZE} "temp_icons/$FILENAME"
done

echo "所有图标已生成在temp_icons目录中"
echo "可以使用以下命令将它们复制到Resources目录中:"
echo "cp temp_icons/*.png TrollStore/Resources/" 