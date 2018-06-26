#!/bin/bash

BOOTSTRAPURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.3.0/bootstrap.dat.xz"
BOOTSTRAPARCHIVE="bootstrap.dat.xz"

clear
echo "This script will refresh your masternode."
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  systemctl stop bulwarkd
else
  su -c "bulwark-cli stop" bulwark
fi

echo "Refreshing node, please wait."

sleep 5

rm -rf /home/bulwark/.bulwark/blocks
rm -rf /home/bulwark/.bulwark/database
rm -rf /home/bulwark/.bulwark/chainstate
rm -rf /home/bulwark/.bulwark/peers.dat

cp /home/bulwark/.bulwark/bulwark.conf /home/bulwark/.bulwark/bulwark.conf.backup
sed -i '/^addnode/d' /home/bulwark/.bulwark/bulwark.conf

echo "Installing bootstrap file..."
wget $BOOTSTRAPURL && xz -cd $BOOTSTRAPARCHIVE > /home/bulwark/.bulwark/bootstrap.dat && rm $BOOTSTRAPARCHIVE

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  sudo systemctl start bulwarkd
else
  su -c "bulwarkd -daemon" bulwark
fi

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window." && echo ""

until [ -n "$(bulwark-cli getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" bulwark; do
  echo -ne "Current block: "`su -c "bulwark-cli getinfo" bulwark | grep blocks | awk '{print $3}' | cut -d ',' -f 1`'\r'
  sleep 1
done

clear

cat << EOL

Now, you need to start your masternode. Please go to your desktop wallet and
enter the following line into your debug console:

startmasternode alias false <mymnalias>

where <mymnalias> is the name of your masternode alias (without brackets)

EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

sleep 1
su -c "/usr/local/bin/bulwark-cli startmasternode local false" bulwark
sleep 1
clear
su -c "/usr/local/bin/bulwark-cli masternode status" bulwark
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""