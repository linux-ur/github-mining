#!/bin/bash
# 42X98aXKvRm1H5CuJFMJP4XNvXPMLephkdF6yebtkJdja1UfnUKz2eaMqpNG2j81p9cVHubpQNuxHXSiFTPL85Jp8ByFcAY
# Script automático para instalar e configurar o XMRig no Ubuntu/Debian

echo "🔄 Atualizando sistema..."
sudo apt update -y && sudo apt upgrade -y

echo "📦 Instalando dependências..."
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "📥 Baixando XMRig..."
cd ~
if [ ! -d "xmrig" ]; then
    git clone https://github.com/xmrig/xmrig.git
fi
cd xmrig
mkdir -p build && cd build

echo "⚙️ Compilando XMRig (pode demorar)..."
cmake ..
make -j$(nproc)

echo "✅ XMRig compilado com sucesso!"

cat > config.json <<EOL
{
  "api": {
    "id": null,
    "worker-id": null
  },
  "http": {
    "enabled": false,
    "host": "127.0.0.1",
    "port": 0,
    "access-token": null,
    "restricted": true
  },
  "autosave": true,
  "version": 1,
  "background": false,
  "colors": true,
  "randomx": {
    "init": 1,
    "numa": true
  },
  "cpu": {
    "enabled": true,
    "huge-pages": true,
    "hw-aes": null,
    "priority": 5,
    "memory-pool": true,
    "max-threads-hint": 75,
    "asm": true,
    "argon2-impl": "auto",
    "cn/0": false,
    "cn-lite/0": false,
    "yield": true
  },
  "opencl": {
    "enabled": false,
    "cache": true,
    "loader": null,
    "platform": "AMD",
    "cn/0": false,
    "cn-lite/0": false
  },
  "cuda": {
    "enabled": false,
    "loader": null,
    "nvml": true,
    "cn/0": false,
    "cn-lite/0": false
  },
  "donate-level": 1,
  "donate-over-proxy": 1,
  "log-file": "xmrig.log",
  "pools": [
    {
      "algo": null,
      "coin": null,
      "url": "pool.hashvault.pro:443",
      "user": "",
      "pass": "git2",
      "rig-id": "rig-001",
      "nicehash": false,
      "keepalive": true,
      "enabled": true,
      "tls": true,
      "tls-fingerprint": "420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14",
      "daemon": false,
      "self-select": null
    }
  ],
  "print-time": 30,
  "health-print-time": 60,
  "retries": 10,
  "retry-pause": 5,
  "syslog": false,
  "user-agent": "xmrig-optimized/1.0",
  "watch": true
}
EOL

echo "⚡ Configuração completa criada em: $(pwd)/config.json"
echo "➡️ Certifique-se de que o 'user' está correto na pool."

echo "🚀 Para rodar o minerador, use:"
echo "cd ~/xmrig/build && ./xmrig -c config.json"
