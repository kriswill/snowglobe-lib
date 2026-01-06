#!/usr/bin/env bash
y_or_n() {
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
		[Yy]) return 0 ;;
		[Nn]) return 1 ;;
		*) echo "Not a valid response." ;;
		esac
	done
}

main() {
	if [[ $(whoami) != "root" ]]; then
		printf "You must be root.\n"
		exit 1
	fi

	if [[ $(systemctl status nix-daemon | grep "inactive") ]]; then
		printf "The nix daemon is not running. Starting it now.\n"
		systemctl start nix-daemon
	fi

	while [[ ! $(curl -s ifconfig.me) ]]; do
		y_or_n "No internet connection detected. Connect Now?" && nmtui || exit 0
	done

	printf "\nIf you have used this installer before, you might have already created a configuration for this host.\n"
	printf "In this case, assuming you have read access to the remote repository, you can skip directly to the installation phase.\n"
	printf "This mode can also be used to repair your system if somehow it cannot boot, even after a rollback.\n"
	y_or_n "Install an existing configuration?" && {
		install_existing_config
		post_install
	}

	printf "\nIf you have used this installer before, you should have an exiting configuration repository.\n"
	printf "If you wish, the installer allows you to seamlessly integrate your new configuration with the rest of your NixOS hosts and modules.\n"
	y_or_n "Append to your existing repository?" && {
		pull_repo
		INSTALLATION_METHOD="append"
	} || INSTALLATION_METHOD="new"

	format_disks
	create_config
	nixos_install
	post_install
}

