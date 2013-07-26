#!/bin/bash
#
# (C) 2013
# Written by Chris J Arges <christopherarges@gmail.com>
#

USER="arges"

# command line 
CLI_PACKAGES="vim git git-email git-extras terminator"
# tools
APPLICATIONS="keepassx weechat chromium-browser virt-manager hamster-applet"
# ubuntu work 
WORK="ubuntu-dev-tools sbuild packaging-dev mumble"
# cloud
CLOUD="cloud-utils juju python-novaclient"
# server
SERVER="znc squid-deb-proxy openssh-server lxc libvirt-bin apt-cacher-ng zookeeper haveged"
# All packages
PACKAGES="$CLI_PACKAGES $APPLICATIONS $WORK $CLOUD $SERVER"

# Default gsettings for all releases
GSETTINGS=(
"com.canonical.indicator.appmenu.hud store-usage-data false"
"org.gnome.desktop.interface gtk-theme \"Radiance\""
"com.canonical.indicator.datetime show-date true"
"com.canonical.indicator.datetime show-day true"
"org.gnome.libgnomekbd.keyboard options \"['caps\tcaps:escape']\""
)

# Newer than precise settings
if [ `lsb_release -cs` != "precise" ]; then
GSETTINGS+=(
"com.canonical.Unity.Lenses remote-content-search none"
"com.canonical.unity.webapps integration-allowed false"
"com.canonical.unity-greeter play-ready-sound false"
)
fi

# distribution series / arches we care about
DISTS="precise quantal raring saucy"
ARCH="i386 amd64 armhf"

# relevant dotfiles
DOTFILES="bash_profile gitconfig quiltrc sbuildrc vimrc mk-sbuild.rc"

BZR_WHOAMI="Chris J Arges <chris.j.arges@ubuntu.com>"

################################################################################

# Update Environment
function _01_update() {
	sudo apt-get update -y
	sudo apt-get upgrade -y
	sudo apt-get autoremove
}

# Install Selected Packages
function _02_install_packages() {
	for pkg in $PACKAGES; do
		sudo apt-get install -y $pkg
	done
}

function _03_update_sshd() {
	sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
		/etc/ssh/sshd_config
}

# setup specific gsettings
# FIXME: need to manually fix theme settings in Precise
# FIXME: need to manually turn on privacy in Precise
function _04_setup_gsettings() {
	for s in  "${GSETTINGS[@]}"; do
		gsettings set $s
	done
}

# setup keys
function _05_setup_keys() {
	ln -s /media/keys/id_rsa ~/.ssh/id_rsa
	ln -s /media/keys/gnupg ~/.gnupg
}

# setup dot files
function _06_install_dot_files() {
	for f in $DOTFILES; do
		cp dotfiles/$f ~/.$f
	done
}

# setup bzr/sshebang (needs ssh keys installed)
function _07_setup_bzr_sshebang() {
	bzr launchpad-login $USER
	bzr whoami $BZR_WHOAMI
	bzr branch lp:canonical-sshebang ~/.ssh/sshebang && make -C ~/.ssh/sshebang
}

# setup kernel trees
function _08_clone_git_trees() {
	mkdir -p ~/src/kernel
	cd ~/src/kernel
	# clone the linux kernel
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

	for d in $DISTS; do
		git clone --reference ./linux git://kernel.ubuntu.com/${USER}/ubuntu-$d.git
		cd ubuntu-$d
		git remote add up \
			ssh+git://${USER}@zinc.canonical.com/srv/kernel.ubuntu.com/git/${USER}/ubuntu-$d.git
		cd -

	done
	cd -
}

# setup sbuild
function _09_setup_sbuild() {
	sudo adduser $USER sbuild
	sbuild-update --keygen
	for d in $DISTS; do
		for a in $ARCH; do
			http_proxy=http://localhost:8000/ mk-sbuild \
				 --name ${d} --arch=${a} --distro=ubuntu ${d}
		done
	done
}

function _10_setup_juju() {
	newgrp libvirtd
}

function _11_add_ddebs() {
	echo "deb http://ddebs.ubuntu.com $(lsb_release -cs)-updates main restricted universe multiverse
	deb http://ddebs.ubuntu.com $(lsb_release -cs)-security main restricted universe multiverse
	deb http://ddebs.ubuntu.com $(lsb_release -cs)-proposed main restricted universe multiverse" | \
	sudo tee -a /etc/apt/sources.list.d/ddebs.list

	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 428D7C01

	sudo apt-get update
}

#TODO
# Workaround: https://bugs.launchpad.net/ubuntu/+source/hamster-indicator/+bug/1020343/comments/5

FUNCTIONS=`declare -F | cut -d" " -f3`
################################################################################

function all() { for f in $FUNCTIONS; do $f; done }

function help() {
	echo "Select one of :"
	for f in $FUNCTIONS; do
		echo '   ' ${f#_*_}
	done
	echo "    all"
}

# Parse arguments
if  [[ $# == 1 ]]; then
	for f in $FUNCTIONS; do
		if [[ $1 == ${f#_*_} ]]; then
			$f
		fi
	done
else
	help
fi

