#!/bin/bash

#disable terminal history while inside of app
set +o history

if ! [[ -z $1 ]]; then
	if [[ $BRANCH_ALREADY_REFERENCED != '1' ]]; then
	export ROOT_BRANCH="$1"
	export BRANCH_ALREADY_REFERENCED='1'
	bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/multitoolbox.sh) $ROOT_BRANCH
	unset ROOT_BRANCH
	unset BRANCH_ALREADY_REFERENCED
	toolbox_close
	fi
else
	export ROOT_BRANCH='master'
fi
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/flux_common.sh)"

trap ctrl_c INT
function ctrl_c() {
	toolbox_close
}

if [[ -d /home/$USER/.zelcash ]]; then
	CONFIG_DIR='.zelcash'
	CONFIG_FILE='zelcash.conf'
else
	CONFIG_DIR='.flux'
	CONFIG_FILE='flux.conf'
fi

FLUX_DIR='zelflux'
FLUX_APPS_DIR='ZelApps'
COIN_NAME='zelcash'
dversion="v7.4"
PM2_INSTALL="0"
zelflux_setting_import="0"

function config_veryfity(){
	if [[ -f /home/$USER/.flux/flux.conf ]]; then
		echo -e "${ARROW} ${YELLOW}Checking config file...${NC}"
		insightexplorer=$(cat /home/$USER/.flux/flux.conf | grep 'insightexplorer=1' | wc -l)
		if [[ "$insightexplorer" == "1" ]]; then
			echo -e "${ARROW} ${CYAN}Insightexplorer enabled..............[${CHECK_MARK}${CYAN}]${NC}"
			echo ""
		else
			echo -e "${WORNING} ${CYAN}Insightexplorer disabled.............[${X_MARK}${CYAN}]${NC}"
			echo -e "${WORNING} ${CYAN}Use option 2 for node re-install${NC}"
			echo -e ""
			toolbox_close
		fi
	fi
}
function config_file() {
	if [[ -f /home/$USER/install_conf.json ]]; then

		import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
		bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
		bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
		use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
		prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
		outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
		index=$(cat /home/$USER/install_conf.json | jq -r '.index')
		zel_id=$(cat /home/$USER/install_conf.json | jq -r '.zelid')
		kda_address=$(cat /home/$USER/install_conf.json | jq -r '.kda_address')
		upnp_port=$(cat /home/$USER/install_conf.json | jq -r '.upnp_port')
    gateway_ip=$(cat /home/$USER/install_conf.json | jq -r '.gateway_ip')

		echo -e "${ARROW} ${YELLOW}Install config summary:"
		if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
			echo -e "${PIN}${CYAN}Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}"
		else
			if [[ "$import_settings" == "1" ]]; then
				echo -e "${PIN}${CYAN}Import settings from exist config files..........................[${CHECK_MARK}${CYAN}]${NC}"
			fi
		fi

		if [[ "$use_old_chain" == "1" ]]; then
			echo -e "${PIN}${CYAN}During re-installation old chain will be used....................[${CHECK_MARK}${CYAN}]${NC}"
		else
			if [[ "$bootstrap_url" == "" || "$bootstrap_url" == "0" ]]; then
				echo -e "${PIN}${CYAN}Use Flux Bootstrap from source build in scripts..................[${CHECK_MARK}${CYAN}]${NC}"
			else
				echo -e "${PIN}${CYAN}Use Flux Bootstrap from own source...............................[${CHECK_MARK}${CYAN}]${NC}"
			fi
			if [[ "$bootstrap_zip_del" == "1" ]]; then
				echo -e "${PIN}${CYAN}Remove Flux Bootstrap archive file...............................[${CHECK_MARK}${CYAN}]${NC}"
			else
				echo -e "${PIN}${CYAN}Leave Flux Bootstrap archive file................................[${CHECK_MARK}${CYAN}]${NC}"
			fi
		fi

		if [[ ( "$discord" != "" && "$discord" != "0" ) || "$telegram_alert" == '1' ]]; then
			echo -e "${PIN}${CYAN}Enable watchdog notification.....................................[${CHECK_MARK}${CYAN}]${NC}"
		else
			echo -e "${PIN}${CYAN}Disable watchdog notification....................................[${CHECK_MARK}${CYAN}]${NC}"
		fi

		if [[ ! -z $gateway_ip && ! -z $upnp_port ]]; then
			echo -e "${PIN}${CYAN}Enable UPnP configuration........................................[${CHECK_MARK}${CYAN}]${NC}" 
		fi
	fi
}
function install_flux() {

	echo -e "${GREEN}Module: Re-install FluxOS${NC}"
	echo -e "${YELLOW}================================================================${NC}"

	if [[ "$USER" == "root" || "$USER" == "ubuntu" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi

	if pm2 -v > /dev/null 2>&1; then
		pm2 del zelflux > /dev/null 2>&1
		pm2 del flux > /dev/null 2>&1
		pm2 save > /dev/null 2>&1
	fi
 
	docker_check=$(docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" | wc -l)
	resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
	mongod_check=$(mongoexport -d localzelapps -c zelappsinformation --jsonArray --pretty --quiet  | jq -r .[].name | head -n1)
	if [[ "$mongod_check" != "" && "$mongod_check" != "null" ]]; then
	echo -e "${ARROW} ${CYAN}Detected Flux MongoDB local apps collection ...${NC}"
	echo -e "${ARROW} ${CYAN}Cleaning MongoDB Flux local apps collection...${NC}"
	echo "db.zelappsinformation.drop()" | mongo localzelapps > /dev/null 2>&1
	fi

	if [[ $docker_check != 0 ]]; then
		echo -e "${ARROW} ${CYAN}Detected running docker container...${NC}"
		echo -e "${ARROW} ${CYAN}Removing containers...${NC}"
		sudo aa-remove-unknown > /dev/null 2>&1 && sudo service docker restart > /dev/null 2>&1
		docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" |
		while read line; do
			sudo docker stop $line > /dev/null 2>&1 && sleep 1
			sudo docker rm $line > /dev/null 2>&1 && sleep 1
		done
	fi

	if [[ $resource_check != 0 ]]; then
		echo -e "${ARROW} ${CYAN}Detected locked resource...${NC}"
		echo -e "${ARROW} ${CYAN}Unmounting locked Flux resource${NC}"
		df | egrep 'flux' | awk '{ print $1}' |
		while read line; do
			sudo umount -l $line
		done
	fi

	if [[ -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
		echo -e "${ARROW} ${CYAN}Import settings...${NC}"
		ZELID=$(grep -w zelid /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
		WANIP=$(grep -w ipaddress /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*ipaddress: .//' | sed -e 's/.\{2\}$//')
		echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$ZELID${NC}"
		KDA_A=$(grep -w kadena /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
		if [[ "$KDA_A" != "" ]]; then
			echo -e "${PIN}${CYAN}Kadena address = ${GREEN}$KDA_A${NC}"
		fi
		echo -e "${PIN}${CYAN}IP = ${GREEN}$WANIP${NC}"  
		echo -e ""
		echo -e "${ARROW} ${CYAN}Removing any instances of FluxOS....${NC}"
		sudo rm -rf $FLUX_DIR  > /dev/null 2>&1 && sleep 1
		if [[ "$ZELID" != "" && "$WANIP" != "" && "$KDA_A" != "" ]]; then
			zelflux_setting_import="1"
		fi
	fi

	if [ -d /home/$USER/$FLUX_DIR ]; then
		echo -e "${ARROW} ${CYAN}Removing any instances of FluxOS....${NC}"
		sudo rm -rf $FLUX_DIR  > /dev/null 2>&1 && sleep 1
	fi

	echo -e "${ARROW} ${CYAN}FluxOS downloading...${NC}"
	git clone https://github.com/RunOnFlux/flux.git zelflux > /dev/null 2>&1 && sleep 1
	if [[ -d /home/$USER/$FLUX_DIR ]]; then
		if [[ -f /home/$USER/$FLUX_DIR/package.json ]]; then
			current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
		else
			string_limit_x_mark "FluxOS was not downloaded, run script again..........................................."
			echo
			toolbox_close
		fi
		string_limit_check_mark "FluxOS v$current_ver downloaded..........................................." "FluxOS ${GREEN}v$current_ver${CYAN} downloaded..........................................."
	else
		string_limit_x_mark "FluxOS was not downloaded, run script again..........................................."
		echo
		toolbox_close
	fi

	if [[ "$zelflux_setting_import" == "0" ]]; then
		get_ip "install"
		while true
		do
			ZELID="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
			if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ]; then
				string_limit_check_mark "Zel ID is valid..........................................."
				break
			else
				string_limit_x_mark "Zel ID is not valid try again..........................................."
				sleep 2
			fi
		done

		while true
		do
			KDA_A=$(whiptail --inputbox "Node tier eligible to receive KDA rewards, what's your KDA address? Nothing else will be required on FluxOS regarding KDA." 8 85 3>&1 1>&2 2>&3)
			if [[ "$KDA_A" != "" && "$KDA_A" != *kadena* && "$KDA_A" = *k:*  ]]; then    
				echo -e "${ARROW} ${CYAN}Kadena address is valid.................[${CHECK_MARK}${CYAN}]${NC}"	
				KDA_A="kadena:$KDA_A?chainid=0"			    
				sleep 2
				break
			else	     
				echo -e "${ARROW} ${CYAN}Kadena address is not valid.............[${X_MARK}${CYAN}]${NC}"
				sleep 2		     
			fi
		done	 
	fi
	fluxos_conf_create
	if [[ -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
		string_limit_check_mark "FluxOS configuration successfull..........................................."
	else
		string_limit_x_mark "FluxOS installation failed, missing config file..........................................."
		echo
		toolbox_close
	fi

	if pm2 -v > /dev/null 2>&1; then 
		rm restart_zelflux.sh > /dev/null 2>&1
		pm2 del flux > /dev/null 2>&1
		pm2 del zelflux > /dev/null 2>&1
		pm2 save > /dev/null 2>&1
		echo -e "${ARROW} ${CYAN}Starting FluxOS....${NC}"
		echo -e "${ARROW} ${CYAN}FluxOS loading will take 2-3min....${NC}"
		echo -e ""
		pm2 start /home/$USER/$FLUX_DIR/start.sh --restart-delay=60000 --max-restarts=40 --name flux --time  > /dev/null 2>&1
		pm2 save > /dev/null 2>&1
		pm2 list
	else
		pm2_install
		if [[ "$PM2_INSTALL" == "1" ]]; then
			echo -e "${ARROW} ${CYAN}Starting FluxOS....${NC}"
			echo -e "${ARROW} ${CYAN}FluxOS loading will take 2-3min....${NC}"
			echo
			pm2 list
		fi
	fi
}
function create_config() {
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	echo -e "${GREEN}Module: Create FluxNode installation config file${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if jq --version > /dev/null 2>&1; then
		sleep 0.2
	else
		echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
		sudo apt  install jq -y > /dev/null 2>&1
		if jq --version > /dev/null 2>&1; then
			#echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
			string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
			echo
		else
			#echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
			string_limit_x_mark "JQ was not installed................................."
			echo
			toolbox_close
		fi
	fi
	skip_zelcash_config='0'
	skip_bootstrap='0'
	if [[ -d /home/$USER/$CONFIG_DIR ]]; then
		if whiptail --yesno "Would you like import old settings from daemon and Flux?" 8 65; then
			import_settings='1'
			skip_zelcash_config='1'
			sleep 1
		else
			import_settings='0'
			sleep 1
		fi
		if whiptail --yesno "Would you like use exist Flux chain?" 8 65; then
			use_old_chain='1'
			skip_bootstrap='1'
			sleep 1
		else
			use_old_chain='0'
			sleep 1
		fi
	fi

	if [[ "$skip_zelcash_config" == "1" ]]; then
		prvkey=""
		outpoint=""
		index=""
		zelid=""
		kda_address=""
		node_label="0" 
		fix_action="1"      
		eps_limit="0"
		discord="0"
		ping="0"
		telegram_alert="0"    
		telegram_bot_token="0"	      	      
		telegram_chat_id="0"	
	else
		prvkey=$(whiptail --inputbox "Enter your FluxNode Identity Key from Zelcore" 8 65 3>&1 1>&2 2>&3)
		sleep 1
		outpoint=$(whiptail --inputbox "Enter your FluxNode Collateral TX ID from Zelcore" 8 72 3>&1 1>&2 2>&3)
		sleep 1
		index=$(whiptail --inputbox "Enter your FluxNode Output Index from Zelcore" 8 65 3>&1 1>&2 2>&3)
		sleep 1
		while true
		do
			zel_id=$(whiptail --title "Flux Configuration" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)
			if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ]; then
				echo -e "${ARROW} ${CYAN}Zel ID is valid${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
				break
			else
				echo -e "${ARROW} ${CYAN}Zel ID is not valid try again...........[${X_MARK}${CYAN}]${NC}"
				sleep 4
			fi
		done
		sleep 1
		while true
		do
			KDA_A=$(whiptail --inputbox "Please enter your Kadena address from Zelcore" 8 85 3>&1 1>&2 2>&3)
			KDA_A=$(grep -Eo "^k:[0-9a-z]{64}\b" <<< "$KDA_A")
			if [[ "$KDA_A" != "" && "$KDA_A" != *kadena* && "$KDA_A" = *k:*  ]]; then    
				echo -e "${ARROW} ${CYAN}Kadena address is valid.................[${CHECK_MARK}${CYAN}]${NC}"	
				kda_address="kadena:$KDA_A?chainid=0"		    
				sleep 2
				break
			else	     
				echo -e "${ARROW} ${CYAN}Kadena address is not valid.............[${X_MARK}${CYAN}]${NC}"
				sleep 2		     
			fi
		done
		sleep 1
		if whiptail --yesno "Would you like enable autoupdate?" 8 65; then
			zelflux_update='1'
			zelcash_update='1'
			zelbench_update='1'
		else
			zelflux_update='0'
			zelcash_update='0'
			zelbench_update='0'   
		fi
		if whiptail --yesno "Would you like enable alert notification?" 8 65; then
			whiptail --msgbox "Info: to select/deselect item use 'space' ...to switch to OK/Cancel use 'tab' " 10 60
			sleep 1
			CHOICES=$(whiptail --title "Choose options: " --separate-output --checklist "Choose options: " 10 45 5 \
			"1" "Discord notification      " ON \
			"2" "Telegram notification     " OFF 3>&1 1>&2 2>&3 )
			if [[ -z "$CHOICES" ]]; then
				echo -e "${ARROW} ${CYAN}No option was selected...Alert notification disabled! ${NC}"
				sleep 1
				discord="0"
				ping="0"
				telegram_alert="0"
				telegram_bot_token="0"
				telegram_chat_id="0"
				node_label="0"
			else
				for CHOICE in $CHOICES; do
				case "$CHOICE" in
				"1")
					discord=$(whiptail --inputbox "Enter your discord server webhook url" 8 65 3>&1 1>&2 2>&3)
					sleep 1
					if whiptail --yesno "Would you like enable nick ping on discord?" 8 60; then
						while true
						do
							ping=$(whiptail --inputbox "Enter your discord user id" 8 60 3>&1 1>&2 2>&3)
						if [[ $ping == ?(-)+([0-9]) ]]; then
							string_limit_check_mark "UserID is valid..........................................."
							break
						else
							string_limit_x_mark "UserID is not valid try again............................."
							sleep 1
						fi
						done
						sleep 1
					else
						ping="0"
						sleep 1
					fi
				;;
				"2")
					telegram_alert="1"
					while true
					do
						telegram_bot_token=$(whiptail --inputbox "Enter telegram bot token from BotFather" 8 65 3>&1 1>&2 2>&3)
						if [[ $(grep ':' <<< "$telegram_bot_token") != "" ]]; then
						string_limit_check_mark "Bot token is valid..........................................."
						break
						else
							string_limit_x_mark "Bot token is not valid try again............................."
							sleep 1
						fi
					done
					sleep 1
					while true
					do
						telegram_chat_id=$(whiptail --inputbox "Enter your chat id from GetIDs Bot" 8 60 3>&1 1>&2 2>&3)
						if [[ $telegram_chat_id == ?(-)+([0-9]) ]]; then
							string_limit_check_mark "Chat ID is valid..........................................."
							break
						else
							string_limit_x_mark "Chat ID is not valid try again............................."
							sleep 1
						fi
					done
				 sleep 1
				;;
				esac
				done
			fi
			while true
			do
			node_label=$(whiptail --inputbox "Enter name of your node (alias)" 8 65 3>&1 1>&2 2>&3)
			if [[ "$node_label" != "" && "$node_label" != "0"  ]]; then
				string_limit_check_mark "Node name is valid..........................................."
				break
			else
				string_limit_x_mark "Node name is not valid try again............................."
				sleep 1
			fi
			done
		else
			discord="0"
			ping="0"
			telegram_alert="0"
			telegram_bot_token="0"
			telegram_chat_id="0"
			node_label="0"
			sleep 1
		fi

		if [[ "$discord" == 0 ]]; then
			ping="0"
		fi

		if [[ "$telegram_alert" == 0 || "$telegram_alert" == "" ]]; then
			telegram_alert="0"
			telegram_bot_token="0"
			telegram_chat_id="0"
		fi

		index_from_file="$index"
		tx_from_file="$outpoint"
		stak_info=$(curl -sSL -m 5 https://$network_url_1/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		if [[ "$stak_info" == "" ]]; then
			stak_info=$(curl -sSL -m 5 https://$network_url_2/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		fi	
		if [[ $stak_info == ?(-)+([0-9]) ]]; then
			case $stak_info in
			"1000") eps_limit=90 ;;
			"12500")  eps_limit=180 ;;
			"40000") eps_limit=300 ;;
			esac
		else
			eps_limit=0;
		fi
	fi
	if [[ "$skip_bootstrap" == "0" ]]; then
		if whiptail --yesno "Would you like use Flux bootstrap from script source?" 8 65; then
			bootstrap_url=""
			sleep 1
		else
			bootstrap_url=$(whiptail --inputbox "Enter your Flux bootstrap URL" 8 65 3>&1 1>&2 2>&3)
			sleep 1
		fi
		if whiptail --yesno "Would you like keep bootstrap archive file localy?" 8 65; then
			bootstrap_zip_del='0'
			sleep 1
		else
			bootstrap_zip_del='1'
			sleep 1
		fi
	fi
	if whiptail --yesno "Would you like to enable UPnP for this node?" 8 65; then
	  router_ip=$(ip rout | head -n1 | awk '{print $3}' 2>/dev/null)
		gateway_ip=$(whiptail --inputbox "Enter your UPnP Gateway IP: (This is usually your router: $router_ip)" 8 85 3>&1 1>&2 2>&3)
		upnp_port=$(whiptail --title "Enter your FluxOS UPnP Port" --radiolist \
		"Use the UP/DOWN arrows to highlight the port you want. Press Spacebar on the port you want to select, THEN press ENTER." 17 50 8 \
		"16127" "" ON \
		"16137" "" OFF \
		"16147" "" OFF \
		"16157" "" OFF \
		"16167" "" OFF \
		"16177" "" OFF \
		"16187" "" OFF \
		"16197" "" OFF 3>&1 1>&2 2>&3)
	else
		gateway_ip=""
		upnp_port=""
	fi
	firewall_disable='1'
	swapon='1'
	rm /home/$USER/install_conf.json > /dev/null 2>&1
	install_conf_create
	config_file
	echo -e  
}
function install_watchdog() {
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	echo -e "${GREEN}Module: Install watchdog for FluxNode${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if ! pm2 -v > /dev/null 2>&1; then
		pm2_install
		if [[ "$PM2_INSTALL" == "0" ]]; then
			toolbox_close
		fi
		echo -e ""
	fi
	echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
	pm2 del watchdog  > /dev/null 2>&1
	pm2 save  > /dev/null 2>&1
	sudo rm -rf /home/$USER/watchdog  > /dev/null 2>&1
	echo -e "${ARROW} ${CYAN}Downloading...${NC}"
	cd && git clone https://github.com/RunOnFlux/fluxnode-watchdog.git watchdog > /dev/null 2>&1
	echo -e "${ARROW} ${CYAN}Installing git hooks....${NC}"
	wget https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/post-merge > /dev/null 2>&1
	mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
	sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
	echo -e "${ARROW} ${CYAN}Installing watchdog module....${NC}"
	cd watchdog && npm install > /dev/null 2>&1
	echo -e "${ARROW} ${CYAN}Creating config file....${NC}"
	if whiptail --yesno "Would you like enable FluxOS auto update?" 8 60; then
		flux_update='1'
		sleep 1
	else
		flux_update='0'
		sleep 1
	fi
	if whiptail --yesno "Would you like enable Flux daemon auto update?" 8 60; then
		daemon_update='1'
		sleep 1
	else
		daemon_update='0'
		sleep 1
	fi
	if whiptail --yesno "Would you like enable Flux benchmark auto update?" 8 60; then
		bench_update='1'
		sleep 1
	else
		bench_update='0'
		sleep 1
	fi
	#if whiptail --yesno "Would you like enable fix action (restart daemon, benchmark, mongodb)?" 8 75; then
	fix_action='1'
	#sleep 1
	#else
	#fix_action='0'
	##sleep 1
	#fi
	telegram_alert=0;
	discord=0;
	if whiptail --yesno "Would you like enable alert notification?" 8 60; then
		sleep 1
		whiptail --msgbox "Info: to select/deselect item use 'space' ...to switch to OK/Cancel use 'tab' " 10 60
		sleep 1
		CHOICES=$(whiptail --title "Choose options: " --separate-output --checklist "Choose options: " 10 45 5 \
			"1" "Discord notification      " ON \
			"2" "Telegram notification     " OFF 3>&1 1>&2 2>&3 )
		if [[ -z "$CHOICES" ]]; then
			echo -e "${ARROW} ${CYAN}No option was selected...Alert notification disabled! ${NC}"
			sleep 1
			discord=0;
			ping=0;
			telegram_alert=0;
			telegram_bot_token=0;
			telegram_chat_id=0;
			node_label=0;
		else
			for CHOICE in $CHOICES; do
				case "$CHOICE" in
					"1")
						discord=$(whiptail --inputbox "Enter your discord server webhook url" 8 65 3>&1 1>&2 2>&3)
						sleep 1
						if whiptail --yesno "Would you like enable nick ping on discord?" 8 60; then
							while true
							do
								ping=$(whiptail --inputbox "Enter your discord user id" 8 60 3>&1 1>&2 2>&3)
								if [[ $ping == ?(-)+([0-9]) ]]; then
									string_limit_check_mark "UserID is valid..........................................."
									break
								else
									string_limit_x_mark "UserID is not valid try again............................."
									sleep 1
								fi
							done
							sleep 1
						else
							ping=0;
							sleep 1
						fi
					;;
					"2")
						telegram_alert=1;
						while true
						do
							telegram_bot_token=$(whiptail --inputbox "Enter telegram bot token from BotFather" 8 65 3>&1 1>&2 2>&3)
							if [[ $(grep ':' <<< "$telegram_bot_token") != "" ]]; then
								string_limit_check_mark "Bot token is valid..........................................."
								break
							else
								string_limit_x_mark "Bot token is not valid try again............................."
								sleep 1
							fi
						done

						sleep 1
						while true
						do
							telegram_chat_id=$(whiptail --inputbox "Enter your chat id from GetIDs Bot" 8 60 3>&1 1>&2 2>&3)
							if [[ $telegram_chat_id == ?(-)+([0-9]) ]]; then
								string_limit_check_mark "Chat ID is valid..........................................."
								break
							else
								string_limit_x_mark "Chat ID is not valid try again............................."
								sleep 1
							fi
						done

						sleep 1
					;;
				esac
			done
		fi

		while true
		do
			node_label=$(whiptail --inputbox "Enter name of your node (alias)" 8 65 3>&1 1>&2 2>&3)
			if [[ "$node_label" != "" && "$node_label" != "0"  ]]; then
				string_limit_check_mark "Node name is valid..........................................."
				break
			else
				string_limit_x_mark "Node name is not valid try again............................."
				sleep 1
			fi
		done
		sleep 1
	else
		node_label=0;
		discord=0;
		ping=0;
		telegram_alert=0;
		telegram_bot_token=0;
		telegram_chat_id=0;
		sleep 1
	fi
	if [[ $discord == 0 ]]; then
		ping=0;
	fi
	if [[ $telegram_alert == 0 ]]; then
		telegram_bot_token=0;
		telegram_chat_id=0;
	fi
	if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
		index_from_file=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
		tx_from_file=$(grep -w zelnodeoutpoint /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
		stak_info=$(curl -s -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		if [[ "$stak_info" == "" ]]; then
			stak_info=$(curl -s -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		fi	
	fi
	if [[ $stak_info == ?(-)+([0-9]) ]]; then
		case $stak_info in
		"1000") eps_limit=90 ;;
		"12500")  eps_limit=180 ;;
		"40000") eps_limit=300 ;;
		esac
	else
		eps_limit=0;
	fi
	watchdog_conf_create
	echo -e "${ARROW} ${CYAN}Starting watchdog...${NC}"
	pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
	pm2 save > /dev/null 2>&1
	if [[ -f /home/$USER/watchdog/watchdog.js ]]; then
		current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
		string_limit_check_mark "Watchdog v$current_ver installed..........................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed..........................................."  
	else
		string_limit_x_mark "Watchdog was not installed..........................................."
	fi
	echo -e ""
}
function flux_daemon_bootstrap() {
	echo -e "${GREEN}Module: Restore Flux blockchain from bootstrap${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	cd
	echo -e "${NC}"
	config_veryfity
	bootstrap_new
}
function install_node(){
	echo -e "${GREEN}Module: Install FluxNode${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		toolbox_close
	fi
	if [[ $(lsb_release -cs) == "jammy" ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		toolbox_close
	fi
	if sudo docker run hello-world > /dev/null 2>&1; then
		echo -e ""
	else
		echo -e "${WORNING}${CYAN}Docker is not working correct or is not installed.${NC}"
		toolbox_close
	fi
	bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/install_pro.sh)
}
function install_docker(){
	echo -e "${GREEN}Module: Install Docker${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" != "root" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the root account use command 'sudo su -'.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		toolbox_close
	fi
	if [[ $(lsb_release -cs) == "jammy" ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		toolbox_close
	fi
	if [[ -z "$usernew" ]]; then
		usernew="$(whiptail --title "MULTITOOLBOX $dversion" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
		usernew=$(awk '{print tolower($0)}' <<< "$usernew")
	else
		echo -e "${PIN}${CYAN} Import docker user '$usernew' from environment variable............[${CHECK_MARK}${CYAN}]${NC}" 
	fi
	echo -e "${ARROW} ${CYAN}New User: ${GREEN}${usernew}${NC}"
	adduser --gecos "" "$usernew" 
	usermod -aG sudo "$usernew" > /dev/null 2>&1  
	echo -e "${ARROW} ${YELLOW}Update and upgrade system...${NC}"
	apt update -y && apt upgrade -y 
	if ! ufw version > /dev/null 2>&1; then
		echo -e "${ARROW} ${YELLOW}Installing ufw firewall..${NC}"
		sudo apt-get install -y ufw > /dev/null 2>&1
	fi
	cron_check=$(systemctl status cron 2> /dev/null | grep 'active' | wc -l)
	if [[ "$cron_check" == "0" ]]; then
		echo -e "${ARROW} ${YELLOW}Installing crontab...${NC}"
		sudo apt-get install -y cron > /dev/null 2>&1
	fi
	echo -e "${ARROW} ${YELLOW}Installing docker...${NC}"
	echo -e "${ARROW} ${CYAN}Architecture: ${GREEN}$(dpkg --print-architecture)${NC}"      
	if [[ -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
		sudo rm /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
	fi
	if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
		sudo rm /etc/apt/sources.list.d/docker.list > /dev/null 2>&1 
	fi
	if [[ $(lsb_release -d) = *Debian* ]]; then
		sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1 
		sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1
		#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - > /dev/null 2>&1
		#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /dev/null 2>&1
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  
	else
		sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
		sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1  
		sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1  
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
		#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
		#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null 2>&1
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
	fi
	echo -e "${ARROW} ${YELLOW}Adding $usernew to docker group...${NC}"
	adduser "$usernew" docker 
	echo -e "${NC}"
	echo -e "${YELLOW}=====================================================${NC}"
	echo -e "${YELLOW}Running through some checks...${NC}"
	echo -e "${YELLOW}=====================================================${NC}"
	if sudo docker run hello-world > /dev/null 2>&1; then
		echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
	else
		echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
	fi
	if [[ $(getent group docker | grep "$usernew") ]]; then
		echo -e "${CHECK_MARK} ${CYAN}User $usernew is member of 'docker'${NC}"
	else
		echo -e "${X_MARK} ${CYAN}User $usernew is not member of 'docker'${NC}"
	fi
	echo -e "${YELLOW}=====================================================${NC}"
	echo -e "${NC}"
	read -p "Would you like switch to user account Y/N?" -n 1 -r
	echo -e "${NC}"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		su - $usernew
	fi
}
function install_watchtower(){
 echo -e "${GREEN}Module: Install flux_watchtower for docker images autoupdate${NC}"
 echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi 
	echo -e ""
	echo -e "${ARROW} ${CYAN}Checking if flux_watchtower is installed....${NC}"
	apps_check=$(docker ps | grep "flux_watchtower")
	if [[ "$apps_check" != "" ]]; then
		echo -e "${ARROW} ${CYAN}Stopping flux_watchtower...${NC}"
		docker stop flux_watchtower > /dev/null 2>&1
		sleep 2
		echo -e "${ARROW} ${CYAN}Removing flux_watchtower...${NC}"
		docker rm flux_watchtower > /dev/null 2>&1
	fi
	echo -e "${ARROW} ${CYAN}Downloading containrrr/watchtower image...${NC}"
	docker pull containrrr/watchtower:latest > /dev/null 2>&1
	echo -e "${ARROW} ${CYAN}Starting containrrr/watchtower...${NC}"
	random=$(shuf -i 7500-35000 -n 1)
	echo -e "${ARROW} ${CYAN}Interval: ${GREEN} $random sec.${NC}"
	apps_id=$(docker run -d \
	--restart unless-stopped \
	--name flux_watchtower \
	-v /var/run/docker.sock:/var/run/docker.sock \
	containrrr/watchtower \
	--cleanup --interval $random 2> /dev/null) 
	if [[ $apps_id =~ ^[[:alnum:]]+$ ]]; then
		echo -e "${ARROW} ${CYAN}flux_watchtower installed successful, id: ${GREEN}$apps_id${NC}"
	else
		echo -e "${ARROW} ${CYAN}flux_watchtower installion failed...${NC}"
	fi
 
}
function mongod_db_fix() {
	echo -e "${GREEN}Module: MongoDB FiX action${NC}"
	echo -e "${YELLOW}================================================================${NC}"
 if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi 


	 CHOICE=$(
 whiptail --title "MongoDB FiX action" --menu "Make your choice" 15 65 8 \
 "1)" "Soft repair - MongoDB database repair"   \
 "2)" "Hard repair - MongoDB re-install"  3>&2 2>&1 1>&3
	)
		case $CHOICE in
		"1)")
			echo -e ""  
			echo -e "${ARROW} ${YELLOW}Soft repair starting... ${NC}" 
			echo -e "${ARROW} ${CYAN}Stopping mongod service ${NC}" 
			sudo systemctl stop mongod
			echo -e "${ARROW} ${CYAN}Fix for corrupted DB ${NC}"
			sudo -u mongodb mongod --dbpath /var/lib/mongodb --repair > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Fix for bad privilege ${NC}" 
			sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
			sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Starting mongod service ${NC}" 
			sudo systemctl start mongod
			echo -e ""
		;;
		"2)")
			echo -e ""  
			echo -e "${ARROW} ${YELLOW}Hard repair starting... ${NC}" 
			echo -e "${ARROW} ${CYAN}Stopping mongod service...${NC}" 
			sudo systemctl stop mongod 
			#sudo rm -rf /home/$USER/mongoDB_backup.gz > /dev/null 2>&1
			#echo -e "${ARROW} ${CYAN}Backuping Database... ${NC}"
      #mongodump --archive=/home/$USER/mongoDB_backup.gz > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Removing MongoDB... ${NC}" 
			sudo apt-get purge mongodb-org -y > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Removing Database... ${NC}"
			sudo rm -r /var/log/mongodb > /dev/null 2>&1
			sudo rm -r /var/lib/mongodb > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Installing MongoDB... ${NC}"
			sudo apt install mongodb-org -y > /dev/null 2>&1
			sudo mkdir -p /var/log/mongodb > /dev/null 2>&1
			sudo mkdir -p /var/lib/mongodb > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Settings privilege... ${NC}"
			sudo chown -R mongodb:mongodb /var/log/mongodb > /dev/null 2>&1
			sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
			sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
		  #echo -e "${ARROW} ${CYAN}Restoring Database... ${NC}"
			#mongorestore --drop --archive=/home/$USER/mongoDB_backup.gz > /dev/null 2>&1
			echo -e "${ARROW} ${CYAN}Starting mongod service... ${NC}"
			sudo systemctl start mongod
			if mongod --version > /dev/null 2>&1; then
				string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
				echo -e "${ARROW} ${CYAN}Service status:${SEA} $(sudo systemctl status mongod | grep -w 'Active' | sed -e 's/^[ \t]*//')${NC}" 
			else
				string_limit_x_mark "MongoDB was not installed................................."
			fi
			echo -e ""
		;;
	esac

}
function node_reconfiguration() {
	reset=""
	if [[ -f /home/$USER/install_conf.json ]]; then
		import_config_file "silent"
		get_ip
		if [[ -d /home/$USER/zelflux ]]; then	  
			if [[ "$KDA_A" != "" && "$ZELID" != "" ]]; then
				echo -e "${ARROW} ${CYAN}Creating FluxOS config file...${NC}"
				sudo rm -rf /home/$USER/zelflux/config/userconfig.js > /dev/null 2>&1
				fluxos_conf_create
				reset=0
			fi
		fi
		if [[ -d /home/$USER/.flux ]]; then
      if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]]; then
				zelnodeprivkey="$prvkey"
				zelnodeoutpoint="$outpoint"
				zelnodeindex="$index"
				echo -e "${ARROW} ${CYAN}Creating Daemon config file...${NC}"
				sudo rm -rf /home/$USER/.flux/flux.conf > /dev/null 2>&1
				flux_daemon_conf_create
				reset=0
			fi
		fi
		if [[ -d /home/$USER/watchdog ]]; then
			echo -e "${ARROW} ${CYAN}Creating Watchdog config file...${NC}"
			sudo rm -rf /home/$USER/watchdog/config.js > /dev/null 2>&1
			fix_action='1'
  			watchdog_conf_create
			reset=0
		fi
		if [[ -d /home/$USER/.flux ]]; then
			if [[ ! -z "$upnp_port" && ! -z "$gateway_ip" ]]; then
				reset=1
				upnp_enable
			fi
		fi
		if [[ "$reset" == "0" ]]; then
			echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark...${NC}"
			sudo systemctl restart zelcash > /dev/null 2>&1
			pm2 restart flux > /dev/null 2>&1
			sleep 10
		fi
	else
	 echo -e "${ARROW} ${CYAN}Install config file not exist, operation aborted...${NC}"
	 echo -e ""
	fi
}

if ! figlet -v > /dev/null 2>&1; then
	sudo apt-get update -y > /dev/null 2>&1
	sudo apt-get install -y figlet > /dev/null 2>&1
fi

if ! pv -V > /dev/null 2>&1; then
	sudo apt-get install -y pv > /dev/null 2>&1
fi

if ! gzip -V > /dev/null 2>&1; then
	sudo apt-get install -y gzip > /dev/null 2>&1
fi

if ! zip -v > /dev/null 2>&1; then
	sudo apt-get install -y zip > /dev/null 2>&1
fi

if ! whiptail -v > /dev/null 2>&1; then
	sudo apt-get install -y whiptail > /dev/null 2>&1
fi

if [[ $(cat /etc/bash.bashrc | grep 'multitoolbox' | wc -l) == "0" ]]; then
	echo "alias multitoolbox='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox.sh)'" | sudo tee -a /etc/bash.bashrc
	echo "alias multitoolbox_testnet='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox_testnet.sh)'" | sudo tee -a /etc/bash.bashrc
	source /etc/bash.bashrc
fi

if ! wget --version > /dev/null 2>&1 ; then
	sudo apt install -y wget > /dev/null 2>&1 && sleep 2
fi
clear
sleep 1
echo -e "${BLUE}"
figlet -f slant "Multitoolbox"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${GREEN}Version: $dversion${NC}"
echo -e "${GREEN}Branch: $ROOT_BRANCH${NC}"
echo -e "${GREEN}OS: Ubuntu 16/18/19/20, Debian 9/10 ${NC}"
echo -e "${GREEN}Created by: X4MiLX from Flux's team${NC}"
echo -e "${GREEN}Special thanks to dk808, CryptoWrench, jriggs28 && TechDufus${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${CYAN}1  - Install Docker${NC}"
echo -e "${CYAN}2  - Install FluxNode${NC}"
echo -e "${CYAN}3  - FluxNode analyzer and fixer${NC}"
echo -e "${CYAN}4  - Install watchdog for FluxNode${NC}"
echo -e "${CYAN}5  - Restore Flux blockchain from bootstrap${NC}"
echo -e "${CYAN}6  - Create FluxNode installation config file${NC}"
echo -e "${CYAN}7  - Re-install FluxOS${NC}"
echo -e "${CYAN}8  - Flux Daemon Reconfiguration${NC}"
echo -e "${CYAN}9  - Create Flux daemon service ( for old nodes )${NC}"
echo -e "${CYAN}10 - Create Self-hosting cron ip service ${NC}"
echo -e "${CYAN}11 - FluxOS reconfiguration ${NC}"
echo -e "${CYAN}12 - Install fluxwatchtower for docker images autoupdate${NC}"
echo -e "${CYAN}13 - MongoDB FiX action${NC}"
echo -e "${CYAN}14 - Multinode configuration with UPNP communication (Needs Router with UPNP support)  ${NC}"
echo -e "${CYAN}15 - Node reconfiguration from install config${NC}"
echo -e "${YELLOW}================================================================${NC}"

read -rp "Pick an option and hit ENTER: "
case "$REPLY" in
 1)  
		clear
		sleep 1
		install_docker
 ;;
 2) 
		clear
		sleep 1
		install_node
 ;;
 3)     
		clear
		sleep 1
		analyzer_and_fixer
 ;;
	4)  
		clear
		sleep 1
		install_watchdog   
 ;;
	5)  
		clear
		sleep 1
		flux_daemon_bootstrap     
 ;; 
	6)
		clear
		sleep 1
		create_config
 ;;
	7)
		clear
		sleep 1
		install_flux
 ;;
 8)
	 clear
	 sleep 1
	 daemon_reconfiguration
 ;;
 9)
	clear
	sleep 1
	create_service_scripts
	create_service
	;;
	10)
	clear
	sleep 1
	selfhosting_creator
 ;;
	11)
	clear
	sleep 1
	fluxos_reconfiguration
	echo -e ""
 ;;
	12)
	clear
	sleep 1
	install_watchtower
	echo -e ""
	;;
	13)
	clear
	sleep 1
	mongod_db_fix
	echo -e ""
 ;;
	14)
	clear
	sleep 1
	multinode
	echo -e ""
 ;;
 	15)
	clear
	sleep 1
	echo -e "${GREEN}Module: Node reconfiguration from install config${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		toolbox_close
	fi
	node_reconfiguration
	echo -e ""
 ;;
esac
# USED FOR CLEANUP AT END OF SCRIPT
unset ROOT_BRANCH
unset BRANCH_ALREADY_REFERENCED