format_disks() {
	if [[ $(ls -A /mnt) ]]; then
		printf "\nFiles were found in the /mnt directory, which is where your system will be installed.\n"
		printf "If this is due to a failed installation attempt, you do not have to format your drives again.\n"
		printf "Otherwise you should abort the installation and clear the directory first to avoid deletion of those files.\n"
		y_or_n "Is your disk mounted?" && return 0
	fi

	printf "\nThe installer will use a nix-community tool called disko to declaratively partition your hard drives or other persistent storage volumes.\n"
	printf "This allows you to easily store & re-deploy the partition scheme without reliance on nixos-generate-config or partition UUIDs\n"
	printf "By default, this will create a GPT partition table with a FAT32 partition for the bootloader and an ext4 partition for the OS root filesystem. This is suitable for most scenarios.\n"
	printf "If you wish to deploy a custom setup, such as a dual boot, RAID, or the use of a different filesystem, add the nix file to /etc/disko anywhere except the \"defaults\" directory before you continue.\n"
	printf "The disko repository: https://github.com/nix-community/disko/example has several examples to help you get started.\n"
	if [[ $REPO_DIR ]]; then
		printf "Since you have cloned a repository, you will also have the option to select a disko configuration from it to use for formatting.\n"
	fi

	y_or_n "Do you wish to proceed with formatting?" || exit 0

	if [[ $REPO_DIR ]]; then
		y_or_n "Use a disko file from your repo?" && {
			pushd $REPO_DIR >/dev/null
			SELECTED="$REPO_DIR/""$(fzf --border --border-label-pos 1:bottom --border-label="Choose a disko file to use for formatting. (Press ESC or Ctrl+C to cancel)")"
			popd >/dev/null
		}
	fi

	if [[ ! $SELECTED ]]; then
		DISKO_CONFIGURATIONS=$(find /etc/disko -type f | sed 's/\/etc\/disko\///' | grep -v defaults)
		if [[ $DISKO_CONFIGURATIONS ]]; then
			SELECTED=$(
				for config in $DISKO_CONFIGURATIONS; do
					file=/etc/disko/$config
					# small check to see if the file actually contains a disko config
					if [[ ! $(cat $file | grep disko) ]]; then
						continue
					else
						printf "%s\n" $config
					fi
				done | fzf --preview='cat /etc/disko/{}' --border --border-label-pos 1:bottom --border-label="Found the following custom configurations. Would you like to use one of these? (Press ESC or Ctrl+C to skip)"
			)
			if [[ $SELECTED ]]; then
				SELECTED="/etc/disko/""$SELECTED"
			else
				printf "\nNo custom disko configuration file selected, proceeding with defaults.\n"
			fi
		fi
	fi

	if [[ ! $SELECTED ]]; then
		ROWS=$(lsblk -p -do name,label,size,mountpoints | grep -ve "loop0" -e "sr0" -e "NAME")
		SELECTED_DISK=$(printf "%s" "${ROWS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Select a disk to install NixOS" | cut -d " " -f1)

		if [[ ! $SELECTED_DISK ]]; then
			printf "\nNo disk selected\n"
			exit 0
		fi

		printf "Selected Disk: %s\n" $SELECTED_DISK

		printf "\nTo protect your storage volume from theft, you have the option to encrypt it with LUKS using a password. (hardware keys are not yet supported)\n"
		y_or_n "Would you like to set up LUKS encryption?" && {
			while :; do
				read -p "Enter Password: " -s PASSWORD
				printf "\n"
				read -p "Retype Password: " -s PASSWORD2
				if [[ $PASSWORD != $PASSWORD2 ]]; then
					printf "\n\nPasswords do not match! Try again.\n"
				else
					printf "\n"
					break
				fi
			done
			printf "%s" $PASSWORD >/tmp/secret.key
			unset PASSWORD PASSWORD2
			LUKS=true
		}
		if [[ -d /sys/firmware/efi ]]; then
			PARTITION_MODE="uefi"
		else
			PARTITION_MODE="legacy"
		fi
		if [[ $LUKS ]]; then
			SELECTED=/etc/disko/defaults/luks-$PARTITION_MODE.nix
		else
			SELECTED=/etc/disko/defaults/default-$PARTITION_MODE.nix
		fi
	fi

	CURRENT_DISKO_FILE=/tmp/selected-disko-config.nix

	if [[ -e $CURRENT_DISKO_FILE ]]; then
		rm $CURRENT_DISKO_FILE
	fi
	cp $SELECTED $CURRENT_DISKO_FILE

	# TODO
	# If a disko file is copied from your repo, it is actually possible that the device specified is not the correct one
	# depending on the position of the drives in your board, udevadm can assign a different value to it per-boot.
	# This is rare and only comes up with drives that are not in the primary location on your board.
	# As of now, users must ensure that the disko file they are using targets the correct drives, using by-label or by-partlabel for example.

	if [[ $SELECTED_DISK ]]; then
		# replace default /dev/sda with whatever disk was selected
		sed -i "s|device = \"\/dev\/sda\"|device = \"$SELECTED_DISK\"|" $CURRENT_DISKO_FILE
	fi

	# Wipe all contents of the mount directory in preparation for mounting
	rm -rf /mnt || {
		printf "\nError: Could not remove contents of the /mnt directory.\n"
		exit 1
	}
	mkdir -p /mnt

	printf "\nPreparing to format disks.\n"
	# since disko 1.12+ gives a warning about what device its about to destroy, there is no need to implement that here.
	disko --mode destroy,format,mount $CURRENT_DISKO_FILE || {
		printf "\nError: Disko was unable to format the requested drives"
		exit 1
	}

	unset SELECTED
	if [[ -e /tmp/secret.key ]]; then
		rm /tmp/secret.key
	fi
}

