FROM alpine:latest

# 安装必要工具
RUN apk add --no-cache curl bash ca-certificates

# 下载并安装 sing-box 和 cloudflared
RUN curl -L https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz | tar xz && \
    mv sing-box-*/sing-box /usr/local/bin/ && \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 创建启动脚本
RUN echo '#!/bin/bash \n\
/usr/local/bin/cloudflared tunnel run --token ${TUNNEL_TOKEN} & \n\
printf "{\\\"inbounds\\\":[{\\\"type\\\":\\\"vless\\\",\\\"listen\\\":\\\"0.0.0.0\\\",\\\"listen_port\\\":7860,\\\"users\\\":[{\\\"uuid\\\":\\\"${PROXY_UUID}\\\"}],\\\"transport\\\":{\\\"type\\\":\\\"ws\\\",\\\"path\\\":\\\"/argo\\\"}}],\\\"outbounds\\\":[{\\\"type\\\":\\\"direct\\\",\\\"tag\\\":\\\"direct\\\"},{\\\"type\\\":\\\"wireguard\\\",\\\"tag\\\":\\\"warp\\\",\\\"server\\\":\\\"engage.cloudflareclient.com\\\",\\\"server_port\\\":2408,\\\"local_address\\\":[\\\"172.16.0.2/32\\\"],\\\"mtu\\\":1280}],\\\"route\\\":{\\\"rules\\\":[{\\\"domain_suffix\\\":[\\\"netflix.com\\\",\\\"openai.com\\\",\\\"chatgpt.com\\\"],\\\"outbound\\\":\\\"warp\\\"}]}}" > /config.json \n\
/usr/local/bin/sing-box run -c /config.json' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 7860
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
