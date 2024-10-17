# Cloudflare DDNS 管理脚本

## 项目介绍

Cloudflare DDNS 管理脚本是一个简单易用的 Bash 脚本，旨在帮助用户管理其 Cloudflare DNS 记录。它允许用户实时更新动态 IP 地址的 A 记录或 AAAA 记录，从而确保子域名始终指向正确的 IP 地址。该脚本支持所有 Linux 系统，为用户提供了一种便捷的 DNS 记录管理方式。

### 注意
- **十分简单**：不需要通过命令编辑任何文件，提示什么输入什么。
- **定时任务**：不需要通过crontab -e添加定时任务，脚本自动增删。
- **你就用吧**：一用一个不吱声，我也是小白,扔掉脑子用。

## 如何使用

### 使用脚本

1. 一键命令： 
    ```bash
    apt-get update
    apt-get install -y wget
    wget https://raw.githubusercontent.com/gaikangkai/Cloudflare_DDNS/main/cloudflare_ddns.sh
    chmod +x cloudflare_ddns.sh
    ./cloudflare_ddns.sh
    ```
2. 修改配置
    ```bash
    ./cloudflare_ddns.sh
    ```
    
### 获取 Cloudflare API 密钥

要获取 Cloudflare API 密钥，请按照以下步骤操作：

1. **登录 Cloudflare 账户**：
   - 访问 [Cloudflare官网](https://www.cloudflare.com) 并登录您的账户。

2. **创建 API Token**：
   - 点击右上角的头像，选择 **"My Profile"**。
   - 转到 **"API Tokens"** 标签页。
   - 点击 **"Create Token"** 按钮。
   - 选择 **"Edit DNS"** 模板，然后点击 **"Continue to Summary"**。
   - 在权限设置中，确保选择以下权限：
     - **Zone - Read**：用于读取 DNS 区域信息。
     - **DNS - Edit**：用于编辑 DNS 记录。
   - 点击 **"Create Token"** 完成操作。
   - **复制 API 密钥**，并妥善保存，因为您将需要在脚本中使用它。



## 联系方式
如有问题，请在GitHub上提交issue。
