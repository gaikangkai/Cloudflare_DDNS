#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Cloudflare API 配置
CFKEY="123"  # 替换为你的 Cloudflare Global API Key
CFUSER="123@gmail.com"             # 替换为你的 Cloudflare 账号（邮箱）
CFZONE_NAME="google.com"                  # 域名，例如 google.com
CFRECORD_NAME="test"                       # 主机名，不包含域名部分，例如 test
CFRECORD_TYPE="A"                              # 记录类型：A(IPv4) 或 AAAA(IPv6)
CFTTL=180                                      # TTL 时间，可选范围：120 ~ 86400 秒
FORCE=true                                     # 是否强制更新

# 获取 WAN IP 的服务
WANIPSITE="http://ipv4.icanhazip.com"

# 判断 IPv4 或 IPv6
if [ "$CFRECORD_TYPE" = "AAAA" ]; then
  WANIPSITE="http://ipv6.icanhazip.com"
fi

# 获取当前 WAN IP
WAN_IP=$(curl -s "$WANIPSITE")
if [ -z "$WAN_IP" ]; then
  echo "无法获取 WAN IP，脚本退出。"
  exit 1
fi

# 上次 IP 文件位置
WAN_IP_FILE=$HOME/.cf-wan_ip_$CFRECORD_NAME.txt
OLD_WAN_IP=""
if [ -f "$WAN_IP_FILE" ]; then
  OLD_WAN_IP=$(cat "$WAN_IP_FILE")
fi

# 如果 IP 未变化，且不强制更新，则退出
if [ "$WAN_IP" = "$OLD_WAN_IP" ] && [ "$FORCE" = false ]; then
  echo "WAN IP 未变更，无需更新。"
  exit 0
fi

# 获取 Zone ID 和 Record ID
ID_FILE=$HOME/.cf-id_$CFRECORD_NAME.txt
CFZONE_ID=""
CFRECORD_ID=""
if [ -f "$ID_FILE" ] && [ $(wc -l "$ID_FILE" | awk '{print $1}') -eq 4 ]; then
  CFZONE_ID=$(sed -n '1p' "$ID_FILE")
  CFRECORD_ID=$(sed -n '2p' "$ID_FILE")
else
  echo "更新 Zone ID 和 Record ID..."
  CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" \
    -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" \
    | grep -Po '(?<="id":")[^"]*' | head -1)
  CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME.$CFZONE_NAME" \
    -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" \
    | grep -Po '(?<="id":")[^"]*' | head -1)
  echo -e "$CFZONE_ID\n$CFRECORD_ID\n$CFZONE_NAME\n$CFRECORD_NAME" > "$ID_FILE"
fi

# 更新 DNS 记录
echo "更新 DNS 到 $WAN_IP..."
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "X-Auth-Key: $CFKEY" \
  -H "Content-Type: application/json" \
  --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME.$CFZONE_NAME\",\"content\":\"$WAN_IP\",\"ttl\":$CFTTL}")

# 检查更新结果
if echo "$RESPONSE" | grep -q "\"success\":true"; then
  echo "DNS 更新成功！"
  echo "$WAN_IP" > "$WAN_IP_FILE"
else
  echo "DNS 更新失败！"
  echo "响应：$RESPONSE"
  exit 1
fi
