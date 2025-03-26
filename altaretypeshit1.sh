#!/bin/bash
set -eo pipefail
curl -O https://raw.githubusercontent.com/yunchih/static-binaries/refs/heads/master/wget
chmod +x ./wget
echo "Installing uDocker..."
./wget https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz
tar zxvf udocker-1.3.17.tar.gz
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
export FILEDIR=`pwd`/udocker-1.3.17/udocker
mv $FILEDIR/udocker $FILEDIR/op
# udocker being udocker..
sed -i '1s|#!/usr/bin/env python|#!/usr/bin/env python3|' `pwd`/udocker-1.3.17/udocker/op
op install
# Setting execmode to runc
export UDOCKER_DEFAULT_EXECUTION_MODE=R1
# Fix runc execution issue
export XDG_RUNTIME_DIR=$HOME
echo "Installing the Debian container..."
op pull debian
op create --name=debian debian
op setup --execmode=R1 debian

cat > start_container.sh << EOF

#!/bin/sh
export XDG_RUNTIME_DIR=$HOME
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
op setup --execmode=R1 debian
op run debian /bin/bash
EOF
chmod +x start_container.sh
echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will auto destroy."
rm "$0"
