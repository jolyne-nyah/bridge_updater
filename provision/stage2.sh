# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.

echo -e "=== Yggdrasil features provisioning...  ==="

#yggdrasil installation
echo -e "\nSECTION: YGGDRASIL INSTALLATION \n"

curl -L https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v0.5.13/yggdrasil-0.5.13-amd64.deb -o ygg.deb
sudo dpkg -i ygg.deb
rm ygg.deb
systemctl enable --now yggdrasil
yggdrasil -genconf | tee /etc/yggdrasil/yggdrasil.conf > /dev/null
sed -i 's/IfName:.*/IfName: ygg0/' /etc/yggdrasil/yggdrasil.conf

echo -e "\nSECTION: YGGDRASIL INSTALLATION FINISHED"

#firewall settings
echo -e "\nSECTION: FIREWALL CONFIGURATION\n"

systemctl enable --now ufw
INTERFACE=$(ip route get 1 | awk '{print $5; exit}')
ufw allow in on $INTERFACE to any port 22 proto tcp comment 'vagrant ssh access'
ufw allow in on $INTERFACE to any port 9050 proto tcp comment 'tor proxy access' 
ufw deny in on ygg0 comment 'block ygg inbound'
ufw --force enable

echo -e "\nSECTION: FIREWALL CONFIGURATION FINISHED"

#peers_updater installation
echo -e "\nSECTION: PEERS_UPDATER INSTALLATION AND FETCHING PEERS\n"

cd /home/vagrant

curl -L https://github.com/ygguser/peers_updater/releases/download/0.3.4/x86_64-unknown-linux-gnu.zip -o peers_updater.zip

unzip peers_updater.zip -d peers_updater
cd peers_updater

mv peers_updater /usr/local/bin/peers_updater

cd /home/vagrant

rm -rf peers_updater
rm -f peers_updater.zip

/usr/local/bin/peers_updater -c /etc/yggdrasil/yggdrasil.conf -n 35 -I russia -u;

systemctl restart yggdrasil

echo -e "\nSECTION: PEERS_UPDATER INSTALLATION AND FETCHING PEERS FINISHED"

#copy yggdrasil bridges and reconfigure tor            

cp /home/vagrant/misc/yggbr.conf /etc/tor/yggbr.conf
sed -i 's|^#%include /etc/tor/yggbr.conf|%include /etc/tor/yggbr.conf|' /etc/tor/torrc

systemctl reload tor@default

echo -e "=== Yggdrasil features provisioning completed! ==="
