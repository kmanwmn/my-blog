# SSL 证书申请指南（acme.sh + Let's Encrypt）

## 环境

- 服务器：腾讯云 CVM (Ubuntu 22.04)
- 证书工具：acme.sh
- CA：Let's Encrypt
- 域名 DNS：腾讯云 DNSPod

## 安装 acme.sh

```bash
curl -s https://get.acme.sh | sh -s email=admin@sensing-origin.cn
```

安装后重启终端或 `source ~/.bashrc`。

## 方法一：HTTP 验证（端口 80 可用时）

适用条件：域名指向本服务器，且 80 端口可从外网访问。

```bash
# 停 Nginx 释放 80 端口
sudo systemctl stop nginx

# 申请证书（standalone 模式）
sudo ~/.acme.sh/acme.sh --issue -d your-domain.com --standalone --keylength ec-256

# 重启 Nginx
sudo systemctl start nginx
```

## 方法二：DNS 手动验证（推荐，无需 80 端口）

适用条件：DNS 在腾讯云 DNSPod 管理，但域名未备案或 80 端口不可外网访问。

```bash
# 第一步：获取 TXT 记录值
~/.acme.sh/acme.sh --issue -d your-domain.com --dns \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please --keylength ec-256
```

输出示例：
```
Add the following TXT record:
Domain: '_acme-challenge.your-domain.com'
TXT value: 'aVKNGfeOCYg8GUE6e_QCTGByriz5xWf7Q2pJ1NQ8y3U'
```

第二步：在 DNS 管理平台添加 TXT 记录

| 主机记录 | 记录类型 | 记录值 |
|---------|---------|--------|
| `_acme-challenge.upload` | TXT | 上面输出的值 |

第三步：验证并完成签发

```bash
# 确认 TXT 记录已生效（可多次尝试直到生效）
dig +short TXT _acme-challenge.your-domain.com @8.8.8.8

# 完成证书签发
~/.acme.sh/acme.sh --renew -d your-domain.com --dns \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please --keylength ec-256
```

## 安装证书到 Nginx

```bash
# 创建证书目录
sudo mkdir -p /etc/nginx/ssl/your-domain

# 复制证书
sudo cp ~/.acme.sh/your-domain.com_ecc/fullchain.cer /etc/nginx/ssl/your-domain/
sudo cp ~/.acme.sh/your-domain.com_ecc/your-domain.com.key /etc/nginx/ssl/your-domain/

# 设置权限
sudo chmod 644 /etc/nginx/ssl/your-domain/fullchain.cer
sudo chmod 600 /etc/nginx/ssl/your-domain/your-domain.com.key
```

## Nginx 配置示例

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate     /etc/nginx/ssl/your-domain/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/your-domain/your-domain.com.key;

    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}

# HTTP 跳转 HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}
```

## 配置自动续期

acme.sh 会自动添加 cron 任务。验证：

```bash
crontab -l | grep acme
```

手动续期测试：

```bash
~/.acme.sh/acme.sh --renew -d your-domain.com --keylength ec-256
```

## 切换到 Let's Encrypt（默认 ZeroSSL）

```bash
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
```

## 常用命令

```bash
# 查看证书列表
~/.acme.sh/acme.sh --list

# 查看证书信息
~/.acme.sh/acme.sh --info -d your-domain.com

# 删除证书
~/.acme.sh/acme.sh --remove -d your-domain.com

# 强制续期
~/.acme.sh/acme.sh --renew -d your-domain.com --force --keylength ec-256
```

## 注意事项

1. **Let's Encrypt 速率限制**：每周最多 5 个重复证书，每小时最多 50 个
2. **DNS 验证**：TXT 记录添加后需等待 DNS 生效（通常 30 秒到几分钟）
3. **腾讯云未备案域名**：80 端口会被 DNS 拦截，只能用 DNS 验证
4. **证书有效期**：90 天，acme.sh 自动续期（cron 每天检查）
