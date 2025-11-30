#!/usr/bin/env bash
y_or_n() {
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
		[Yy]*) return 0 ;;
		[Nn]*)
			return 1
			;;
		esac
	done
}

nixos_install() {
	if [[ ${#USERS[@]} == 0 && $INSTALL_MODE != "existing" ]]; then
		# if no users have been configured, ensure root gets a password
		# also assume existing configurations have proper user configurations and do not set root password
		nixos-install --no-channel-copy --flake /mnt/etc/nixos#$HOSTNAME
	else
		nixos-install --no-channel-copy --no-root-password --flake /mnt/etc/nixos#$HOSTNAME
	fi
}

create_swap() {
	# /tmp will be cleared on bootup if nixos option boot.tmp.cleanOnBoot is set (which it is by default in my config)
	if [[ $(cat /proc/meminfo | grep MemAvailable | cut -d ":" -f2 | tr -d " kB") -lt 4000000 && ! -f /mnt/tmp/swap ]]; then
		printf "Detected less than 4GB of free ram\nNixOS requires at least 4GB of free ram to install smoothly.\nCreating a 4GB swap file at /mnt/tmp/swap."
		mkdir -p /mnt/tmp
		dd if=/dev/zero of=/mnt/tmp/swap bs=1024 count=4194304
		mkswap /mnt/tmp/swap
		chmod 600 /mnt/tmp/swap
		swapon /mnt/tmp/swap
	fi
}

hardware_config() {
	if [[ $DISKO_CONFIG == "" ]]; then
		nixos-generate-config --root /mnt >/dev/null
	else
		nixos-generate-config --no-filesystems --root /mnt >/dev/null
	fi
	rm /mnt/etc/nixos/configuration.nix

	# regenerate the hardware config on every reinstall.
	if [[ -e $HOST_CONFIG/hardware-configuration.nix ]]; then
		rm $HOST_CONFIG/hardware-configuration.nix
	fi
	mv /mnt/etc/nixos/hardware-configuration.nix $HOST_CONFIG

	# if in a git repo, then nix will fail to find the new files unless they are added.
	if [[ -d /mnt/etc/nixos/.git ]]; then
		git -C /mnt/etc/nixos add /mnt/etc/nixos
	fi
}

pull_repo() {
	REPO_DIR=/tmp/nix-config

	if [[ -d $REPO_DIR ]]; then
		echo "existing repository found at $REPO_DIR".
		y_or_n "Would you like to remove it and pull your repository again?" || return 0
	fi

	read -p "Enter the url for your config repository: " REPO_URL
	$(git ls-remote $REPO_URL)
	while [[ $? == 128 ]]; do
		read -p "Try again: " REPO_URL
		$(git ls-remote $REPO_URL)
	done

	if [[ -d $REPO_DIR ]]; then
		echo "removing existing repository found at $REPO_DIR"
		rm -rf $REPO_DIR
	fi
	git clone $REPO_URL --depth 1 $REPO_DIR
}

install_existing_config() {
	pull_repo

	CONFIGURATIONS=($(nix eval $REPO_DIR'#'nixosConfigurations --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'))
	HOSTNAME=$(printf "%s\n" "${CONFIGURATIONS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Found the following configurations. Which one would you like to install?")

	if [[ $HOSTNAME == "" ]]; then
		echo "No host selected."
		exit 1
	fi

	HOST_CONFIG="/mnt/etc/nixos/hosts/$HOSTNAME"

	printf "\nIf performing a fresh install you will need to format and partition your disks\n"
	echo "However, if performing a recovery install due to a non-booting system, cancel and mount the necessary drives, then skip partitioning."
	y_or_n "Format disks?" && format_disks

	if [[ $yn == [Nn]* ]]; then
		if [[ $(ls /mnt) ]]; then
			echo "/mnt contains files. Assuming disks are mounted"
		else
			echo "/mnt is empty. Be sure to mount required disks and run the installer again"
			exit 1
		fi
	fi

	if [[ ! -d /mnt/etc/nixos ]]; then
		mkdir -p /mnt/etc/nixos
	fi

	mv $REPO_DIR/{.,}* /mnt/etc/nixos
	rm -rf $REPO_DIR
	hardware_config

	echo "checking configuration"
	if [[ $(nix eval /mnt/etc/nixos'#'nixosConfigurations.$HOSTNAME.config.sops.secrets) != "{ }" ]]; then
		SOPS_KEYFILE=$(nix eval /mnt/etc/nixos'#'nixosConfigurations.$HOSTNAME.config.sops.age.keyFile | tr -d '"')
		if [[ ! -f /mnt$SOPS_KEYFILE ]]; then
			echo "Detected sops secrets from this configuration."
			printf "You will need to imperatively place your private key file at /mnt%s before you continue\n" $SOPS_KEYFILE
			printf "Press any key to continue..."
			read -n 1 key
		fi

		while [[ ! -f /mnt$SOPS_KEYFILE ]]; do
			printf "Keyfile not found.\nEnsure the file is present in /mnt%s.\n" $SOPS_KEYFILE
			printf "Press any key to continue..."
			read -n 1 key
		done
	fi

	create_swap
	nixos_install
	exit 0
}

sops_setup() {
	# TODO bug where this is hardcoded in the installer. if the host has a different key file path set in the sops module this will cause an error
	KEY_DIR="/mnt/var/lib/sops-nix"
	KEY_FILE="$KEY_DIR/keys.txt"
	SECRETS_PATH="hosts/$HOSTNAME/secrets.yaml"
	printf "\nBefore creating your user accounts you will need set up sops-nix.\n"
	echo "By default, all nix configuration files, including those containing hashed passwords or other secrets, will be world-readable in /nix/store."
	echo "To circumvent this security limitation of NixOS, you can use a sops-nix configuration."
	echo "This framework allows secure storage of secrets in your configuration repository using encryption."
	echo "While other key-based encryption formats can be used for sops-nix. This installer will use age."
	y_or_n "Do you have an existing age key pair that you wish to use with this host?"

	if [[ -d $KEY_DIR ]]; then
		rm -rf $KEY_DIR
	fi
	mkdir -p $KEY_DIR

	if [[ $yn == [Nn]* ]]; then
		echo "generating new age key pair"
		age-keygen -o $KEY_FILE >/dev/null
		PUBLIC_AGE_KEY=$(cat $KEY_FILE | grep "public key:" | cut -d ":" -f2 | tr -d " ")

		read -p "Create an alias for your new key (\`default\`, \`workstations\`, \`homelab\`, etc): " KEY_NAME

		echo "Configuring sops..."
		# write the configuration to .sops.yaml
		if [[ $INSTALL_MODE == "new" ]]; then
			echo "keys:
  - &$KEY_NAME $PUBLIC_AGE_KEY
creation_rules:
  - path_regex: $SECRETS_PATH
    key_groups:
      - age:
          - *$KEY_NAME" >$CONFIG_ROOT/.sops.yaml
		else
			# append the key and creation rules to an existing .sops.yaml
			sed -i "/keys:/a\  - &$KEY_NAME $PUBLIC_AGE_KEY" $CONFIG_ROOT/.sops.yaml
			sed -i "/creation_rules:/a\  - path_regex: $SECRETS_PATH\n    key_groups:\n      - age:\n          - *$KEY_NAME" $CONFIG_ROOT/.sops.yaml
		fi
		echo "Completed, the generated key will be stored at $KEY_FILE."
		echo "It is imperative that you create a backup of this private key after installation is complete. If you lose it, you will no longer be able to access your secrets and your system cannot rebuild."
		echo "press any key to acknowledge..."
		read -n 1 key
	else
		read -p "Enter your public age key: " PUBLIC_AGE_KEY
		read -p "What is the name of this key?: " KEY_NAME

		while [[ ! -e $KEY_FILE ]]; do
			echo "Place your private key file at the following location: $KEY_FILE"
			echo "The file must be in the proper format or else the install will fail."
			echo "press any key when the file is in place..."
			read -n 1 key

			if [[ ! -e $KEY_FILE ]]; then
				echo "File not found"
			fi
		done

		# add the key to .sops.yaml if the installation is a new repository. Else just assume that the repo contains the key in its .sops.yaml
		if [[ $INSTALL_MODE == "new" ]]; then
			echo "keys:
  - &$KEY_NAME $PUBLIC_AGE_KEY
creation_rules:
  - path_regex: $SECRETS_PATH
    key_groups:
      - age:
          - *$KEY_NAME" >$CONFIG_ROOT/.sops.yaml
		else
			sed -i "/creation_rules:/a\  - path_regex: $SECRETS_PATH\n    key_groups:\n      - age:\n          - *$KEY_NAME" $CONFIG_ROOT/.sops.yaml
		fi
	fi

	# make sure secure permissions are set for the keyfile
	chmod 600 $KEY_FILE
}

create_config() {
	read -p "Set your system hostname: " HOSTNAME
	CONFIG_ROOT=/mnt/etc/nixos
	# config directory for this specific host
	HOST_CONFIG=$CONFIG_ROOT/hosts/$HOSTNAME
	# file containing all hosts on your flake
	HOSTS_CONFIG=$CONFIG_ROOT/hosts/default.nix

	SPECIALIZATIONS=(
		"Let me install my own bloatware."
		"server"
		"gaming"
	)

	SPECIALIZATION=$(printf "%s\n" "${SPECIALIZATIONS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Enable a specialization module listed here?")

	if [[ $SPECIALIZATION == "Let me install my own bloatware." ]]; then
		printf "\nNo specialization modules will be enabled by default.\n"
		SPECIALIZATION=""
	fi

	if [[ $(lscpu | grep -i "intel") ]]; then
		CPU="intel"
	elif [[ $(lscpu | grep -i "amd") ]]; then
		CPU="amd"
	else
		CPU=""
	fi

	if [[ $(lspci -nnk | grep VGA | grep -i amd) ]]; then
		GPU="amd"
	elif [[ $(lspci -nnk | grep VGA | grep -i nvidia) ]]; then
		GPU="nvidia"
	# check for intel last in case of integrated graphics
	elif [[ $(lspci -nnk | grep VGA | grep -i intel) ]]; then
		GPU="intel"
	else
		GPU=""
	fi

	if [[ -d /sys/firmware/efi ]]; then
		BIOS="UEFI"
	else
		BIOS="legacy"
	fi

	ARCH=$(lscpu | grep Arch | tr -d " " | cut -d ":" -f2)
	STATEVERSION=$(nixos-version | cut -d "." -f1-2)

	y_or_n "Use the default localization configuration? (en_US.UTF-8)" ||
		LOCALE="$(cat /etc/locales.txt | fzf --border --border-label-pos 1:bottom --border-label="Select the default locale")"".UTF-8" &&
		LOCALE="en_US.UTF-8"

	if [[ -z $LOCALE ]]; then
		echo "aborted"
		exit 1
	fi

	y_or_n "Use the default keyboard layout? (us)" ||
		KBD_LAYOUT=$(localectl list-keymaps | fzf --border --border-label-pos 1:bottom --border-label="Select a keyboard layout") &&
		KBD_LAYOUT="us"

	if [[ -z $KBD_LAYOUT ]]; then
		echo "aborted"
		exit 1
	fi

	TIMEZONE=$(timedatectl list-timezones | fzf --border --border-label-pos 1:bottom --border-label="Select your time zone.")

	if [[ -z $TIMEZONE ]]; then
		echo "aborted"
		exit 1
	fi

	DESKTOPS=("hyprland" "niri" "plasma" "no-desktop")
	DESKTOP=$(printf "%s\n" "${DESKTOPS[@]}" | fzf --border --border-label-pos 1:bottom --border-label "Choose a desktop environment.")

	if [[ -z $DESKTOP ]]; then
		echo "aborted"
		exit 1
	fi

	echo "
	  NixOS will install with the following configuration.
	 	CPU - $CPU
	 	GPU - $GPU
	 	BIOS - $BIOS
	 	Arch - $ARCH 
		NixOS - $STATEVERSION
		Locale - $LOCALE
		keyboard - $KBD_LAYOUT
		timezone - $TIMEZONE
		Desktop - $DESKTOP 
		Specialization - $SPECIALIZATION
	"

	# remove the config files in case of an aborted or failed install
	if [[ -d $CONFIG_ROOT ]]; then
		rm -rf $CONFIG_ROOT
	fi
	mkdir -p $CONFIG_ROOT

	if [[ $INSTALL_MODE == "new" ]]; then
		# create flake.nix
		echo " {
		description = \"my NixOS configurations\";

		inputs = {
			# Uncomment to lock your own nixpkgs revision in the flake.lock.
      # nixpkgs = {
			#   url = \"github:NixOS/nixpkgs/nixos-unstable\";
			# };

			gman = {
				url = \"git+https://codeberg.org/EarthGman/nix-modules\";
				# Be sure to uncomment this if you use your own nixpkgs input. Mismatched system dependencies are not good.
				# inputs.nixpkgs.follows = \"nixpkgs\";
			};
		};

		outputs = { self, nixpkgs, gman, ... }@inputs:
		let
			lib = gman.lib;
			outputs = self.outputs;
		in
		{
			# expose hosts configured under this flake
			nixosConfigurations = import ./hosts { inherit lib outputs; };

			# expose your custom modules
			nixosModules.default = import ./modules/nixos { inherit inputs lib; };

			# expose package set modifications
			overlays = import ./overlays.nix { inherit inputs; };

			# your custom derivations
			packages = 
			let
			  supported-systems = [
				  # add more archs as needed
          \"$ARCH-linux\"
				];
			in
			# generate a package attribute set for each supported architecture
      lib.genAttrs supported-systems (
				system:
				import ./packages {
				  pkgs = nixpkgs.legacyPackages.\${system};
			  }
			);
		};
	}
	" >$CONFIG_ROOT/flake.nix

		# create directory framework
		echo "
		  # wrapper for all your nixos modules and modules consumed from flake inputs.
			{ inputs, lib, ... }:
			{
				# automatically import all configuration modules placed under core or mixins
				imports = lib.autoImport ./. ++ [
					# EXAMPLES
					# inputs.home-manager.nixosModules.default
				];
		  }
		" | install -D /dev/stdin "$CONFIG_ROOT/modules/nixos/default.nix"

		echo "
		  # This module directory is reserved for any modules appended to the core NixOS module set such as appending to options.programs options.services or options.hardware
			{ }
		" | install -D /dev/stdin "$CONFIG_ROOT/modules/nixos/core/default.nix"

		echo "
      # This directory is reserved for your custom modules
			# modules configured within this directory should be behind a config option of your name to distinguish the option set to your flake.
			{ lib, ... }:
			{
				# import all configuration automatically
				imports = lib.autoImport ./.;

				# EXAMPLE
				# options.my-name.enable = lib.mkEnableOption \"my nixos modules\"
				
				# config = lib.mkIf config.my-name.enable {
				#   my-name.module1.enable = true;
				#   my-name.module2.enable = true;
				# }
			}
		" | install -D /dev/stdin "$CONFIG_ROOT/modules/nixos/mixins/default.nix"

		echo "
		  # create custom derivations using pkgs.callPackage
      { pkgs, ... }:
			{
        # my-package = pkgs.callPackage ./my-package.nix { };
			}
		" | install -D /dev/stdin "$CONFIG_ROOT/packages/default.nix"

		echo "
      # overlays are functions which add derivations or modify existing derivations.
			# the flake.nix expects this to be a regular nix attribute set however
			# the nixos option \`nixpkgs.overlays\` requires the functions to be in a nix array to properly apply them to the configuration modules.
			# to apply them throughout your nixos configuration add:
			
			# extraModules = [
			#   { nixpkgs.overlays = builtins.attrValues outputs.overlays; }
			# ];
			#
			# to the lib.mkHost function at /hosts/default.nix (apply separately for each host)
			{
				# EXAMPLE 
				# TODO example
			}
		" | install -D /dev/stdin "$CONFIG_ROOT/overlays.nix"

	else
		mv $REPO_DIR/{.,}* $CONFIG_ROOT
		# if hostname is the same as an existing configuration, replace it
		if [[ -d $HOST_CONFIG ]]; then
			rm -rf $HOST_CONFIG
		fi
	fi

	mkdir -p $HOST_CONFIG

	# if a disko file from the repo was used, ensure it gets moved into the host's configuration
	if [[ ($DISKO_CONFIG != "") && (! -f $HOST_CONFIG/disko.nix) ]]; then
		mv $CONFIG_ROOT/$DISKO_CONFIG $HOST_CONFIG/disko.nix
	fi

	sops_setup

	y_or_n "Add a non-root user to the system?"
	USERS=()
	while [[ $yn == [Yy]* ]]; do
		read -p "Username: " USERNAME
		read -p "Password: " -s PASSWORD
		printf "\n"
		read -p "Retype password: " -s PASSWORD_2
		printf "\n"

		while [[ $PASSWORD != $PASSWORD_2 ]]; do
			printf "\nPasswords do not match\n"
			read -p "Password: " -s PASSWORD
			printf "\n"
			read -p "Retype password: " -s PASSWORD_2
			printf "\n"
		done

		y_or_n "Should this user have access to sudo?" && SUDO=true || SUDO=false

		USER_DIR=$HOST_CONFIG/users/$USERNAME
		if [[ ! -d $USER_DIR ]]; then
			mkdir -p $USER_DIR
		fi

		echo "{ config, ... }:
    {
      sops.secrets.""$USERNAME""_password.neededForUsers = true;
      users.users.$USERNAME = {
        hashedPasswordFile = config.sops.secrets."$USERNAME"_password.path;
        isNormalUser = true;
    " >$USER_DIR/default.nix
		if [[ $SUDO == true ]]; then
			echo "extraGroups = [ \"wheel\"];" >>$USER_DIR/default.nix
		fi
		echo "};
    }
		" >>$USER_DIR/default.nix

		echo "$USERNAME""_password: $(mkpasswd -s $PASSWORD)" >>$HOST_CONFIG/secrets.yaml

		USERS+=$USERNAME

		y_or_n "Add/Configure another user?"
	done

	# encrypt the secrets file with any secrets added throughout the installation
	if [[ -e $HOST_CONFIG/secrets.yaml ]]; then
		pushd $CONFIG_ROOT >/dev/null
		sops -e -i $HOST_CONFIG/secrets.yaml
		popd >/dev/null
	fi

	echo "{ pkgs, lib, config, ... }:
		{
			imports = [
			  # kernel and fstab configuration
			  ./hardware-configuration.nix 
			];

			time.timeZone = \"$TIMEZONE\";

			i18n.defaultLocale = \"$LOCALE\";

			services.xserver.xkb.layout = \"$KBD_LAYOUT\";
		}" >$HOST_CONFIG/default.nix

	# adds disko to the imports array
	if [[ $DISKO_CONFIG != "" ]]; then
		sed -i '/]/i./disko.nix' $HOST_CONFIG/default.nix
	fi

	if [[ $DESKTOP == "no-desktop" ]]; then
		DESKTOP=""
	fi

	if [[ $INSTALL_MODE == "new" ]]; then
		mkdir -p $CONFIG_ROOT/hosts
		# add the function header if this is a new configuration
		echo " { lib, outputs, ... }:
		{" >$HOSTS_CONFIG
	else
		# INSTALL_MODE "append"
		# remove the last character to make way for the new configuration
		sed -i '$ s/.$//' $HOSTS_CONFIG
	fi
	echo "$HOSTNAME = lib.mkHost {
			hostname = \"$HOSTNAME\";
			stateVersion = \"$STATEVERSION\";
			system = \"$ARCH-linux\";
			bios = \"$BIOS\";
			specialization = \"$SPECIALIZATION\"; 
			cpu = \"$CPU\";
			gpu = \"$GPU\";
			desktop = \"$DESKTOP\";
			configDir = ./$HOSTNAME;
			secretsFile = ./$HOSTNAME/secrets.yaml;
			extraModules = [ outputs.nixosModules.default ];
		};
	}
  " >>$HOSTS_CONFIG

	hardware_config
	nixfmt.sh $CONFIG_ROOT
}

disko_format() {
	pushd $REPO_DIR >/dev/null
	DISKO_CONFIG=$(fzf --border --border-label-pos 1:bottom --border-label="Choose a disko.nix file")

	# DISKO_CONFIG is a relative path to where ever the repository root currently is which will later be moved to /mnt/etc/nixos
	while [[ ! $DISKO_CONFIG != "*disko.nix" ]]; do
		DISKO_CONFIG=$(fzf --border --border-label-pos 1:bottom --border-label="File must end in disko.nix. Try again")
	done

	disko --mode destroy,format,mount $DISKO_CONFIG

	popd >/dev/null
}

format_disks() {
	if [[ $(ls /mnt) ]]; then
		y_or_n "/mnt contains files, is your disk mounted?" && return 0 || echo "empty the /mnt directory and run the installer again"
		exit 1
	fi

	printf "\nYou will need to choose and format a disk to install NixOS\n"
	if [[ $REPO_DIR != "" ]]; then
		y_or_n "Use a disko file from your repo?"

		if [[ $yn == [Yy]* ]]; then
			disko_format
			return 0
		fi
	fi

	# TODO disk encryption OOB
	echo "By default, the installer will create a boot partition with FAT32 and root partition with ext4, which is sufficient for daily use such as gaming or productivity work."
	echo "More complex setups such as RAID, or encrypted drives require manual setup or a disko.nix file."
	echo "In this case, you will have to format and mount the disks yourself or use a disko configuration file from an existing repository. Then, run the installer when you are finished."
	y_or_n "Allow the installer to format disks for you?"

	if [[ $yn == [Nn]* ]]; then
		echo "Partition, format, and mount the drives you wish to use for install. Then, run the installer again."
		exit 0
	fi

	DISKS=$(lsblk -dp | grep -v /dev/loop | grep -v "NAME")
	SELECTED_DISK=$(printf "%s\n" "${DISKS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Select a disk to install NixOS")

	if [[ $SELECTED_DISK == "" ]]; then
		echo "aborted"
		exit 1
	fi

	SELECTED_DISK=$(echo $SELECTED_DISK | cut -d " " -f1)
	y_or_n "WARNING: All data on $SELECTED_DISK will be destroyed. Are you sure you want to proceed?" || exit 1

	if [[ -d /sys/firmware/efi ]]; then
		BOOT_PART="1"
		ROOT_PART="2"
		BOOT_START="0%"
	else
		# TODO idk how to get this working with parted. Grub seems to install but it just doesn't boot
		echo "detected legacy firmware."
		echo "I have not managed to get legacy booting with grub working yet."
		echo "if you must install for legacy bios use a disko.nix file"
		exit 1

		# part 1 is for bios_grub boot
		# BOOT_PART="2"
		# ROOT_PART="3"
		# BOOT_START="1MiB"
	fi

	wipefs -a -f $SELECTED_DISK >/dev/null
	dd if=/dev/zero of=$SELECTED_DISK bs=1M count=1 >/dev/null

	# use a gpt disk regardless of firmware implementation
	parted -s $SELECTED_DISK mklabel gpt

	if [[ ! -d /sys/firmware/efi ]]; then
		parted -s $SELECTED_DISK \
			mkpart "bios-boot" 0% 1MiB \
			set 1 bios_grub on
	fi

	parted -a optimal -s $SELECTED_DISK \
		mkpart "esp" $BOOT_START 512MiB \
		set $BOOT_PART esp on \
		mkpart "root" 512MiB 100%

	if [[ $(echo $SELECTED_DISK | grep "nvme") ]]; then
		mkfs.fat -F 32 "$SELECTED_DISK""p""$BOOT_PART"
		mkfs.ext4 "$SELECTED_DISK""p""$ROOT_PART"

		mount "$SELECTED_DISK""p""$ROOT_PART" /mnt
		mkdir -p /mnt/boot
		mount "$SELECTED_DISK""p""$BOOT_PART" /mnt/boot
	else
		mkfs.fat -F 32 "$SELECTED_DISK""$BOOT_PART"
		mkfs.ext4 "$SELECTED_DISK""$ROOT_PART"

		mount "$SELECTED_DISK""$ROOT_PART" /mnt
		mkdir -p /mnt/boot
		mount "$SELECTED_DISK""$BOOT_PART" /mnt/boot
	fi
}

main() {
	if [[ ! $(whoami) == "root" ]]; then
		echo "You must be root."
		exit 1
	fi

	# for some reason the nix-daemon doesn't start on boot of the iso
	# start the nix-daemon if its not running already
	if [[ $(systemctl status nix-daemon | grep "inactive") ]]; then
		echo "starting nix daemon"
		systemctl start nix-daemon
	fi

	while [[ ! $(curl -s ifconfig.me) ]]; do
		y_or_n "No internet connection detected. Connect Now?" && nmtui || exit 0
	done

	echo "If this machine is a host that has already been configured via a nix repository, you can skip directly to the installation phase."
	y_or_n "Are you installing an existing host configuration?"

	if [[ $yn == [Yy]* ]]; then
		INSTALL_MODE="existing"
		install_existing_config
	fi

	echo " "
	echo "If you already have a nixos-hosts repository that was derived using this installer and its nix modules, you can append this configuration to that repository."
	y_or_n "Append to an existing repository?"

	if [[ $yn == [Yy]* ]]; then
		INSTALL_MODE="append"
		pull_repo
	else
		INSTALL_MODE="new"
	fi

	format_disks
	create_config
	create_swap
	nixos_install
}

main
