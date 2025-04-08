#!/bin/bash
set -eo pipefail

# === Downloader setup ===
download() {
    OUT="$1"
    URL="$2"
    if [[ "$DOWNLOADER" == "wget" ]]; then
        wget -O "$OUT" "$URL"
    elif [[ "$DOWNLOADER" == "curl" ]]; then
        curl -Lo "$OUT" "$URL"
    else
        ./wget_busybox_amd_x86_64_gcc_Linux "$URL" -O "$OUT"
    fi
}

# Detect downloader
if command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
else
    echo "Neither wget nor curl is installed."
    echo "Please upload the following files manually and rerun the script:"
    echo "- wget_busybox_amd_x86_64_gcc_Linux"
    echo "- udocker-1.3.17.tar.gz"
    echo "- proot (as zsh)"
    exit 1
fi

# === wget_busybox fallback ===
if [[ "$DOWNLOADER" != "wget" ]]; then
    if [[ ! -f wget_busybox_amd_x86_64_gcc_Linux ]]; then
        echo "Downloading wget_busybox binary..."
        download wget_busybox_amd_x86_64_gcc_Linux https://raw.githubusercontent.com/pkgforge-dev/Static-Binaries/refs/heads/main/wget/wget_busybox_amd_x86_64_gcc_Linux
        chmod +x wget_busybox_amd_x86_64_gcc_Linux
    fi
fi

# === Python install ===
if [[ ! -d python ]]; then
    echo "Downloading standalone Python 3.10..."
    download python.tar.gz https://github.com/astral-sh/python-build-standalone/releases/download/20250317/cpython-3.10.16+20250317-x86_64-unknown-linux-gnu-install_only.tar.gz
    tar -xvf python.tar.gz
    rm python.tar.gz
fi

# Add Python to PATH
export PATH="$(pwd)/python/bin:$PATH"

# Install pycurl if curl is missing
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found, installing pycurl with pip..."
    pip install pycurl
fi

# === uDocker install ===
echo "Installing uDocker..."
if [[ ! -f udocker-1.3.17.tar.gz ]]; then
    download udocker-1.3.17.tar.gz https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz
fi

tar zxvf udocker-1.3.17.tar.gz
export PATH=$(pwd)/udocker-1.3.17/udocker:$PATH
export FILEDIR=$(pwd)/udocker-1.3.17/udocker

# === proot ===
if [[ ! -f $FILEDIR/zsh ]]; then
    download "$FILEDIR/zsh" https://proot.gitlab.io/proot/bin/proot
    chmod +x "$FILEDIR/zsh"
fi

# === uDocker setup ===
sed -i '1s|#!/usr/bin/env python|#!/usr/bin/env python3|' "$FILEDIR/udocker"
"$FILEDIR/udocker" install

export UDOCKER_DEFAULT_EXECUTION_MODE=P1
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)

# === Container install ===
echo "Installing the Ubuntu 22.04 container..."
"$FILEDIR/udocker" pull ubuntu:jammy
"$FILEDIR/udocker" create --name=ubuntu ubuntu:jammy
"$FILEDIR/udocker" setup --execmode=P1 ubuntu

# === Create start_container.sh ===
cat > start_container.sh << EOF
#!/bin/sh
export PATH=\$(pwd)/udocker-1.3.17/udocker:\$PATH
export PATH=\$(pwd)/python/bin:\$PATH
export UDOCKER_USE_PROOT_EXECUTABLE=\$(which zsh)
udocker setup --execmode=P1 ubuntu
udocker run --containerauth -v /home/container:/pterohome --workdir /root ubuntu /bin/bash
EOF

chmod +x start_container.sh

echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will now delete itself."

rm -- "\$0"
rm -f wget_busybox_amd_x86_64_gcc_Linux
