#!/bin/bash
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/flux_common.sh)"
#wallet information
COIN_NAME='flux'
CONFIG_DIR='.flux'
CONFIG_FILE='flux.conf'
BENCH_NAME='fluxbench'
BENCH_CLI='fluxbench-cli'
BENCH_DIR_LOG='.fluxbenchmark'
COIN_DAEMON='fluxd'
COIN_CLI='flux-cli'
COIN_PATH='/usr/local/bin'
USERNAME="$(whoami)"
FLUX_DIR='zelflux'
#Install variable
IMPORT_ZELCONF="0"
IMPORT_ZELID="0"
CORRUPTED="0"
BOOTSTRAP_SKIP="0"
WATCHDOG_INSTALL="0"
SKIP_OLD_CHAIN="0"
#Zelflux ports
ZELFRONTPORT=16126
LOCPORT=16127
ZELNODEPORT=16128
#MDBPORT=27017


function config_veryfity(){
  if [[ -f /home/$USER/.flux/flux.conf ]]; then
	echo -e "${ARROW} ${YELLOW}Checking config file...${NC}"
	insightexplorer=$(cat /home/$USER/.flux/flux.conf | grep 'insightexplorer=1' | wc -l)
	if [[ "$insightexplorer" == "1" ]]; then
		echo -e "${ARROW} ${CYAN}Insightexplorer enabled.................[${CHECK_MARK}${CYAN}]${NC}"
	else
		echo -e "${ARROW} ${CYAN}Insightexplorer enabled.................[${X_MARK}${CYAN}]${NC}"
		echo -e "${ARROW} ${CYAN}Removing wallet.dat...${NC}"
		echo -e "${ARROW} ${CYAN}Use old chain will be skipped...${NC}"
		sudo rm -rf /home/$USER/$CONFIG_DIR/wallet.dat && sleep 1
		SKIP_OLD_CHAIN="1"
	fi
  fi
}
function import_date() {
	if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
		if [[ -z "$import_settings" ]]; then
			if whiptail --yesno "Would you like to import data from Flux config files Y/N?" 8 60; then
		          config_smart_create "import"
			  IMPORT_ZELCONF="1"
		          if [[ "$ZELID" != "" ]]; then
		            IMPORT_ZELID="1"
			  fi 		
			fi   
		else 
			if [[ "$import_settings" == "1" ]]; then	  
		          config_smart_create "import"
			  IMPORT_ZELCONF="1"
		          if [[ "$ZELID" != "" ]]; then
		            IMPORT_ZELID="1"
			  fi     
			fi
		fi
	fi
	echo -e ""
}
function install_watchdog() {
	echo -e "${ARROW} ${YELLOW}Watchdog installing...${NC}"
	if pm2 -v > /dev/null 2>&1; then
		WATCHDOG_INSTALL="1"
		cd && git clone https://github.com/RunOnFlux/fluxnode-watchdog.git watchdog > /dev/null 2>&1
		wget https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/post-merge > /dev/null 2>&1
		mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
		sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
		cd watchdog && npm install > /dev/null 2>&1
		echo -e "${ARROW} ${CYAN}Creating config file....${NC}"
		fix_action='1'
		if [[ "$import_settings" == "0"  && -f /home/$USER/install_conf.json ]]; then
			watchdog_conf_create
			if [[ -f /home/$USER/watchdog/watchdog.js ]]; then
				current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
				string_limit_check_mark "Watchdog v$current_ver installed................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed................................."
				pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
				pm2 save > /dev/null 2>&1
			else
				string_limit_x_mark "Watchdog was not installed................................."
			fi  
			return 
		fi
		if [[ "$IMPORT_ZELCONF" == "1" ]]; then
			watchdog_conf_create
			if [[ -f /home/$USER/watchdog/watchdog.js ]]; then
				current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
				string_limit_check_mark "Watchdog v$current_ver installed................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed................................."
				pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
				pm2 save > /dev/null 2>&1
			else
				string_limit_x_mark "Watchdog was not installed................................."
			fi
			return 
		fi
		if whiptail --yesno "Would you like enable autoupdate?" 8 60; then
			flux_update='1'
			daemon_update='1'
			bench_update='1'
		else
			flux_update='0'
			daemon_update='0'
			bench_update='0'
		fi
		discord='0'
		if whiptail --yesno "Would you like enable alert notification?" 8 60; then
			sleep 1
			whiptail --msgbox "Info: to select/deselect item use 'space' ...to switch to OK/Cancel use 'tab' " 10 60
			sleep 1
			CHOICES=$(whiptail --title "Choose options: " --separate-output --checklist "Choose options: " 10 45 5 \
			"1" "Discord notification      " ON \
			"2" "Telegram notification     " OFF 3>&1 1>&2 2>&3 )
			if [ -z "$CHOICES" ]; then
				echo -e "${ARROW} ${CYAN}No option was selected...Alert notification disabled! ${NC}"
				sleep 1
				discord="0"
				ping="0"
				telegram_alert="0"
				telegram_bot_token="0"
				telegram_chat_id="0"
				node_label="0"
			else
				for CHOICE in $CHOICES; 
				do
					case "$CHOICE" in
					"1")
						discord=$(whiptail --inputbox "Enter your discord server webhook url" 8 65 3>&1 1>&2 2>&3)
						sleep 1
						if whiptail --yesno "Would you like enable nick ping on discord?" 8 60; then
							try="0"
							while true
							do
								ping=$(whiptail --inputbox "Enter your discord user id" 8 60 3>&1 1>&2 2>&3)
								if [[ $ping == ?(-)+([0-9]) ]]; then
									string_limit_check_mark "UserID is valid..........................................."
									break
								else
									string_limit_x_mark "UserID is not valid try again............................."
									sleep 1
									try=$(($try+1))
									if [[ "$try" -gt "3" ]]; then
										echo -e "${WORNING} ${CYAN}You have reached the maximum number of attempts...${NC}" 
										echo -e "${WORNING} ${CYAN}Disabling ping but continue watchdog install ...${NC}"
										ping=0;
										break
									fi
								fi
							done
							sleep 1
						else
							 ping=0;
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
			ping="0";
		fi
		if [[ "$telegram_alert" == 0 ]]; then
			telegram_bot_token="0";
			telegram_chat_id="0";
		fi
		if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
			index_from_file=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
			tx_from_file=$(grep -w zelnodeoutpoint /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
			stak_info=$(curl -s -m 5 https://$network_url_1/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
			if [[ "$stak_info" == "" ]]; then
			stak_info=$(curl -s -m 5 https://$network_url_2/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
			fi	   
		fi
		if [[ $stak_info == ?(-)+([0-9]) ]]; then

			case $stak_info in
				"1000") eps_limit=240 ;;
				"12500")  eps_limit=640 ;;
				"40000") eps_limit=1520 ;;
			esac
		else
			eps_limit=0;
		fi
		watchdog_conf_create
		pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
		pm2 save > /dev/null 2>&1
		if [[ -f /home/$USER/watchdog/watchdog.js ]]; then
			current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
			string_limit_check_mark "Watchdog v$current_ver installed................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed................................."
		else
			string_limit_x_mark "Watchdog was not installed................................."
		fi
	else
		string_limit_x_mark "Watchdog was not installed................................."
	fi
}
function wipe_clean() {
	echo -e "${ARROW} ${YELLOW}Removing any instances of FluxNode${NC}"
	apt_number=$(ps aux | grep 'apt' | wc -l)
	if [[ "$apt_number" > 1 ]]; then
		sudo killall apt > /dev/null 2>&1
		sudo killall apt-get > /dev/null 2>&1
		sudo dpkg --configure -a > /dev/null 2>&1
	fi
	echo -e "${ARROW} ${CYAN}Stopping all services and running processes...${NC}"
	sudo killall nano > /dev/null 2>&1
	$COIN_CLI stop > /dev/null 2>&1 && sleep 2
	sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
	sudo killall -s SIGKILL $COIN_DAEMON > /dev/null 2>&1 && sleep 2
	$BENCH_CLI stop > /dev/null 2>&1 && sleep 2
	sudo killall -s SIGKILL $BENCH_NAME > /dev/null 2>&1 && sleep 1
	sudo fuser -k 16127/tcp > /dev/null 2>&1 && sleep 1
	sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
	sudo rm -rf /usr/bin/flux* > /dev/null 2>&1 && sleep 1
	echo -e "${ARROW} ${CYAN}Removing daemon && benchmark...${NC}"
	sudo apt-get remove $COIN_NAME $BENCH_NAME -y > /dev/null 2>&1 && sleep 1
	sudo apt-get purge $COIN_NAME $BENCH_NAME -y > /dev/null 2>&1 && sleep 1
	sudo apt-get autoremove -y > /dev/null 2>&1 && sleep 1
	sudo rm -rf /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1 && sleep 1
	tmux kill-server > /dev/null 2>&1 && sleep 1
	echo -e "${ARROW} ${CYAN}Removing PM2...${NC}"
	pm2 del zelflux > /dev/null 2>&1 && sleep 1
	pm2 del flux > /dev/null 2>&1 && sleep 1
	pm2 del watchdog > /dev/null 2>&1 && sleep 1
	pm2 save > /dev/null 2>&1
	pm2 unstartup > /dev/null 2>&1 && sleep 1
	pm2 flush > /dev/null 2>&1 && sleep 1
	pm2 save > /dev/null 2>&1 && sleep 1
	pm2 kill > /dev/null 2>&1  && sleep 1
	npm remove pm2 -g > /dev/null 2>&1 && sleep 1
	echo -e "${ARROW} ${CYAN}Removing others files and scripts...${NC}"
	sudo rm -rf watchgod > /dev/null 2>&1 && sleep 1
	sudo rm -rf $BENCH_DIR_LOG && sleep 1
	sudo rm -rf /etc/logrotate.d/mongolog > /dev/null 2>&1
	sudo rm -rf /etc/logrotate.d/zeldebuglog > /dev/null 2>&1
	rm update.sh > /dev/null 2>&1
	rm restart_zelflux.sh > /dev/null 2>&1
	rm zelnodeupdate.sh > /dev/null 2>&1
	rm start.sh > /dev/null 2>&1
	rm update-zelflux.sh > /dev/null 2>&1  
	sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
	zelcash-cli stop > /dev/null 2>&1 && sleep 2
	sudo killall -s SIGKILL zelcashd > /dev/null 2>&1
	zelbench-cli stop > /dev/null 2>&1
	sudo killall -s SIGKILL zelbenchd > /dev/null 2>&1
	sudo rm /usr/local/bin/zel* > /dev/null 2>&1 && sleep 1
	sudo apt-get purge zelcash zelbench -y > /dev/null 2>&1 && sleep 1
	sudo apt-get autoremove -y > /dev/null 2>&1 && sleep 1
	sudo rm /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1 && sleep 1
	sudo rm -rf zelflux  > /dev/null 2>&1 && sleep 1
	sudo rm -rf .zelbenchmark  > /dev/null 2>&1 && sleep 1
	sudo rm -rf .fluxbenchmark  > /dev/null 2>&1 && sleep 1
	sudo rm -rf /home/$USER/stop_zelcash_service.sh > /dev/null 2>&1
	sudo rm -rf /home/$USER/start_zelcash_service.sh > /dev/null 2>&1
	if [[ -d /home/$USER/.zelcash  ]]; then
		echo -e "${ARROW} ${CYAN}Moving ~/.zelcash to ~/.flux${NC}"   
		sudo mv /home/$USER/.zelcash /home/$USER/.flux > /dev/null 2>&1 && sleep 1
		sudo mv /home/$USER/.flux/zelcash.conf /home/$USER/.flux/flux.conf > /dev/null 2>&1 && sleep 1   
	fi
	if [[ -d /home/$USER/$CONFIG_DIR ]]; then
		config_veryfity
		if [[ -z "$use_old_chain" ]]; then
			if [[ "$SKIP_OLD_CHAIN" == "0" ]]; then       
				if  ! whiptail --yesno "Would you like to use old chain from Flux daemon config directory?" 8 60; then
					echo -e "${ARROW} ${CYAN}Removing Flux daemon config directory...${NC}"
					sudo rm -rf /home/$USERNAME/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate > /dev/null 2>&1
					sudo rm -rf /home/$USER/$CONFIG_DIR  > /dev/null 2>&1
				else
					BOOTSTRAP_SKIP="1"
					sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
					sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat 
					sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
					sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat 
					sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
					sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
					sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log 
					sudo rm -rf /home/$USER/$CONFIG_DIR/flux.conf 
					sudo rm -rf /home/$USER/$CONFIG_DIR/database 
					sudo rm -rf /home/$USER/$CONFIG_DIR/sporks 
				fi 
			else
				echo -e "${ARROW} ${CYAN}Removing Flux daemon config directory...${NC}"
				sudo rm -rf /home/$USER/$CONFIG_DIR/determ_zelnodes /home/$USER/$CONFIG_DIR/sporks /home/$USER/$CONFIG_DIR/database /home/$USER/$CONFIG_DIR/blocks /home/$USER/$CONFIG_DIR/chainstate > /dev/null 2>&1  
				sudo rm -rf /home/$USER/$CONFIG_DIR  > /dev/null 2>&1 
			fi
		else
			if [[ "$use_old_chain" == "1" ]]; then
				BOOTSTRAP_SKIP="1"
				sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
				sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat
				sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
				sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat
				sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
				sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
				sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log 
				sudo rm -rf /home/$USER/$CONFIG_DIR/flux.conf 
				sudo rm -rf /home/$USER/$CONFIG_DIR/database 
				sudo rm -rf /home/$USER/$CONFIG_DIR/sporks 
			else
				 echo -e "${ARROW} ${CYAN}Removing Flux daemon config directory...${NC}"
				sudo rm -rf /home/$USER/$CONFIG_DIR/determ_zelnodes /home/$USER/$CONFIG_DIR/sporks /home/$USER/$CONFIG_DIR/database /home/$USER/$CONFIG_DIR/blocks /home/$USER/$CONFIG_DIR/chainstate > /dev/null 2>&1
				sudo rm -rf /home/$USER/$CONFIG_DIR  > /dev/null 2>&1
			fi
		fi
	fi
	sudo rm -rf /home/$USER/watchdog > /dev/null 2>&1
	sudo rm -rf /home/$USER/stop_daemon_service.sh > /dev/null 2>&1
	sudo rm -rf /home/$USER/start_daemon_service.sh > /dev/null 2>&1
	echo -e "${ARROW} ${YELLOW}Checking firewall status...${NC}" && sleep 1
	if [[ $(sudo ufw status | grep "Status: active") ]]; then
		sudo ufw disable > /dev/null 2>&1
		echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
	else
		echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
	fi
}
function ssh_port() { 
	if [[ -z "$ssh_port" ]]; then
		SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
		echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
	else   		
		pettern='^[0-9]+$'
		if [[ $ssh_port =~ $pettern ]] ; then
			SSHPORT="$ssh_port"
			echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
		else
			echo -e "${ARROW} ${CYAN}SSH port must be integer................[${X_MARK}${CYAN}]${NC}}"
			echo
			exit
		fi	   
	fi
}
function create_conf() {
	echo -e "${ARROW} ${YELLOW}Creating Flux daemon config file...${NC}"
	if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
		echo -e "${ARROW} ${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
		mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
	fi
	if [[ "$IMPORT_ZELCONF" == "0" ]]; then
		zelnodeprivkey=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode Identity Key generated by your Zelcore" 8 72 3>&1 1>&2 2>&3)
		zelnodeoutpoint=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode Collateral TX ID" 8 72 3>&1 1>&2 2>&3)
		zelnodeindex=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode Output Index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
	fi
	mkdir /home/$USER/$CONFIG_DIR > /dev/null 2>&1
	flux_daemon_conf_create
	if [[ "$IMPORT_ZELID" == "0" ]]; then
		while true
		do
			ZELID=$(whiptail --title "Flux Configuration" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)
			if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ] || [ $(grep -Eo "^0x[a-fA-F0-9]{40}$" <<< "$ZELID") ]; then
				echo -e "${ARROW} ${CYAN}Zel ID is valid${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
				break
			else
				echo -e "${ARROW} ${CYAN}Zel ID is not valid try again...........[${X_MARK}${CYAN}]${NC}"
				sleep 4
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
}
function install_daemon() {
   sudo rm /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1
   sudo rm /etc/apt/sources.list.d/flux.list > /dev/null 2>&1
   echo -e "${ARROW} ${YELLOW}Configuring daemon repository and importing public GPG Key${NC}" 
   sudo chown -R $USER:$USER /usr/share/keyrings > /dev/null 2>&1
   sudo chown -R $USER:$USER /home/$USER/.gnupg > /dev/null 2>&1
	if [[ "$(lsb_release -cs)" == "xenial" ]]; then
		echo 'deb https://apt.fluxos.network/ '$(lsb_release -cs)' main' | sudo tee /etc/apt/sources.list.d/flux.list > /dev/null 2>&1
		gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B69CA27A986265D > /dev/null 2>&1
		gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1    
		if ! gpg --list-keys Zel > /dev/null; then    
			gpg --keyserver hkp://keys.gnupg.net:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
			gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1   
		fi 
		flux_package && sleep 2    
	else
		sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
		#echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/flux-archive-keyring.gpg] https://apt.fluxos.network/ focal main" | sudo tee /etc/apt/sources.list.d/flux.list  > /dev/null 2>&1
    #echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/flux-archive-keyring.gpg] https://apt.runonflux.io/ focal main" | sudo tee --append /etc/apt/sources.list.d/flux.list  > /dev/null 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/flux-archive-keyring.gpg] https://apt.runonflux.io/ focal main" | sudo tee /etc/apt/sources.list.d/flux.list  > /dev/null 2>&1
		# downloading key && save it as keyring  
		gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
		key_counter=0
		until [ $key_counter -gt 5 ]
		do
			if gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
				break
			fi
			echo -e "${CYAN}Retrieve keys failed will try again...${NC}"
			sleep 5
			sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
			gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
			((key_counter++))
		done
		#if ! gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
			#echo -e "${YELLOW}First attempt to retrieve keys failed will try a different keyserver.${NC}"
			#sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
			#gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://na.pool.sks-keyservers.net:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
		#fi
		#if ! gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
			#echo -e "${YELLOW}Last keyserver also failed will try one last keyserver.${NC}"
			#sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
			#gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://keys.gnupg.net:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
		#fi
		if gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
			flux_package && sleep 2 
		else   
			echo -e ""
			echo -e "${WORNING} ${RED}Importing public GPG Key failed...${NC}"
			echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
			echo -e ""
			exit
		fi
	fi
}
function basic_security() {
	echo -e "${ARROW} ${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
	sudo ufw allow "$SSHPORT"/tcp > /dev/null 2>&1
	sudo ufw logging on > /dev/null 2>&1
	sudo ufw default deny incoming > /dev/null 2>&1
	sudo ufw allow out from any to any port 123  > /dev/null 2>&1
	sudo ufw allow out to any port 80 > /dev/null 2>&1
	sudo ufw allow out to any port 443 > /dev/null 2>&1
	sudo ufw allow out to any port 53 > /dev/null 2>&1
	#FluxOS communication
	sudo ufw allow 16100:16199/tcp > /dev/null 2>&1
	#sudo ufw default deny outgoing > /dev/null 2>&1
	sudo ufw limit OpenSSH > /dev/null 2>&1
	echo "y" | sudo ufw enable > /dev/null 2>&1
	sudo ufw reload > /dev/null 2>&1
	sudo systemctl enable fail2ban > /dev/null 2>&1
	sudo systemctl start fail2ban > /dev/null 2>&1
}
function start_daemon() {
	sudo systemctl enable zelcash.service > /dev/null 2>&1
	sudo systemctl start zelcash > /dev/null 2>&1
	x=1  
	while [ $x -le 6 ]
	do
		NUM='300'
		MSG1='Starting daemon & syncing with chain please be patient this will take about 5 min...'
		MSG2=''
		spinning_timer 
		chain_check=$($COIN_CLI $1 getinfo  2>&1 >/dev/null | grep "Activating" | wc -l)   
		if [[ "$chain_check" == "1" ]]; then
			echo -e ""
			echo -e "${ARROW} ${CYAN}Activating best chain detected....Awaiting increased for next 5min${NC}"
		fi
		if [[ "$($COIN_CLI $1 getinfo 2>/dev/null  | jq -r '.version' 2>/dev/null)" != "" ]]; then
			break
		fi
		if [[ "$x" -gt 6 ]]; then
			echo -e "${ARROW} ${CYAN}Maximum timeout exceeded...${NC}"
			break
		fi
		x=$(( $x + 1 ))   
	done
	if [[ "$($COIN_CLI $1 getinfo 2>/dev/null  | jq -r '.version' 2>/dev/null)" != "" ]]; then  
		NUM='2'
		MSG1='Getting info...'
		MSG2="${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
		spinning_timer
		echo && echo
		daemon_version=$($COIN_CLI $1 getinfo | jq -r '.version')
		string_limit_check_mark "Flux daemon v$daemon_version installed................................." "Flux daemon ${GREEN}v$daemon_version${CYAN} installed................................."
		bench_version=$($BENCH_CLI $1 getinfo | jq -r '.version')
		string_limit_check_mark "Flux benchmark v$bench_version installed................................." "Flux benchmark ${GREEN}v$bench_version${CYAN} installed................................."
		echo
		pm2_install
	else
		echo -e ""
		echo -e "${WORNING} ${RED}Something is not right the daemon did not start or still loading...${NC}"
		if [[ -f /home/$USER/$CONFIG_DIR/debug.log ]]; then
			error_line=$(egrep -a --color 'Error:' /home/$USER/$CONFIG_DIR/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')	  
			if [[ "$error_line" != "" ]]; then	  
				echo -e "${WORNING} ${CYAN}Last error from ~/$CONFIG_DIR/debug.log: ${NC}"
				echo -e "${WORNING} ${CYAN}$error_line${NC}"
				echo -e ""
				exit
			fi  	       
		fi
		if whiptail --yesno "Something is not right the daemon did not start or still loading....\nWould you like continue the installation (make sure that flux daemon working) Y/N?" 8 90; then
			echo -e "${ARROW} ${CYAN}Problem with daemon noticed but user want continue installation...  ${NC}"
			echo -n ""
		else
			echo -e "${WORNING} ${RED}Installation stopped by user...${NC}"
			echo -n ""
			exit
		fi	
	fi
}
function install_process() {
	echo -e "${ARROW} ${YELLOW}Configuring firewall...${NC}"
	sudo ufw allow $ZELFRONTPORT/tcp > /dev/null 2>&1
	sudo ufw allow $LOCPORT/tcp > /dev/null 2>&1
	sudo ufw allow $ZELNODEPORT/tcp > /dev/null 2>&1
	echo -e "${ARROW} ${YELLOW}Configuring service repositories...${NC}"
	sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
	sudo rm /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1 
	# check to see if cpu supports avx
	avx_check=$(cat /proc/cpuinfo | grep -o avx | head -n1)
	# AVX instruction flag not found - so install 4.4
	# else install newest version 6.0
	if [[ "$avx_check" == "" ]]; then
		curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
		if [[ $(lsb_release -d) = *Debian* ]]; then 
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/4.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
		elif [[ $(lsb_release -d) = *Ubuntu* ]]; then 
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
		else
			echo -e "${WORNING} ${RED}OS type $(lsb_release -si) not supported..${NC}"
			echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
			echo
			exit    
		fi
	else
		curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
		if [[ $(lsb_release -d) = *Debian* ]]; then 
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null 2>&1
		elif [[ $(lsb_release -d) = *Ubuntu* ]]; then
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null 2>&1
		else
			echo -e "${WORNING} ${RED}OS type $(lsb_release -si) not supported..${NC}"
			echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
			echo
			exit    
		fi
	fi
	
	if ! sysbench --version > /dev/null 2>&1; then
		echo -e ""
		echo -e "${ARROW} ${YELLOW}Sysbench installing...${NC}"
		curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh 2> /dev/null | sudo bash > /dev/null 2>&1
		sudo apt -y install sysbench > /dev/null 2>&1
	 if sysbench --version > /dev/null 2>&1; then
	   string_limit_check_mark "Sysbench $(sysbench --version | awk '{print $2}') installed................................." "Sysbench ${GREEN}$(sysbench --version | awk '{print $2}')${CYAN} installed................................."   
	 fi
		
	fi
	install_mongod
	install_nodejs
	install_flux
	sleep 2
}
function install_flux() {
	echo -e "${ARROW} ${YELLOW}FluxOS installing...${NC}"
	docker_check=$(docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" | wc -l)
	resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
	mongod_check=$(mongoexport -d localzelapps -c zelappsinformation --jsonArray --pretty --quiet  | jq -r .[].name | head -n1)

	if [[ "$mongod_check" != "" && "$mongod_check" != "null" ]]; then
		#echo -e "${ARROW} ${YELLOW}Detected Flux MongoDB local apps collection ...${NC}" && sleep 1
		echo -e "${ARROW} ${CYAN}Cleaning MongoDB Flux local apps collection...${NC}" && sleep 1
		echo "db.zelappsinformation.drop()" | mongo localzelapps > /dev/null 2>&1
	fi

	if [[ $docker_check != 0 ]]; then
		#echo -e "${ARROW} ${YELLOW}Detected running docker container...${NC}" && sleep 1
		echo -e "${ARROW} ${CYAN}Removing containers...${NC}"
		sudo service docker restart > /dev/null 2>&1 && sleep 2
		docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" |
		while read line; do
			sudo docker stop $line > /dev/null 2>&1 && sleep 2
			sudo docker rm $line > /dev/null 2>&1 && sleep 2
		done
	fi
	if [[ $resource_check != 0 ]]; then
		#echo -e "${ARROW} ${YELLOW}Detected locked resource${NC}" && sleep 1
		echo -e "${ARROW} ${CYAN}Unmounting locked FluxOS resource${NC}" && sleep 1
		df | egrep 'flux' | awk '{ print $1}' |
		while read line; do
			sudo umount -l $line && sleep 1
		done
	fi
	if [ -d "./$FLUX_DIR" ]; then
		echo -e "${ARROW} ${CYAN}Removing any instances of FluxOS${NC}"
		sudo rm -rf $FLUX_DIR
	fi
	
	git clone https://github.com/RunOnFlux/flux.git zelflux > /dev/null 2>&1
	echo -e "${ARROW} ${CYAN}Creating FluxOS configuration file...${NC}"
	fluxos_conf_create
	if [ -d ~/$FLUX_DIR ]; then
		current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
		string_limit_check_mark "FluxOS v$current_ver installed................................." "FluxOS ${GREEN}v$current_ver${CYAN} installed................................."
		echo -e ""
	else
		string_limit_x_mark "FluxOS was not installed................................."
		echo -e ""
	fi
}

#end of functions
start_install
wipe_clean
ssh_port
get_ip "install"
create_swap
install_packages
create_conf
install_daemon
zk_params
if [[ "$BOOTSTRAP_SKIP" == "0" ]]; then
	bootstrap_new "install"
fi
create_service_scripts
create_service "install"
selfhosting "install"
install_process
start_daemon
log_rotate "Flux benchmark" "bench_debug_log" "/home/$USER/$BENCH_DIR_LOG/debug.log" "monthly" "2"
log_rotate "Flux daemon" "daemon_debug_log" "/home/$USER/$CONFIG_DIR/debug.log" "daily" "7"
log_rotate "MongoDB" "mongod_debug_log" "/var/log/mongodb/*.log" "daily" "14"
log_rotate "Docker" "docker_debug_log" "/var/lib/docker/containers/*/*.log" "daily" "7"
basic_security
status_loop
install_watchdog
if [[ "$thunder" == "1" ]]; then
        echo -e ""
	echo -e "${ARROW} ${YELLOW}Thunder Mode configuration...${NC}"
	thunder_mode "install"
fi
if [[ "$gateway_ip" != "" && "$upnp_port" != "" ]] && [[ "$upnp_port" != "null" ]] && [[ "$upnp_enabled" == "true" ]] ; then
	upnp_enable "install"
fi
finalizing
display_banner
