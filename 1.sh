#!/bin/bash

# ========================================
# IndexNow 自动提交脚本
# ========================================

# 配置区域 - 修改这里的配置
DOMAIN="blog.liaoke.xyz"                           # 你的域名
API_KEY="$INDEXNOW_KEY"                            # 你的IndexNow API密钥
SITEMAP_URL="https://blog.liaoke.xyz/sitemap.xml" # sitemap地址

# ========================================
# 以下代码无需修改
# ========================================

echo "======================================"
echo "IndexNow 自动提交工具"
echo "======================================"
echo "域名: $DOMAIN"
echo "Sitemap: $SITEMAP_URL"
echo ""

# 下载sitemap
echo "[1/3] 下载sitemap..."
curl -s "$SITEMAP_URL" -o sitemap.xml
if [ $? -ne 0 ]; then
    echo "❌ 下载sitemap失败"
    exit 1
fi
echo "✓ sitemap下载成功"

# 提取URL并生成JSON
echo "[2/3] 提取URL..."
URLS=$(grep -oP '(?<=<loc>)[^<]+' sitemap.xml | awk '{printf "\"%s\",", $0}' | sed 's/,$//')

if [ -z "$URLS" ]; then
    echo "❌ 未找到任何URL"
    exit 1
fi

URL_COUNT=$(echo "$URLS" | grep -o "https://" | wc -l)
echo "✓ 找到 $URL_COUNT 个URL"

# 构建JSON
JSON_DATA="{\"host\":\"$DOMAIN\",\"key\":\"$API_KEY\",\"urlList\":[$URLS]}"

# 提交到IndexNow
echo "[3/3] 提交到IndexNow..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.indexnow.org/indexnow" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$JSON_DATA")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo ""
echo "======================================"
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "202" ]; then
    echo "✅ 提交成功！"
    echo "状态码: $HTTP_CODE"
    echo "提交了 $URL_COUNT 个URL"
else
    echo "❌ 提交失败"
    echo "状态码: $HTTP_CODE"
    echo "响应: $BODY"
fi
echo "======================================"

# 清理临时文件
rm -f sitemap.xml
