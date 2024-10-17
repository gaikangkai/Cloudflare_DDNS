#!/bin/bash

# 颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无色

# 配置文件路径
CONFIG_FILE="$HOME/.cfddns_config"

# 主菜单
main_menu() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${GREEN}        Cloudflare DDNS 管理脚本${NC}"
    echo -e "${YELLOW}========================================${NC}"

    if [[ -f "$CONFIG_FILE" ]]; then
        # 读取并显示现有配置信息
        source "$CONFIG_FILE"
        echo -e "已读取现有配置："
        echo -e "邮箱：$EMAIL"
        echo -e "API密钥：$API_KEY"
        echo -e "主域名：$DOMAIN"
        echo -e "子域名：$SUBDOMAIN"
        read -p "是否需要修改以上信息？(y/n)：" MODIFY
        if [[ "$MODIFY" == "y" ]]; then
            input_credentials
        fi
    else
        input_credentials
    fi

    echo -e "${YELLOW}========================================${NC}"
    echo -e "请选择操作："
    echo -e "1) 创建DNS记录并添加定时任务"
    echo -e "2) 删除定时任务"
    echo -e "q) 退出"
    echo -e "${YELLOW}========================================${NC}"
    read -p "请输入选择: " CHOICE

    case "$CHOICE" in
        1)
            create_dns_record
            ;;
        2)
            remove_cron
            ;;
        q)
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重试。${NC}"
            main_menu
            ;;
    esac
}

# 输入凭据
input_credentials() {
    echo -e "${YELLOW}首次运行，请输入以下信息：${NC}"
    read -p "请输入Cloudflare邮箱：" EMAIL
    read -p "请输入Cloudflare API密钥：" API_KEY
    read -p "请输入主域名（如example.com）：" DOMAIN
    read -p "请输入子域名（如www）：" SUBDOMAIN

    # 检查必填项
    if [[ -z "$EMAIL" || -z "$API_KEY" || -z "$DOMAIN" || -z "$SUBDOMAIN" ]]; then
        echo -e "${RED}所有信息均为必填项，请重新运行脚本并填写必要信息。${NC}"
        exit 1
    fi

    echo "EMAIL=\"$EMAIL\"" > "$CONFIG_FILE"
    echo "API_KEY=\"$API_KEY\"" >> "$CONFIG_FILE"
    echo "DOMAIN=\"$DOMAIN\"" >> "$CONFIG_FILE"
    echo "SUBDOMAIN=\"$SUBDOMAIN\"" >> "$CONFIG_FILE"
    echo -e "${GREEN}信息已保存至配置文件：$CONFIG_FILE${NC}"
}

# 创建DNS记录
create_dns_record() {
    source "$CONFIG_FILE"

    # 获取外部IP
    IP=$(curl -s http://ipv4.icanhazip.com)
    echo -e "当前外部IP：$IP"

    # 创建DNS记录的API请求
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      --data "{\"name\":\"$DOMAIN\",\"account\":{\"id\":\"your_account_id\"}}")

    ZONE_ID=$(echo "$RESPONSE" | grep -oP '(?<="id":")[^"]*')
    
    if [[ -z "$ZONE_ID" ]]; then
        echo -e "${RED}获取Zone ID失败，请检查输入的主域名或API密钥。${NC}"
        return
    fi

    # 创建或更新DNS记录
    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      --data "{\"type\":\"A\",\"name\":\"$SUBDOMAIN.$DOMAIN\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")

    if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}DNS记录已成功创建或更新！新IP：$IP${NC}"
    else
        echo -e "${RED}DNS记录创建或更新失败！${NC}"
        echo "$UPDATE_RESPONSE"
    fi

    # 添加定时任务
    read -p "是否添加定时任务来保持实时更新？(y/n)： " ADD_CRON
    if [[ "$ADD_CRON" == "y" ]]; then
        read -p "请输入定时任务的执行时间（以分钟为单位，默认每1分钟执行一次）：" CRON_TIME
        CRON_TIME=${CRON_TIME:-1} # 默认每1分钟执行
        (crontab -l 2>/dev/null; echo "*/$CRON_TIME * * * * /bin/bash $0") | crontab -
        echo -e "${GREEN}定时任务已添加。${NC}"
    else
        echo -e "${YELLOW}未添加定时任务。${NC}"
    fi

    main_menu
}

# 删除定时任务
remove_cron() {
    echo -e "${YELLOW}当前定时任务：${NC}"
    crontab -l

    echo -e -n "${YELLOW}请输入要删除的子域名：${NC}"
    read SUBDOMAIN

    CRON_JOBS=$(crontab -l 2>/dev/null)
    if [[ $CRON_JOBS == *"$SUBDOMAIN"* ]]; then
        # 删除包含指定子域名的cron任务
        NEW_CRON_JOBS=$(echo "$CRON_JOBS" | grep -v "$SUBDOMAIN")
        (echo "$NEW_CRON_JOBS"; echo "") | crontab -
        echo -e "${GREEN}定时任务已删除。${NC}"
    else
        echo -e "${RED}未找到与子域名 '$SUBDOMAIN' 相关的定时任务！${NC}"
    fi

    main_menu
}

# 启动主菜单
main_menu