create_config() {
	read -p "Set your system hostname (name your machine): " HOSTNAME
	CONFIG_ROOT=/mnt/etc/nixos
	# config directory for this specific host
	HOST_CONFIG=$CONFIG_ROOT/hosts/$HOSTNAME
	# file containing all hosts on your flake
	HOSTS_CONFIG=$CONFIG_ROOT/hosts/default.nix

	# "Out of the box" experiences
	SPECIALIZATIONS=(
		"Let me install my own bloatware."
		"server"
		"gaming"
	)

	# TODO describe the specializations in more detail
	SPECIALIZATION=$(printf "%s\n" "${SPECIALIZATIONS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Enable a specialization module listed here?")

	if [[ ! $SPECIALIZATION || $SPECIALIZATION == "Let me install my own bloatware." ]]; then
		printf "\nNo specialization modules will be enabled by default.\n"
		unset SPECIALIZATION
	fi

	# Gather system information

	# so these modules only allow for 1 cpu, what are the odds that somebody uses this in a dual CPU system of an AMD and Intel? Probably 0.
	if [[ $(lscpu | grep -i "intel") ]]; then
		CPU="intel"
	elif [[ $(lscpu | grep -i "amd") ]]; then
		CPU="amd"
	fi

	# TODO Multi GPU setups will not work if different gpu brands are used due to constraints of the old module.
	if [[ $(lspci -nnk | grep VGA | grep -i amd) ]]; then
		GPU="amd"
	elif [[ $(lspci -nnk | grep VGA | grep -i nvidia) ]]; then
		GPU="nvidia"
	# check for intel last in case of integrated graphics
	elif [[ $(lspci -nnk | grep VGA | grep -i intel) ]]; then
		GPU="intel"
	fi

	if [[ -d /sys/firmware/efi ]]; then
		BIOS="UEFI"
	else
		BIOS="legacy"
	fi

	ARCH=$(lscpu | grep Arch | tr -d " " | cut -d ":" -f2)
	STATEVERSION=$(nixos-version | cut -d "." -f1-2)

	# TODO research different locale encodings, update TXT if any other than UTF 8 are needed for any reason
	y_or_n "Use the default localization configuration? (en_US.UTF-8)" && LOCALE="en_US.UTF-8"

	if [[ ! $LOCALE ]]; then
		LOCALE=$(cat /etc/locales.txt | fzf --border --border-label-pos 1:bottom --border-label="Select the default locale")
		if [[ ! $LOCALE ]]; then
			printf "\nNo localization selected, assuming default (en_US.UTF-8)\n"
			LOCALE="en_US.UTF-8"
			# give people time to read
			sleep 2
		else
			LOCALE="$LOCALE"".UTF-8"
		fi
	fi

	printf "\nChosen Locale: $LOCALE\n"

	y_or_n "Use the default keyboard layout? (us)" && KBD_LAYOUT="us"

	if [[ ! $KBD_LAYOUT ]]; then
		KBD_LAYOUT=$(localectl list-keymaps | fzf --border --border-label-pos 1:bottom --border-label="Select a keyboard layout")
		if [[ ! $KBD_LAYOUT ]]; then
			printf "\nNo layout selected, assuming default (us)\n"
			KBD_LAYOUT="us"
			# give people time to read
			sleep 2
		fi
	fi

	printf "\nChosen Layout $KBD_LAYOUT\n"

	DESKTOPS=("hyprland" "niri" "plasma" "no-desktop")
	DESKTOP=$(printf "%s\n" "${DESKTOPS[@]}" | fzf --border --border-label-pos 1:bottom --border-label "Choose a desktop environment.")

	if [[ ! $DESKTOP ]]; then
		printf "\nNo desktop selected, using default (none)\n"
		# give people time to read
		sleep 2
	fi

	printf "\nChosen Desktop: $DESKTOP\n"

	printf "\n"
	echo "  NixOS will install with the following configuration.
  CPU - $CPU
  GPU - $GPU
  BIOS - $BIOS
  Arch - $ARCH 
  NixOS - $STATEVERSION
  Locale - $LOCALE
  Keyboard - $KBD_LAYOUT
  Desktop - $DESKTOP 
  Specialization - $SPECIALIZATION
"

	# Implementation

	# refresh the config files in case of an aborted or failed install
	if [[ -d $CONFIG_ROOT ]]; then
		rm -rf $CONFIG_ROOT
	fi
	mkdir -p $CONFIG_ROOT

	# create flake.nix if not in append mode
	if [[ $INSTALLATION_METHOD == "new" ]]; then
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
				nixosConfigurations = import ./hosts { inherit lib inputs outputs; };

				# expose your custom modules
				nixosModules.default = import ./nixosModules { inherit inputs lib; };

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
		" | install -D /dev/stdin "$CONFIG_ROOT/nixosModules/default.nix"

		echo "
		  # This module directory is reserved for any modules appended to the core NixOS module set such as appending to options.programs options.services or options.hardware
			{ }
		" | install -D /dev/stdin "$CONFIG_ROOT/nixosModules/core/default.nix"

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
		" | install -D /dev/stdin "$CONFIG_ROOT/nixosModules/mixins/default.nix"

		echo "
		  # create custom derivations using pkgs.callPackage
      { pkgs, ... }:
			{
        # my-package = pkgs.callPackage ./my-package.nix { };
			}
		" | install -D /dev/stdin "$CONFIG_ROOT/packages/default.nix"

		echo "
      { inputs, ... }:
      # overlays are functions which add derivations or modify existing derivations.
      # the flake.nix expects this to be a regular nix attribute set however
      # the nixos option \`nixpkgs.overlays\` requires the functions to be in an array to properly apply them to the configuration modules.
      # to apply them throughout your nixos configuration add:

      # nixpkgs.overlays = builtins.attrValues outputs.overlays;
      #
      # to your nixos configuration modules. Note: that \'outputs\' will need to be accessible for this module.
      {
        # EXAMPLE 
        # inputs.yazi.overlays.default;
      }
		" | install -D /dev/stdin "$CONFIG_ROOT/overlays.nix"

	# If in append mode, directory framework already exists. Move the repo from $REPO_DIR to /mnt/etc/nixos
	else
		mv $REPO_DIR/{.,}* $CONFIG_ROOT
		rm -rf $REPO_DIR
		# if hostname is the same as an existing configuration, replace it
		if [[ -d $HOST_CONFIG ]]; then
			rm -rf $HOST_CONFIG
		fi
	fi

	# start creating configuration specific to the host.
	mkdir -p $HOST_CONFIG

	# TODO hack where this is hardcoded in the installer. if the host somehow has a different default key file path set in the sops module this will cause an error.
	# Could fix by just forcing the sops age key file location in modules, but that would break the purpose of them.
	# This shouldn't come up too often (hopefully)
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

		# quick check to make sure 2 keys are not named the same thing
		if [[ $INSTALLATION_METHOD == "append" ]]; then
			while [[ $(cat $CONFIG_ROOT/.sops.yaml | grep "&$KEY_NAME") ]]; do
				printf "\nWARNING: Detected duplicate key names/aliases in .sops.yaml. Your new key name must be different than your other keys.\n"
				read -p "Create an alias for your new key (\`default\`, \`workstations\`, \`homelab\`, etc): " KEY_NAME
			done
		fi

		echo "Configuring sops..."
		# write the configuration to .sops.yaml
		if [[ $INSTALLATION_METHOD == "new" ]]; then
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
		echo "Completed, the generated private key is stored at $KEY_FILE."
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
		if [[ $INSTALLATION_METHOD == "new" ]]; then
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
		mkdir -p $USER_DIR

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
			  ./disko.nix
			];

			i18n.defaultLocale = \"$LOCALE\";

			services.xserver.xkb.layout = \"$KBD_LAYOUT\";
		}" >$HOST_CONFIG/default.nix

	if [[ $DESKTOP == "no-desktop" ]]; then
		unset DESKTOP
	fi

	if [[ $INSTALLATION_METHOD == "new" ]]; then
		mkdir -p $CONFIG_ROOT/hosts
		# add the function header if this is a new configuration
		echo " { lib, inputs, outputs, ... }:
		{" >$HOSTS_CONFIG
	else
		# with "append" remove the last character to make way for the new configuration
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
			extraSpecialArgs = { inherit inputs; };
			extraModules = [ outputs.nixosModules.default ];
		};
	}
  " >>$HOSTS_CONFIG

	hardware_config
	# format the nix files according to the nixpkgs RFC standard
	nixfmt.sh $CONFIG_ROOT
}

