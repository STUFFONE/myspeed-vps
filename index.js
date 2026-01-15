const { spawn } = require('child_process');
const http = require('http');

// 1. 核心：下载并配置环境
const setup = () => {
  const cmd = `
    curl -L https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz | tar xz && \
    mv sing-box-*/sing-box ./sb && \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o ./cf && \
    chmod +x ./sb ./cf && \
    echo '{"inbounds":[{"type":"vless","listen":"0.0.0.0","listen_port":10000,"users":[{"uuid":"${process.env.PROXY_UUID}"}],"transport":{"type":"ws","path":"/argo"}}],"outbounds":[{"type":"direct","tag":"direct"},{"type":"wireguard","tag":"warp","server":"engage.cloudflareclient.com","server_port":2408,"local_address":["172.16.0.2/32"],"mtu":1280}],"route":{"rules":[{"domain_suffix":["netflix.com","openai.com","chatgpt.com"],"outbound":"warp"}]}}' > config.json
  `;
  
  const child = spawn(cmd, { shell: true });
  child.on('exit', () => {
    console.log("环境搭建完成，启动服务...");
    spawn('./cf tunnel run --token ' + process.env.TUNNEL_TOKEN, { shell: true, stdio: 'inherit' });
    spawn('./sb run -c config.json', { shell: true, stdio: 'inherit' });
  });
};

setup();

// 2. 核心：建立一个假 Web 服务骗过 Render 的健康检查
http.createServer((req, res) => { res.end("Service Running"); }).listen(process.env.PORT || 10000);

// 3. 核心：每 20 秒打一次日志，防止掉线
setInterval(() => { console.log("Keep-alive heartbeat: " + new Date().toISOString()); }, 20000);
