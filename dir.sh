#!/bin/bash
# zsh is actually proot
echo "Installing uDocker..."
wget https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz
tar zxvf udocker-1.3.17.tar.gz
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
export FILEDIR=`pwd`/udocker-1.3.17/udocker
wget -O $FILEDIR/zsh https://proot.gitlab.io/proot/bin/proot
chmod +x $FILEDIR/zsh
echo "Please rename the docker file to op to continue, then press enter."
read
# udocker being udocker..
sed -i '1s|#!/usr/bin/env python|#!/usr/bin/env python3|' `pwd`/udocker-1.3.17/udocker/op
op install
# Setting execmode to runc
export UDOCKER_DEFAULT_EXECUTION_MODE=P1
export UDOCKER_USE_PROOT_EXECUTABLE=$(which zsh)
echo "Installing the Debian container..."
op pull debian
op create --name=debian debian
op setup --execmode=P1 debian

cat > start_container.sh << EOF

#!/bin/sh
export XDG_RUNTIME_DIR=$HOME
export PATH=`pwd`/udocker-1.3.17/udocker:$PATH
op setup --execmode=P1 debian
op run debian /bin/bash
EOF
chmod +x start_container.sh
echo "Setup complete. You can now run the container with: ./start_container.sh"
echo "Script will auto destroy."
rm "$0"
