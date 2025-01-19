# Cloudflare DDNS 管理脚本

## 项目介绍

Cloudflare DDNS 管理脚本是一个简单易用的 Bash 脚本，旨在帮助用户管理其 Cloudflare DNS 记录。它允许用户实时更新动态 IP 地址的 A 记录或 AAAA 记录，从而确保子域名始终指向正确的 IP 地址。

### 注意
- **定时任务**：使用crontab -e添加定时任务确保定期执行脚本来更新最新IP。