nixos_install() {
	# /tmp will be cleared on bootup if nixos option boot.tmp.cleanOnBoot is set (which it is by default in my config)
	if [[ $(cat /proc/meminfo | grep MemAvailable | cut -d ":" -f2 | tr -d " kB") -lt 4000000 && ! -f /mnt/tmp/swap ]]; then
		# unless you are installing on a REALLY small drive, this will work fine
		printf "\nWARNING: Detected less than 4GB of free ram\nNixOS requires at least 4GB of free ram to install smoothly.\nCreating a 8GB swap file at /mnt/tmp/swap.\n"
		printf "This file will be cleared upon next bootup and Zram swap will be enabled for this system to ensure it runs smoothly after install.\n"
		mkdir -p /mnt/tmp
		dd if=/dev/zero of=/mnt/tmp/swap bs=1024 count=8000000 || {
			printf "\nError: Unable to create swap file.\n"
			exit 1
		}
		mkswap /mnt/tmp/swap || {
			printf "\nError: Could not use mkswap on that file\n"
			exit 1
		}
		chmod 600 /mnt/tmp/swap
		swapon /mnt/tmp/swap || {
			printf "\nError: Could not activate the swap file with swapon.\n"
			exit 1
		}
	fi

	if [[ $INSTALLATION_METHOD == "append" ]]; then
		# the infamous bug with nix flakes where if the new files are not added to git they cannot be realized to the /nix/store
		git -C $CONFIG_ROOT add $CONFIG_ROOT
	fi

	if [[ ! -d $HOST_CONFIG/users ]]; then
		# if no users have been configured, ensure root gets a password
		# This password will not be declaratively stored with sops.
		nixos-install --no-channel-copy --flake "/mnt/etc/nixos#$HOSTNAME" || {
			printf "\nERROR: Installation failed or aborted.\n"
			exit 1
		}
	else
		nixos-install --no-channel-copy --no-root-password --flake "/mnt/etc/nixos#$HOSTNAME" || {
			printf "\nERROR: Installation failed or aborted.\n"
			exit 1
		}
	fi
}

