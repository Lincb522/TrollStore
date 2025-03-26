#!/bin/bash

# 这个脚本用于将TrollStore打包为非标准结构的IPA格式

# 设置变量
CURRENT_DIR=$(pwd)
BUILD_DIR="${CURRENT_DIR}/_build"
TEMP_DIR="${BUILD_DIR}/ipa_tmp"
OUTPUT_FILE="${BUILD_DIR}/TrollStore.ipa"

# 创建临时目录
echo "创建临时目录..."
mkdir -p "${TEMP_DIR}/Payload"

# 检查是否存在TrollStore.tar
if [ ! -f "${BUILD_DIR}/TrollStore.tar" ]; then
    echo "构建TrollStore..."
    make
fi

# 解压TrollStore.tar到临时目录
echo "解压TrollStore.tar..."
tar -xf "${BUILD_DIR}/TrollStore.tar" -C "${TEMP_DIR}"

# 移动TrollStore.app到Payload目录下
echo "创建IPA包结构..."
mv "${TEMP_DIR}/TrollStore.app" "${TEMP_DIR}/Payload/"

# 打包为IPA
echo "打包为IPA..."
cd "${TEMP_DIR}"
zip -r "${OUTPUT_FILE}" Payload
cd "${CURRENT_DIR}"

# 清理临时文件
echo "清理临时文件..."
rm -rf "${TEMP_DIR}"

echo "打包完成: ${OUTPUT_FILE}" 