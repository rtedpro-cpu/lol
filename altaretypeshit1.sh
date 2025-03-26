#!/bin/bash
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
export UDOCKER_DEFAULT_EXECUTION_MODE=P2
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)
echo "Installing the Debian container..."
op pull debian
op create --name=debian debian
op setup --execmode=P2 debian

cat > start_container.sh << EOF

#!/bin/sh
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)
op setup --execmode=P2 debian
op run debian /bin/bash
EOF
chmod +x start_container.sh
echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will auto destroy."
rm "$0"
