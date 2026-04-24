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

        config.vm.synced_folder "./source", "/home/vagrant/source", owner: "vagrant", group: "vagrant"
        config.vm.synced_folder "./provision/misc", "/home/vagrant/misc", owner: "vagrant", group: "vagrant"

        config.vm.provision "shell", path: "./provision/stage1.sh", privileged: true
        config.vm.provision "shell", path: "./provision/stage2.sh", privileged: true
    end
end
