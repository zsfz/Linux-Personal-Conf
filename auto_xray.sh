#!/bin/bash
set -e  # 遇到错误立即退出脚本

# 定义颜色输出（可选，用于更清晰的提示）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 第一步：安装Xray
echo -e "${YELLOW}[1/6] 正在安装Xray...${NC}"
if ! bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; then
    echo -e "${RED}Xray安装失败！${NC}"
    exit 1
fi
echo -e "${GREEN}Xray安装成功！${NC}"

# 第二步：生成UUID
echo -e "${YELLOW}[2/6] 正在生成UUID...${NC}"
UUID=$(xray uuid)
if [ -z "$UUID" ]; then
    echo -e "${RED}UUID生成失败！${NC}"
    exit 1
fi
echo -e "${GREEN}UUID生成成功：$UUID${NC}"

# 第三步：生成Reality公钥和私钥
echo -e "${YELLOW}[3/6] 正在生成Reality密钥对...${NC}"
# 捕获xray x25519的输出并提取私钥和公钥（Password对应公钥）
X25519_OUTPUT=$(xray x25519)
PRIVATE_KEY=$(echo "$X25519_OUTPUT" | grep "PrivateKey" | awk -F ': ' '{print $2}')
PUBLIC_KEY=$(echo "$X25519_OUTPUT" | grep "Password" | awk -F ': ' '{print $2}')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo -e "${RED}Reality密钥对生成失败！${NC}"
    exit 1
fi
echo -e "${GREEN}Reality私钥生成成功：$PRIVATE_KEY${NC}"
echo -e "${GREEN}Reality公钥生成成功：$PUBLIC_KEY${NC}"

# 第四步：写入Xray配置文件
echo -e "${YELLOW}[4/6] 正在写入Xray配置文件...${NC}"
CONFIG_PATH="/usr/local/etc/xray/config.json"
# 备份原有配置（如果存在）
if [ -f "$CONFIG_PATH" ]; then
    mv "$CONFIG_PATH" "${CONFIG_PATH}.bak_$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}已备份原有配置文件为：${CONFIG_PATH}.bak_$(date +%Y%m%d%H%M%S)${NC}"
fi

# 写入新配置（替换UUID、私钥）
cat > "$CONFIG_PATH" << EOF
{
  "inbounds": [
    {
      "port": 1225,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.apple.com:443",
          "xver": 0,
          "serverNames": [
            "www.apple.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            ""
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private",
          "geoip:cn"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
EOF

# 验证配置文件是否写入成功
if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}配置文件写入失败！${NC}"
    exit 1
fi
echo -e "${GREEN}Xray配置文件写入成功：$CONFIG_PATH${NC}"

# 第五步：禁用防火墙并重启Xray
echo -e "${YELLOW}[5/6] 正在禁用防火墙并重启Xray服务...${NC}"
# 禁用ufw防火墙
if command -v ufw &> /dev/null; then
    ufw disable &> /dev/null
    echo -e "${GREEN}ufw防火墙已禁用${NC}"
else
    echo -e "${YELLOW}未检测到ufw防火墙，跳过禁用步骤${NC}"
fi

# 重启Xray服务
if ! systemctl restart xray; then
    echo -e "${RED}Xray服务重启失败！${NC}"
    exit 1
fi
# 设置Xray开机自启（可选，增加实用性）
systemctl enable xray &> /dev/null
echo -e "${GREEN}Xray服务已重启并设置开机自启${NC}"

# 第六步：获取服务器IP并生成客户端链接
echo -e "${YELLOW}[6/6] 正在生成客户端链接...${NC}"
# 获取服务器公网IP（优先获取IPv4）
SERVER_IP=$(curl -s icanhazip.com || curl -s ifconfig.me || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    echo -e "${YELLOW}无法自动获取服务器公网IP，请手动替换链接中的IP地址${NC}"
    SERVER_IP="你的服务器公网IP"
else
    echo -e "${GREEN}获取服务器公网IP成功：$SERVER_IP${NC}"
fi

# 生成VLESS客户端链接
CLIENT_LINK="vless://$UUID@$SERVER_IP:1225?flow=xtls-rprx-vision&encryption=none&security=reality&sni=www.apple.com&pbk=$PUBLIC_KEY&fp=chrome#$SERVER_IP"

# 输出最终结果
echo -e "\n========================================"
echo -e "${GREEN}所有步骤执行完成！${NC}"
echo -e "${GREEN}Xray客户端链接如下：${NC}"
echo -e "$CLIENT_LINK"
echo -e "========================================\n"

# 可选：将链接保存到本地文件
echo "$CLIENT_LINK" > /root/xray_client_link.txt
echo -e "${GREEN}客户端链接已保存到：/root/xray_client_link.txt${NC}"

# 静默检查并安装qrencode
if ! command -v qrencode &> /dev/null; then
    # 静默安装
    if [ -f /etc/debian_version ]; then
        apt-get update > /dev/null 2>&1
        apt-get install -y qrencode > /dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then
        yum install -y qrencode > /dev/null 2>&1
    elif [ -f /etc/arch-release ]; then
        pacman -S --noconfirm qrencode > /dev/null 2>&1
    fi
fi

# 生成二维码
if command -v qrencode &> /dev/null; then
    echo -e "\n${GREEN}二维码：${NC}"
    echo -e "========================================"
    qrencode -t ANSIUTF8 "$CLIENT_LINK"
    echo -e "========================================"
fi

