echo "=== Basic provisioning the Tor Proxy Server VM... ==="

#creating swapfile
echo -e "\nSECTION: CREATING SWAPFILE\n"

fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

#backup old fstab
cp /etc/fstab /etc/fstab.backup

echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

echo -e "\nSECTION: CREATING SWAPFILE FINISHED"

#https transport for apt
echo -e "\nSECTION: APT-TRANSPORT SWITCH \n"

apt-get update 
DEBIAN_FRONTEND=noninteractive apt-get install apt-transport-https -y

sudo sed -i 's|http://|https://|g' /etc/apt/sources.list

echo -e "\nSECTION: APT TRANSPORT SWITCH FINISHED"

#packages installation
echo -e "\nSECTION: PACKAGES INSTALLATION \n"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y tor nyx curl git obfs4proxy jq unzip

echo -e "\nSECTION: PACKAGES INSTALLATION FINISHED"

#needed directories
cd /usr/local/src
mkdir -p directs
mkdir -p repos
cd /etc/tor
mkdir -p torrc.d
cd /home/vagrant

#go installation
echo -e "\nSECTION: GO INSTALLATION \n"

curl -L -f https://go.dev/dl/go1.26.1.linux-amd64.tar.gz -o go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/golang.sh
. /etc/profile.d/golang.sh
rm go.tar.gz

echo -e "\nSECTION: GO INSTALLATION FINISHED"

#export configs from source

cp /home/vagrant/misc/brupd_conf.json /etc/brupd_conf.json

cp /home/vagrant/misc/brupd.service /etc/systemd/system/brupd.service
cp /home/vagrant/misc/brupd.timer /etc/systemd/system/brupd.timer

cp /home/vagrant/misc/brupd-tor.service /etc/systemd/system/brupd-tor.service
cp /home/vagrant/misc/brupd-tor.timer /etc/systemd/system/brupd-tor.timer

cat /home/vagrant/misc/torrc | tee -a /etc/tor/torrc > /dev/null

#brupd-tor onfailure std status
touch /etc/brupd-onfailure

#sysctl keepalive settings
cp /home/vagrant/misc/99-tcp-keepalive.conf /etc/sysctl.d/99-tcp-keepalive.conf
sysctl -p /etc/sysctl.d/99-tcp-keepalive.conf


#binary installation
echo -e "\nSECTION: BRIDGE_UPDATER BINARY INSTALLATION \n"

cd /home/vagrant/source/core
go build -o /usr/local/bin/bridge_updater
cd /home/vagrant

echo -e "\nSECTION: BRIDGE_UPDATER BINARY INSTALLATION FINISHED\n"

#comfy comfy usage binds and user guide
cat /home/vagrant/misc/bind.sh | tee -a /home/vagrant/.bashrc > /dev/null

#apparmor configuration
echo '/etc/tor/torrc.d/ r,' | sudo tee -a /etc/apparmor.d/local/system_tor > /dev/null
echo '/etc/tor/torrc.d/* r,' | sudo tee -a /etc/apparmor.d/local/system_tor > /dev/null

systemctl reload apparmor

#enable and start the services
echo -e "\nSECTION: SERVICES START \n"

systemctl enable --now tor
systemctl start brupd.service
systemctl enable --now brupd-tor.timer

echo -e "\nSECTION: SERVICES START FINISHED\n"

echo "=== Basic provisioning completed! ==="