# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.6.3"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
 
  config.vm.box = "windows2012-chef"
  config.vm.box_url="box/windows2012-chef.box"

  # Admin user name and password
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"

  config.windows.halt_timeout = 25
  
  # PLUGINS
  # Set the version of chef to install using the vagrant-omnibus plugin
  if Vagrant.has_plugin?("vagrant-omnibus")
    config.omnibus.chef_version = :latest
  end

  # Enable berkshelf to copy cookbooks
  if Vagrant.has_plugin?("vagrant-berkshelf")
    config.berkshelf.enabled = true
  end

  # Enable provisioning caching for vagrant
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # When chef-zero is installed, use chef_client to configure VM
  if Vagrant.has_plugin?("vagrant-chef-zero")
    config.chef_zero.enabled = true
    config.chef_zero.chef_repo_path = "."

    config.vm.provision :chef_client do |chef|
      chef.run_list = [
          "recipe[sql_server::default]"
      ]
    end
    # Use chef_solo to configure VM
  else
    VAGRANT_JSON = JSON.parse(Pathname(__FILE__).dirname.join('nodes', 'vagrant.json').read)
    config.vm.provision :chef_solo do |chef|

      # Allows to set chef log level from cmdline like EXPORT CHEF_LOG=debug ...
      chef.formatter = ENV.fetch("CHEF_FORMAT", "null").downcase.to_sym
      chef.log_level = ENV.fetch("CHEF_LOG", "info").downcase.to_sym

      # DO NOT REMOVE otherwise chef-solo won't find the databags
      chef.data_bags_path = "data_bags"

      # Fill the runlist from 'nodes/vagrant.json'
      chef.json = VAGRANT_JSON
      VAGRANT_JSON['run_list'].each do |recipe|
        chef.add_recipe(recipe)
      end if VAGRANT_JSON['run_list']
    end
  end

  config.vm.define :windows2012, primary: true do |windows2012|
    windows2012.vm.hostname = "windows2012-chef"
    windows2012.vm.network :private_network, type: "dhcp"
    windows2012.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct:true
    windows2012.vm.communicator = "winrm"
    windows2012.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm", auto_correct:true
    # Port forward SSH
    windows2012.vm.network :forwarded_port, guest: 22, host: 22, id: "ssh", auto_correct:true

	windows2012.vm.network :forwarded_port, guest: 1433, host: 1433, auto_correct:true
	windows2012.vm.guest = :windows
	
    windows2012.vm.provider :virtualbox do |vb|
#	  vb.gui = true
      vb.memory = 2048
      vb.cpus = 2
	  vb.customize ["modifyvm", :id, "--nic3", "bridged", "--bridgeadapter3", "Intel(R) 82579LM Gigabit Network Connection"]
	  vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
	  vb.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
    end
  end

end
