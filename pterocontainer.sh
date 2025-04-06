#!/bin/bash
# python fix
wget -O python.tar.gz https://github.com/astral-sh/python-build-standalone/releases/download/20250317/cpython-3.10.16+20250317-x86_64-unknown-linux-gnu-install_only.tar.gz
tar -xvf python.tar.gz
# delete
rm python.tar.gz
export PATH="$HOME/python/bin:$PATH"
set -eo pipefail
curl -O https://raw.githubusercontent.com/pkgforge-dev/Static-Binaries/refs/heads/main/wget/wget_busybox_amd_x86_64_gcc_Linux
chmod +x ./wget_busybox_amd_x86_64_gcc_Linux
echo "Installing uDocker..."
./wget_busybox_amd_x86_64_gcc_Linux https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz
tar zxvf udocker-1.3.17.tar.gz
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
export FILEDIR=`pwd`/udocker-1.3.17/udocker
./wget_busybox_amd_x86_64_gcc_Linux -O $FILEDIR/zsh https://proot.gitlab.io/proot/bin/proot
chmod +x $FILEDIR/zsh
mv $FILEDIR/udocker $FILEDIR/op
# udocker being udocker..
sed -i '1s|#!/usr/bin/env python|#!/usr/bin/env python3|' `pwd`/udocker-1.3.17/udocker/op
op install
# Setting execmode to runc
export UDOCKER_DEFAULT_EXECUTION_MODE=P1
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)
echo "Installing the Ubuntu container..."
op pull ubuntu:focal
op create --name=ubuntu ubuntu:focal
op setup --execmode=P1 ubuntu

cat > start_container.sh << EOF

#!/bin/sh
export PATH="$HOME/python/bin:$PATH"
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)
op setup --execmode=P1 ubuntu
op run --containerauth -v /home/container:/pterohome --workdir /root ubuntu /bin/bash
EOF
chmod +x start_container.sh
echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will auto destroy."
rm "$0"
rm wget_busybox_amd_x86_64_gcc_Linux
