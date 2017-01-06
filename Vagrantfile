# -*- mode: ruby -*-
# vi: set ft=ruby :

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize(32)
  end
end

Vagrant.configure(2) do |config|
  config.vm.box = 'boxesio/trusty64-ansible'
  config.vm.box_version = '2.3.0.20161011172019'

  config.vm.provider 'virtualbox' do |v|
    host = RbConfig::CONFIG['host_os']

    # Dynamically alocate system resources
    mem = `sysctl -n hw.memsize`.to_i / 1024
    cpu = `sysctl -n hw.ncpu`.to_i / 4

    mem = mem / 1024 / 4

    # Minimum of 2 cpu, and 2048 meg ram
    mem = 2048 if mem < 2048
    cpu = 2 if cpu < 2

    v.name = 'recruitx-vagrant'
    v.memory = mem
    v.cpus = cpu
    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpu]
  end

  config.vm.network 'private_network', ip: '10.10.10.10'
  config.vm.network :forwarded_port, guest: 22, host: 2200, auto_correct: false, id: "ssh"

  config.vm.synced_folder '.', '/vagrant',
    type: 'rsync',
    rsync__exclude: [
      ".git/",
      "node_modules/",
      "deps/",
      "_build",
      ".sass-cache/",
      ".vagrant/",
      "priv/static"
    ],
    rsync__verbose: true,
    rsync__args: [
      "--delete",
      "--checksum",
      "--stats",
      "--archive",
      "-z",
      "--copy-links"
    ]

  config.vm.provision :ansible do |ansible|
    ansible.playbook = 'provision.yml'
    ansible.vault_password_file = '~/.vault_pass.txt'
    ansible.verbose = 'vvvv'
    ansible.inventory_path = 'inventory'
  end

  config.trigger.after [:up, :provision] do
    info ""
    info "Everything is super, super slow when using VirtualBox shared folders, making provision very slow.".green
    info "As a result, we're copying the files over at boot using rsync, rather than mounting as a share.".green
    info "This means you will need to run 'vagrant rsync' to get your code level changes available.".green
    info ""
  end
end
