# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.


Vagrant.configure("2") do |config|
    config.vm.define "tor-proxy-server" do |config|

        config.vm.box = "ubuntu/jammy64"

        config.vm.network "forwarded_port", guest: 9050, host: 6969, host_ip: "127.0.0.1", id: "tor-proxy"
        config.vm.network "private_network", ip: "192.168.56.10"

        config.vm.hostname = "tor-proxy-server"

        config.vm.provider "virtualbox" do |vb|
            vb.name     = "tor-proxy-server"
            vb.memory   = "1024" 
            vb.cpus     = 2
            vb.gui      = false
        end

        config.vm.synced_folder ".", "/home/vagrant/source", owner: "vagrant", group: "vagrant"

        config.vm.provision "shell", inline: <<-SHELL
            
            echo "=== Basic provisioning the Tor Proxy Server VM... ==="

            #https transport for apt
            echo -e "\nSECTION: APT-TRANSPORT SWITCH \n"

            apt-get update 
            DEBIAN_FRONTEND=noninteractive apt-get install apt-transport-https -y

            sudo sed -i 's|http://|https://|g' /etc/apt/sources.list

            echo -e "\nSECTION: APT TRANSPORT SWITCH FINISHED"

            #packages installation
            echo -e "\nSECTION: PACKAGES INSTALLATION \n"

            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y tor nyx curl git obfs4proxy jq

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
            
            cp /home/vagrant/source/vagrant/brupd_conf.json /etc/brupd_conf.json
            
            cp /home/vagrant/source/vagrant/brupd.service /etc/systemd/system/brupd.service
            cp /home/vagrant/source/vagrant/brupd.timer /etc/systemd/system/brupd.timer
            
            cp /home/vagrant/source/vagrant/brupd-tor.service /etc/systemd/system/brupd-tor.service
            cp /home/vagrant/source/vagrant/brupd-tor.timer /etc/systemd/system/brupd-tor.timer
            
            cat /home/vagrant/source/vagrant/torrc | tee -a /etc/tor/torrc > /dev/null

            #sysctl keepalive settings
            cp /home/vagrant/source/vagrant/99-tcp-keepalive.conf /etc/sysctl.d/99-tcp-keepalive.conf
            sysctl -p /etc/sysctl.d/99-tcp-keepalive.conf


            #binary installation
            echo -e "\nSECTION: BRIDGE_UPDATER BINARY INSTALLATION \n"

            cd /home/vagrant/source
            go build -o /usr/local/bin/bridge_updater
            cd /home/vagrant

            echo -e "\nSECTION: BRIDGE_UPDATER BINARY INSTALLATION FINISHED\n"

            #comfy comfy usage binds and user guide
            cat /home/vagrant/source/vagrant/bind.sh | tee -a /home/vagrant/.bashrc > /dev/null

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
        SHELL

        config.vm.provision "shell", inline: <<-SHELL

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

            #build-essential installation
            echo -e "\nSECTION: BUILD-ESSENTIAL INSTALLATION\n"
            DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
            echo -e "\nBUILD-ESSENTIAL INSTALLATION FINISHED"

            #rust installation
            echo -e "\nSECTION: RUST INSTALLATION\n"

            curl -sSf https://sh.rustup.rs -o rustup-init.sh
            chmod +x rustup-init.sh
            ./rustup-init.sh -y
            source "$HOME/.cargo/env"
            rm rustup-init.sh

            echo -e "\nSECTION: RUST INSTALLATION FINISHED"

            #peers_updater installation
            echo -e "\nSECTION: PEERS_UPDATER INSTALLATION AND FETCHING PEERS\n"

            REPO_URL="https://github.com/ygguser/peers_updater"
            DEST_DIR="/usr/local/src/peers_updater"

            mkdir -p "$DEST_DIR"
            git clone "$REPO_URL" "$DEST_DIR"
            cd "$DEST_DIR"
            cargo build --release

            cd target/release
            mv peers_updater /usr/local/bin/peers_updater

            cd /home/vagrant
            rm -rf $DEST_DIR

            /usr/local/bin/peers_updater -c /etc/yggdrasil/yggdrasil.conf -n 35 -I russia -u;
            
            systemctl restart yggdrasil

            echo -e "\nSECTION: PEERS_UPDATER INSTALLATION AND FETCHING PEERS FINISHED"

            #rust deinstallation
            echo -e "\nSECTION: RUST & BUILD-ESSENTIAL DEINSTALLATION\n"

            rustup self uninstall -y
            apt-get purge -y build-essential && apt-get autoremove -y

            echo -e "\nSECTION: RUST & BUILD-ESSENTIAL DEINSTALLATION FINISHED\n"

            #copy yggdrasil bridges and reconfigure tor            

            cp /home/vagrant/source/vagrant/yggbr.conf /etc/tor/yggbr.conf
            sed -i 's|^#%include /etc/tor/yggbr.conf|%include /etc/tor/yggbr.conf|' /etc/tor/torrc

            systemctl reload tor@default

            echo -e "=== Yggdrasil features provisioning completed! ==="
        SHELL
    end
end
