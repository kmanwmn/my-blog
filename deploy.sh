#!/bin/bash
# 博客部署脚本
# 用法: ./deploy.sh

set -e

cd "$(dirname "$0")"

echo "拉取最新代码..."
git pull

echo "复制文件到 Nginx 目录..."
sudo cp index.html /var/www/blog/
sudo mkdir -p /var/www/blog/blog
sudo cp blog/tech.html /var/www/blog/blog/
sudo cp blog/articles.html /var/www/blog/blog/
sudo cp blog/article.html /var/www/blog/blog/

echo "重载 Nginx..."
sudo systemctl reload nginx

echo "部署完成 ✅"
