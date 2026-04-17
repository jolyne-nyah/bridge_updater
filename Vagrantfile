# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.


Vagrant.configure("2") do |config|
    config.vm.define "tor-proxy-server" do |config|

        config.vm.box = "ubuntu/jammy64"

        config.vm.network "forwarded_port", guest: 9050, host: 6969
        config.vm.network "private_network", ip: "192.168.56.10"

        config.vm.hostname = "tor-proxy-server"

        config.vm.provider "virtualbox" do |vb|
            vb.name     = "tor-proxy-server"
            vb.memory   = "1024" 
            vb.cpus     = 2
            vb.gui      = false
        end

        config.vm.synced_folder ".", "/home/vagrant/source"

        config.vm.provision "shell", inline: <<-SHELL
            
            echo "=== Provisioning the Tor Proxy Server VM... ==="

            #https transport for apt
            apt-get update 
            DEBIAN_FRONTEND=noninteractive apt-get install apt-transport-https -y

            sudo sed -i 's|http://|https://|g' /etc/apt/sources.list

            #packages installation
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y tor nyx curl git obfs4proxy jq

            #needed directories
            cd /usr/local/src
            mkdir -p directs
            mkdir -p repos
            cd /etc/tor
            mkdir -p torrc.d
            cd /home/vagrant

            #go installation
            curl -L -f https://go.dev/dl/go1.26.1.linux-amd64.tar.gz -o go.tar.gz
            tar -C /usr/local -xzf go.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/golang.sh
            . /etc/profile.d/golang.sh
            rm go.tar.gz

            #export configs from source
            cp /home/vagrant/source/vagrant/brupd_conf.json /etc/brupd_conf.json
            cp /home/vagrant/source/vagrant/brupd.service /etc/systemd/system/brupd.service
            cp /home/vagrant/source/vagrant/brupd.timer /etc/systemd/system/brupd.timer
            cp /home/vagrant/source/vagrant/brupd-tor.service /etc/systemd/system/brupd-tor.service
            cp /home/vagrant/source/vagrant/brupd-tor.timer /etc/systemd/system/brupd-tor.timer
            cat /home/vagrant/source/vagrant/torrc | tee -a /etc/tor/torrc > /dev/null

            #binary installation
            cd /home/vagrant/source
            go build -o /usr/local/bin/bridge_updater
            cd /home/vagrant

            #comfy comfy usage binds and user guide
            cat /home/vagrant/source/vagrant/bind.sh | tee -a /home/vagrant/.bashrc > /dev/null

            #apparmor configuration
            echo '/etc/tor/torrc.d/ r,' | sudo tee -a /etc/apparmor.d/local/system_tor > /dev/null
            echo '/etc/tor/torrc.d/* r,' | sudo tee -a /etc/apparmor.d/local/system_tor > /dev/null

            systemctl reload apparmor

            #enable and start the services
            systemctl enable --now tor
            systemctl start brupd.service
            systemctl enable --now brupd-tor.timer

            echo "=== Provisioning completed! ==="
        SHELL
    end
end