pull_repo() {
	REPO_DIR=/tmp/repository

	if [[ -d $REPO_DIR && $(ls -A $REPO_DIR) ]]; then
		printf "\nFiles were found in the directory in which your repository will be cloned: $REPO_DIR\n"
		printf "This only occurs if a previous installation attempt was aborted before the files could be moved.\n"
		y_or_n "Do you wish to clear the contents of $REPO_DIR and pull your repository again?" || return 0
		rm -rf $REPO_DIR
	fi

	mkdir -p $REPO_DIR

	while :; do
		read -p "Enter the url for your repository: " REPO_URL
		git ls-remote $REPO_URL || {
			printf "Could not pull repository, Maybe the url provided is invalid?\n"
			continue
		}
		break
	done

	git clone $REPO_URL --depth 1 $REPO_DIR || {
		printf "\nSomething went wrong while pulling the repository\n"
		exit 1
	}
}

hardware_config() {
	if [[ ! $HOST_CONFIG ]]; then
		printf "\nError: Hardware configuration function called without HOST_CONFIG being set. This is a bug.\n"
		exit 1
	fi

	HARDWARE_CONFIG=$HOST_CONFIG/hardware-configuration.nix
	if [[ -e $HARDWARE_CONFIG ]]; then
		rm $HARDWARE_CONFIG
	fi

	# generate only the kernel modules and other basic configuration as filesystems are handled by disko
	nixos-generate-config --no-filesystems --root /mnt >/dev/null
	# remove the generated configuration.nix as all we care about is the hardware report
	rm $CONFIG_ROOT/configuration.nix

	mv $CONFIG_ROOT/hardware-configuration.nix $HOST_CONFIG

	# enable ZramSwap if the host has 4 GB or less RAM
	if [[ $(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | tr -d " kB") -le 5000000 ]]; then
		printf "\nDetected a small amount of available RAM for this host.\n"
		printf "The installer will enable a module for compressed zramSwap to assist with RAM management\n"

		sed -i '$ s/.$//' $HOST_CONFIG/default.nix
		echo "zramSwap.enable = true;" >>$HOST_CONFIG/default.nix
		echo "}" >>$HOST_CONFIG/default.nix
	fi

	# assume that if /tmp/selected-disko-config.nix exists, the formatting process was run for this host and any existing config should be replaced by it
	if [[ -e /tmp/selected-disko-config.nix && $HOST_CONFIG/disko.nix ]]; then
		rm -f $HOST_CONFIG/disko.nix
	fi

	if [[ ! -e $HOST_CONFIG/disko.nix ]]; then
		# get the disko file in place.
		if [[ ! -e /tmp/selected-disko-config.nix ]]; then
			printf "\nERROR: Neither a disko configuration file for this host nor a configuration file generated by the installer could be found.\n"
			printf "This can only happen in very specific scenarios such as rebooting the installer or clearing /tmp before the configuration files could get properly copied.\n"
			printf "Alternatively, it could be caused by a faulty configuration that does not contain a disko.nix\n"
			printf "It can be fixed by reformatting or placing a valid disko file at $HOST_CONFIG/disko.nix\n"
			exit 1
		fi
		cp /tmp/selected-disko-config.nix $HOST_CONFIG/disko.nix || {
			printf "\nERROR: Failed to copy /tmp/selected-disko-config.nix to $HOST_CONFIG\n"
			exit 1
		}
	else
		return 0
	fi
}

