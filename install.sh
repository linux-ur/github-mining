#!/bin/bash
set -e

ARCH=$(uname -m)
CPU_CORES=$(nproc)

echo "Quantos % da CPU você deseja usar? (1-100)"
read -r CPU_PERCENT
CPU_PERCENT=${CPU_PERCENT:-90}
if ! [[ "$CPU_PERCENT" =~ ^[0-9]+$ ]] || [ "$CPU_PERCENT" -lt 1 ] || [ "$CPU_PERCENT" -gt 100 ]; then
    echo "Valor inválido. Usando 90%."
    CPU_PERCENT=90
fi

if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
    IS_MOBILE=true
    PRIORITY=0
    YIELD=true
else
    IS_MOBILE=false
    PRIORITY=5
    YIELD=false
fi

MEMTOTAL_KB=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
RESERVE_KB=$((IS_MOBILE == true ? 4194304 : 2097152))
AVAILABLE_KB=$((MEMTOTAL_KB > RESERVE_KB ? MEMTOTAL_KB - RESERVE_KB : 0))
HUGEPAGES=$((AVAILABLE_KB / 2048))
[ "$HUGEPAGES" -gt 0 ] && echo "$HUGEPAGES" | sudo tee /proc/sys/vm/nr_hugepages >/dev/null

[ "$IS_MOBILE" = false ] && {
    echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled >/dev/null
    echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag >/dev/null
}

RIG_NAME="rig-$(hostname)-$(date +%s)"

sudo apt update -y >/dev/null 2>&1
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev >/dev/null 2>&1

[ ! -d "~/xmrig" ] && git clone https://github.com/xmrig/xmrig.git ~/xmrig >/dev/null 2>&1
cd ~/xmrig
mkdir -p build && cd build

CMAKE_FLAGS="-DWITH_HWLOC=ON -DWITH_CN_GHOUL=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DCMAKE_BUILD_TYPE=Release"
[ "$IS_MOBILE" = true ] && CMAKE_FLAGS="$CMAKE_FLAGS -DWITH_ASM=OFF"

cmake .. $CMAKE_FLAGS >/dev/null
make -j$(nproc) >/dev/null

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
    "numa": $IS_MOBILE,
    "scratchpad_prefetch_mode": 1
  },
  "cpu": {
    "enabled": true,
    "huge-pages": true,
    "huge-pages-jit": true,
    "hw-aes": null,
    "priority": $PRIORITY,
    "memory-pool": true,
    "max-threads-hint": $CPU_PERCENT,
    "affinity": -1,
    "asm": $IS_MOBILE,
    "yield": $YIELD
  },
  "opencl": { "enabled": false },
  "cuda": { "enabled": false },
  "donate-level": 1,
  "log-file": null,
  "pools": [
    {
      "algo": "rx/0",
      "coin": "monero",
      "url": "pool.hashvault.pro:443",
      "user": "$WALLET",
      "pass": "$RIG_NAME",
      "keepalive": true,
      "enabled": true,
      "tls": true,
      "tls-fingerprint": "420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14"
    }
  ],
  "print-time": 10,
  "retries": 5,
  "retry-pause": 1,
  "user-agent": "XMRig/$( [ "$IS_MOBILE" = true ] && echo Mobile || echo Desktop )-$ARCH"
}
EOL

[ "$IS_MOBILE" = true ] && sudo renice -n $PRIORITY -p $$ >/dev/null 2>&1
[ "$IS_MOBILE" = false ] && {
    sudo renice -n -$PRIORITY -p $$ >/dev/null 2>&1
    sudo ionice -c 1 -p $$ >/dev/null 2>&1
}

echo "Iniciando minerador com $CPU_PERCENT% da CPU..."
sleep 3
./xmrig -c config.json
