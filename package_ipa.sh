#!/bin/bash

# 确保目录干净
echo "准备创建IPA包..."
rm -rf Payload TrollStore-FixedZH.ipa

# 检查tar文件是否存在
TAR_FILE="./_build/TrollStore.tar"
if [ ! -f "$TAR_FILE" ]; then
    echo "错误: 找不到TrollStore.tar文件，请确保项目已正确编译。"
    echo "路径: $TAR_FILE"
    exit 1
fi

# 显示tar文件信息
TAR_SIZE=$(stat -f %z "$TAR_FILE" | awk '{ split( "B KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } printf "%.2f %s", $1, v[s] }')
TAR_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$TAR_FILE")
echo "TAR文件信息:"
echo "- 路径: $TAR_FILE"
echo "- 大小: $TAR_SIZE"
echo "- 修改时间: $TAR_TIME"

# 创建临时和Payload目录
mkdir -p temp_extract Payload

# 解压tar文件
echo "解压TrollStore.tar文件..."
tar -xf "$TAR_FILE" -C temp_extract

# 复制到Payload目录
echo "复制TrollStore.app到Payload目录..."
cp -R temp_extract/TrollStore.app Payload/

# 创建IPA包
echo "正在创建IPA包..."
zip -r TrollStore-FixedZH.ipa Payload

# 清理临时文件
echo "正在清理临时文件..."
rm -rf Payload temp_extract

# 显示创建信息
echo "IPA包已成功创建: TrollStore-FixedZH.ipa"
echo "文件路径: $(pwd)/TrollStore-FixedZH.ipa"
ls -lh TrollStore-FixedZH.ipa 