install_existing_config() {
	pull_repo

	if [[ ! $REPO_DIR ]]; then
		printf "\nError: Repo dir is not set but the existing config function was called. This is a bug.\n"
		exit 1
	fi

	CONFIGURATIONS=($(nix eval $REPO_DIR'#'nixosConfigurations --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'))
	HOSTNAME=$(printf "%s\n" "${CONFIGURATIONS[@]}" | fzf --border --border-label-pos 1:bottom --border-label="Found the following configurations. Which one would you like to install?")

	HOST_CONFIG="/mnt/etc/nixos/hosts/$HOSTNAME"

	if [[ ! $HOSTNAME ]]; then
		printf "\nNo host was selected.\n"
		exit 0
	fi

	format_disks

	mkdir -p /mnt/etc/nixos

	mv $REPO_DIR/{.,}* /mnt/etc/nixos
	rm -rf $REPO_DIR

	# regenerate the hardware configuration on every re-install
	# Since the file is never supposed to be touched anyway, this will cover some hardware changes if they occur.
	# TODO one day when nixos-factor matures enough, use that
	hardware_config

	printf "\nchecking configuration\n"
	if [[ $(nix eval /mnt/etc/nixos'#'nixosConfigurations.$HOSTNAME.config.sops.secrets) != "{ }" ]]; then
		SOPS_KEYFILE=$(nix eval /mnt/etc/nixos'#'nixosConfigurations.$HOSTNAME.config.sops.age.keyFile | tr -d '"')
		if [[ ! -f /mnt$SOPS_KEYFILE ]]; then
			printf "\nDetected sops secrets from this configuration.\n"
			printf "You will need to imperatively place your private age key file at /mnt%s before you continue\n" $SOPS_KEYFILE
			printf "Press any key to continue..."
			read -n 1 key
		fi

		while [[ ! -f /mnt$SOPS_KEYFILE ]]; do
			printf "Keyfile not found.\nEnsure the file is present in /mnt%s before you continue.\n" $SOPS_KEYFILE
			printf "Press any key to continue..."
			read -n 1 key
		done
	fi

	printf "\nChecks complete. No further action needed.\n"
	printf "Installing now.\n"

	nixos_install
}

post_install() {
	printf "You should be able to boot NixOS after you reboot.\n"

	if [[ -d /sys/firmware/efi ]]; then
		printf "\nWARNING: On modern UEFI systems manufactured by MSI, I have observed several instances in which the boot entries are not accessible via the UEFI configuration menu after a reboot.\n"
		printf "As of now, only MSI seems to be affected, and if you have a board from another manufacturer, everything should be ok.\n"
		printf "In this case, you may want to research and use the tool \`efibootmgr\` to manually add the boot entry to your system before you reboot.\n"
	fi

	y_or_n "Reboot now?" && reboot
	exit 0
}

main
