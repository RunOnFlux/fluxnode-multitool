#!/bin/bash
#disable bash history
set +o history
# ensure no `bash: /home/cumulus/config-file-path.extension: cannot overwrite existing file` errors happen
# this error may happen running options 3, 4, 6, 7, 8 and 11
set +o noclobber

if ! [[ -z $1 ]]; then
	if [[ $BRANCH_ALREADY_REFERENCED != '1' ]]; then
	export ROOT_BRANCH="$1"
	export BRANCH_ALREADY_REFERENCED='1'
  if [[ -f "/usr/lib/multitoolbox/multitoolbox.sh" ]]; then
    bash -i "/usr/lib/multitoolbox/multitoolbox.sh"
  else
    bash -i <(curl -s "https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/multitoolbox.sh") $ROOT_BRANCH $2
  fi
	unset ROOT_BRANCH
	unset BRANCH_ALREADY_REFERENCED
	set -o history
	exit
	fi
else
	export ROOT_BRANCH='master'
fi

if [[ -f "/usr/lib/multitoolbox/flux_common.sh" ]]; then
  source "/usr/lib/multitoolbox/flux_common.sh"
else
  source /dev/stdin <<< "$(curl -s "https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/flux_common.sh")"
fi

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
dversion="v8.0"
PM2_INSTALL="0"
zelflux_setting_import="0"
OS_FLAGE="$2"

function config_veryfity(){
  if [[ -f $FLUX_DAEMON_PATH/flux.conf ]]; then
    echo -e "${ARROW} ${YELLOW}Checking config file...${NC}"
    insightexplorer=$(cat $FLUX_DAEMON_PATH/flux.conf | grep 'insightexplorer=1' | wc -l)
    if [[ "$insightexplorer" == "1" ]]; then
      echo -e "${ARROW} ${CYAN}Insightexplorer enabled..............[${CHECK_MARK}${CYAN}]${NC}"
      echo ""
    else
      echo -e "${WORNING} ${CYAN}Insightexplorer disabled.............[${X_MARK}${CYAN}]${NC}"
      echo -e "${WORNING} ${CYAN}Use option 2 for node re-install${NC}"
      echo -e ""
      exit
    fi
  fi
}

function config_file() {
  if [[ -f $DATA_PATH/install_conf.json ]]; then
    import_settings=$(cat $DATA_PATH/install_conf.json | jq -r '.import_settings')
    bootstrap_url=$(cat $DATA_PATH/install_conf.json | jq -r '.bootstrap_url')
    bootstrap_zip_del=$(cat $DATA_PATH/install_conf.json | jq -r '.bootstrap_zip_del')
    use_old_chain=$(cat $DATA_PATH/install_conf.json | jq -r '.use_old_chain')
    prvkey=$(cat $DATA_PATH/install_conf.json | jq -r '.prvkey')
    outpoint=$(cat $DATA_PATH/install_conf.json | jq -r '.outpoint')
    index=$(cat $DATA_PATH/install_conf.json | jq -r '.index')
    zel_id=$(cat $DATA_PATH/install_conf.json | jq -r '.zelid')
    upnp_port=$(cat $DATA_PATH/install_conf.json | jq -r '.upnp_port')
    gateway_ip=$(cat $DATA_PATH/install_conf.json | jq -r '.gateway_ip')
    upnp_enabled=$(cat $DATA_PATH/install_conf.json | jq -r '.upnp_enabled')
    thunder=$(cat $DATA_PATH/install_conf.json | jq -r '.thunder')
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

    if [[ ! -z $gateway_ip && ! -z $upnp_port ]] &&  [[ "$upnp_enabled" == "true" ]] ; then
      echo -e "${PIN}${CYAN}Enable UPnP configuration........................................[${CHECK_MARK}${CYAN}]${NC}" 
    fi
  fi
}
function install_flux() {
  echo -e "${GREEN}Module: Re-install FluxOS${NC}"
  echo -e "${YELLOW}================================================================${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
    if [[ "$USER" == "root" || "$USER" == "ubuntu" ]]; then
      echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
      echo -e "${CYAN}Please switch to the user account.${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
      exit
    fi
  fi  
  if [[ -z $FLUXOS_VERSION ]]; then
    if pm2 -v > /dev/null 2>&1; then
      pm2 del zelflux > /dev/null 2>&1
      pm2 del flux > /dev/null 2>&1
      pm2 save > /dev/null 2>&1
    fi
  else
    echo -e "${ARROW} ${CYAN}Stopping FluxOS....${NC}"
    sudo systemctl stop flux-watchdog > /dev/null 2>&1
    sudo systemctl stop fluxos > /dev/null 2>&1
    sudo systemctl stop syncthing > /dev/null 2>&1
  fi
  fluxos_clean
  if [[ -f $FLUXOS_PATH/config/userconfig.js ]]; then
    echo -e "${ARROW} ${CYAN}Import settings...${NC}"
    ZELID=$(grep -w zelid $FLUXOS_PATH/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
    WANIP=$(grep -w ipaddress $FLUXOS_PATH/config/userconfig.js | sed -e 's/.*ipaddress: .//' | sed -e 's/.\{2\}$//')
    echo -e "${PIN}${CYAN}Flux/SSP ID = ${GREEN}$ZELID${NC}"
    #KDA_A=$(grep -w kadena $FLUXOS_PATH/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
    #if [[ "$KDA_A" != "" ]]; then
      #echo -e "${PIN}${CYAN}Kadena address = ${GREEN}$KDA_A${NC}"
    #fi
    echo -e "${PIN}${CYAN}IP = ${GREEN}$WANIP${NC}"  
    upnp_port=$(grep -w apiport $FLUXOS_PATH/config/userconfig.js | egrep -o '[0-9]+')
    if [[ "$upnp_port" != "" ]]; then
      echo -e "${PIN}${CYAN}API port = ${GREEN}$upnp_port${NC}"
    fi
    router_ip=$(grep -w routerIP $FLUXOS_PATH/config/userconfig.js | sed -e 's/.*routerIP: .//' | sed -e 's/.\{2\}$//')
    if [[ "$router_ip" != "" ]]; then
      echo -e "${PIN}${CYAN}Router IP = ${GREEN}$router_ip${NC}"
    fi
    ImportBlockedPorts
    if [[ "$blockedPortsList" != "" ]]; then
      echo -e "${PIN}${CYAN}BlockedPorts: [$display]${NC}"
    fi
    ImportBlockedRepository
    if [[ "$blockedRepositoryList" != "" ]]; then
      echo -e "${PIN}${CYAN}BlockedRepositories: [$display]${NC}"
    fi
    echo -e ""
    echo -e "${ARROW} ${CYAN}Removing any instances of FluxOS....${NC}"
    sudo rm -rf $FLUXOS_PATH  > /dev/null 2>&1 && sleep 1
    if [[ "$ZELID" != "" && "$WANIP" != "" ]]; then
      zelflux_setting_import="1"
    fi
  fi
  if [ -d $FLUXOS_PATH ]; then
    echo -e "${ARROW} ${CYAN}Removing any instances of FluxOS....${NC}"
    sudo rm -rf $FLUXOS_PATH  > /dev/null 2>&1 && sleep 1
  fi
  if [[ ! -z $FLUXOS_VERSION ]]; then
    cd $DATA_PATH/usr/lib
    FLUXOS_HOME_DIR="fluxos"
  fi
  if [[ -z $FLUXOS_VERSION ]]; then
    FLUXOS_HOME_DIR="zelflux"
  fi
  echo -e "${ARROW} ${CYAN}FluxOS downloading...${NC}"
  if [[ -n $FLUXOS_VERSION ]]; then 
    SUDO_CMD="sudo"
  fi
  $SUDO_CMD git clone https://github.com/RunOnFlux/flux.git $FLUXOS_HOME_DIR > /dev/null 2>&1 && sleep 1
  if [[ -d $FLUXOS_PATH ]]; then
    if [[ -f $FLUXOS_PATH/package.json ]]; then
      current_ver=$(jq -r '.version' $FLUXOS_PATH/package.json)
    else
      string_limit_x_mark "FluxOS was not downloaded, run script again..........................................."
      echo
      exit
    fi
    string_limit_check_mark "FluxOS v$current_ver downloaded..........................................." "FluxOS ${GREEN}v$current_ver${CYAN} downloaded..........................................."
  else
    string_limit_x_mark "FluxOS was not downloaded, run script again..........................................."
    echo
    exit
  fi
  if [[ "$zelflux_setting_import" == "0" ]]; then
    get_ip "install"
    while true
    do
      ZELID="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your Flux/SSP ID from ZelCore (Apps -> Flux ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
      if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ] || [ $(grep -Eo "^0x[a-fA-F0-9]{40}$" <<< "$ZELID") ]; then
        string_limit_check_mark "Flux/SSP ID is valid..........................................."
        break
      else
        string_limit_x_mark "Flux/SSP ID is not valid try again..........................................."
        sleep 2
      fi
    done
    #if [[ -z $FLUXOS_VERSION ]]; then
      #while true
      #do
        #KDA_A=$(whiptail --inputbox "Node tier eligible to receive KDA rewards, what's your KDA address? Nothing else will be required on FluxOS regarding KDA." 8 85 3>&1 1>&2 2>&3)
        #if [[ "$KDA_A" != "" && "$KDA_A" != *kadena* && "$KDA_A" = *k:*  ]]; then    
          #echo -e "${ARROW} ${CYAN}Kadena address is valid.................[${CHECK_MARK}${CYAN}]${NC}"	
          #KDA_A="kadena:$KDA_A?chainid=0"			    
          #sleep 2
          #break
        #else	     
          #echo -e "${ARROW} ${CYAN}Kadena address is not valid.............[${X_MARK}${CYAN}]${NC}"
          #sleep 2		     
        #fi
      #done	 
    #fi
  fi
	fluxos_conf_create
  if [[ -f $FLUXOS_PATH/config/userconfig.js ]]; then	
    if [[ "$upnp_port" != "" ]]; then
      config_builder "apiport" "$upnp_port" "API Port" "fluxos"
    fi
    if [[ "$router_ip" != "" ]]; then
      config_builder "routerIP" "$router_ip" "Router IP" "fluxos"
    fi
    if [[ "$blockedPortsList" != "" ]]; then
      RemoveLine "blockedPorts"
      buildBlockedPortsList "  blockedPorts" "$blockedPortsList" "Blocked ports list created successfully!" "fluxos"
    fi
    if [[ "$blockedRepositoryList" != "" ]]; then
      RemoveLine "blockedRepositories"
      buildBlockedRepositoryList "  blockedRepositories" "$blockedRepositoryList" "Blocked repositories list created successfully!" "fluxos"
    fi
    string_limit_check_mark "FluxOS configuration successfull..........................................."
  else
    string_limit_x_mark "FluxOS installation failed, missing config file..........................................."
    echo
    exit
  fi
  if [[ -z $FLUXOS_VERSION ]]; then
    if pm2 -v > /dev/null 2>&1; then 
      rm restart_zelflux.sh > /dev/null 2>&1
      pm2 del flux > /dev/null 2>&1
      pm2 del zelflux > /dev/null 2>&1
      pm2 save > /dev/null 2>&1
      echo -e "${ARROW} ${CYAN}Starting FluxOS....${NC}"
      echo -e "${ARROW} ${CYAN}FluxOS loading will take 2-3min....${NC}"
      echo -e ""
      pm2 start /home/$USER/$FLUX_DIR/start.sh --max-memory-restart 1500M --restart-delay 30000 --max-restarts 40 --name flux --time  > /dev/null 2>&1
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
  else
    echo -e "${ARROW} ${CYAN}Installing FluxOS dependencies will take 5min....${NC}"
    cd $FLUXOS_PATH
    sudo npm install --omit=dev --cache /dat/usr/lib/npm  > /dev/null 2>&1
    echo -e "${ARROW} ${CYAN}Starting FluxOS....${NC}"
    echo -e "${ARROW} ${CYAN}FluxOS loading will take 2-3min....${NC}"
    echo
    sudo systemctl start syncthing > /dev/null 2>&1
    sudo systemctl start flux-watchdog > /dev/null 2>&1
    sudo systemctl restart fluxbenchd > /dev/null 2>&1
    sudo systemctl start fluxos > /dev/null 2>&1
  fi
}
function create_config() {
  echo -e "${GREEN}Module: Create FluxNode installation config file...${NC}"
  echo -e "${YELLOW}================================================================${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
      echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
      echo -e "${CYAN}Please switch to the user account.${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
      exit
    fi 
  fi
  if jq --version > /dev/null 2>&1; then
  sleep 0.2
  else
    echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
    sudo apt  install jq -y > /dev/null 2>&1
    if jq --version > /dev/null 2>&1; then
      string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
      echo
    else
      string_limit_x_mark "JQ was not installed................................."
      echo
      exit
    fi
  fi

 CHOICE=$(whiptail --title "Create FluxNode installation config" --menu "Make your choice" 15 65 8 \
 "1)" "Manualy - fill questions list"   \
 "2)" "Auto - import exists settings"  3>&2 2>&1 1>&3 )
  case $CHOICE in
  "1)")
    manual_build
  ;;
  "2)")
    config_smart_create
  ;;
  esac
}
function install_watchdog() {
  if [[ -z $FLUXOS_VERSION ]]; then
	  if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		  echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		  echo -e "${CYAN}Please switch to the user account.${NC}"
		  echo -e "${YELLOW}================================================================${NC}"
		  echo -e "${NC}"
	  	exit
	  fi
  fi
	echo -e "${GREEN}Module: Install watchdog for FluxNode${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
    if ! pm2 -v > /dev/null 2>&1; then
      pm2_install
      if [[ "$PM2_INSTALL" == "0" ]]; then
        exit
      fi
      echo -e ""
    fi
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
  else
    sudo systemctl stop flux-watchdog
    cd $FLUX_WATCHDOG_PATH
    cd ..
    sudo rm -rf $FLUX_WATCHDOG_PATH > /dev/null 2>&1
    echo -e "${ARROW} ${CYAN}Downloading...${NC}"
    git clone https://github.com/RunOnFlux/fluxnode-watchdog.git flux-watchdog > /dev/null 2>&1
    echo -e "${ARROW} ${CYAN}Installing git hooks....${NC}"
    wget https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/post-merge > /dev/null 2>&1
    mv post-merge $FLUX_WATCHDOG_PATH/.git/hooks/post-merge
    sudo chmod +x  $FLUX_WATCHDOG_PATH/.git/hooks/post-merge
    echo -e "${ARROW} ${CYAN}Installing watchdog module....${NC}"
    cd flux-watchdog && npm install > /dev/null 2>&1
  fi
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
	fix_action='1'
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
	if [[ -f $FLUX_BENCH_PATH/$CONFIG_FILE ]]; then
		index_from_file=$(grep -w zelnodeindex $FLUX_BENCH_PATH/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
		tx_from_file=$(grep -w zelnodeoutpoint $FLUX_BENCH_PATH/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
		stak_info=$(curl -s -m 5 https://explorer.runonflux.io/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		if [[ "$stak_info" == "" ]]; then
			stak_info=$(curl -s -m 5 https://explorer.runonflux.io/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
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
	echo -e "${ARROW} ${CYAN}Starting watchdog...${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
	  pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
	  pm2 save > /dev/null 2>&1
  else
    sudo systemctl start flux-watchdog  > /dev/null 2>&1
  fi
	if [[ -f $FLUX_WATCHDOG_PATH/watchdog.js ]]; then
		current_ver=$(jq -r '.version' $FLUX_WATCHDOG_PATH/package.json)
		string_limit_check_mark "Watchdog v$current_ver installed..........................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed..........................................."  
	else
		string_limit_x_mark "Watchdog was not installed..........................................."
	fi
	echo -e ""
}
function flux_daemon_bootstrap() {
  echo -e "${GREEN}Module: Restore Flux blockchain from bootstrap${NC}"
	echo -e "${YELLOW}================================================================${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
	  if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
		  echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		  echo -e "${CYAN}Please switch to the user account.${NC}"
	    echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
		  exit
   fi 
	fi
  cd
	echo -e "${NC}"
	#config_veryfity
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
		exit
	fi
	
	if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version $(lsb_release -si) not supported${NC}"
		echo -e "${CYNA}Ubuntu 20.04 LTS is the recommended OS version .. please re-image and retry installation"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		exit
	fi
	
  if [[ "$OS_FLAGE" == "" ]]; then
    os_check
  fi
	
	if sudo docker run hello-world > /dev/null 2>&1; then
		echo -e ""
	else
		echo -e "${WORNING}${CYAN}Docker is not working correct or is not installed.${NC}"
		exit
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
		exit
	fi
	if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
		echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version $(lsb_release -si) not supported${NC}"
		echo -e "${CYNA}Ubuntu 20.04 LTS is the recommended OS version .. please re-image and retry installation"
		echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
		echo
		exit
	fi
	
	if [[ "$OS_FLAGE" == "" ]]; then
          os_check
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
function mongod_db_fix() {
	echo -e "${GREEN}Module: MongoDB Repair Assistant${NC}"
	echo -e "${YELLOW}================================================================${NC}"
  if [[ -z $FLUXOS_VERSION ]]; then
    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		  echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		  echo -e "${CYAN}Please switch to the user account.${NC}"
		  echo -e "${YELLOW}================================================================${NC}"
	  	echo -e "${NC}"
	  	exit
	  fi 
  fi
	if [[ -z $FLUXOS_VERSION ]]; then
    CHOICE=$(
      whiptail --title "MongoDB Repair Assistant" --menu "Make your choice" 15 65 8 \
      "1)" "Soft repair - MongoDB database repair"   \
      "2)" "Hard repair - MongoDB re-install"  3>&2 2>&1 1>&3
    )
	else
    CHOICE=$(
      whiptail --title "MongoDB FiX action" --menu "Make your choice" 15 65 8 \
      "1)" "Soft repair - MongoDB database repair"   \
      "2)" "Hard repair - MongoDB database wipe"  3>&2 2>&1 1>&3
    )
	fi
  case $CHOICE in
		"1)")
      echo -e ""  
      echo -e "${ARROW} ${YELLOW}Soft repair starting... ${NC}" 
      echo -e "${ARROW} ${CYAN}Stopping MongoDB service ${NC}" 
      sudo systemctl stop mongod
      echo -e "${ARROW} ${CYAN}Fixing corrupted DB ${NC}"
      sudo rm $MONGODB_DATA_PATH/journal/* > /dev/null 2>&1
      sudo rm $MONGODB_DATA_PATH/mongod.lock > /dev/null 2>&1
      sudo -u mongodb mongod --dbpath $MONGODB_DATA_PATH --repair > /dev/null 2>&1
      echo -e "${ARROW} ${CYAN}Setting privilege ${NC}" 
      sudo chown -R mongodb:mongodb $MONGODB_DATA_PATH > /dev/null 2>&1
      sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
      echo -e "${ARROW} ${CYAN}Starting MongoDB service ${NC}" 
      sudo systemctl start mongod
      if mongod --version > /dev/null 2>&1; then
        string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
        echo -e "${ARROW} ${CYAN}Service status:${SEA} $(sudo systemctl status mongod | grep -w 'Active' | sed -e 's/^[ \t]*//')${NC}" 
      fi
      echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark...${NC}"
      if [[ -z $FLUXOS_VERSION ]]; then
        sudo systemctl restart zelcash > /dev/null 2>&1
        pm2 restart flux > /dev/null 2>&1
      else
        sudo systemctl restart fluxd > /dev/null 2>&1
        sudo systemctl restart fluxbenchd > /dev/null 2>&1
        sudo systemctl restart fluxos > /dev/null 2>&1
      fi
      sleep 5
      echo -e ""
		;;
		"2)")
			echo -e ""  
			echo -e "${ARROW} ${YELLOW}Hard repair starting... ${NC}" 
			echo -e "${ARROW} ${CYAN}Stopping MongoDB service...${NC}" 
			sudo systemctl stop mongod 
      if [[ -z $FLUXOS_VERSION ]]; then 
        echo -e "${ARROW} ${CYAN}Removing MongoDB... ${NC}" 
        sudo apt-get remove -f mongodb-org* -y > /dev/null 2>&1
        sudo apt-get purge --allow-change-held-packages mongodb-org* -y > /dev/null 2>&1
        sudo apt autoremove -y > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Removing Database... ${NC}"
        sudo rm -r /var/log/mongodb > /dev/null 2>&1
        sudo rm -r /var/lib/mongodb > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Installing MongoDB... ${NC}"
        avx_check=$(cat /proc/cpuinfo | grep -o avx | head -n1)
        os_version=$(lsb_release -rs | tr -d '.')
        architecture=$(dpkg --print-architecture)
        if [[ $(lsb_release -d) = *Debian* ]]; then
          os_name="Debian"
        fi  
        if [[ $(lsb_release -d) = *Ubuntu* ]]; then
          os_name="Ubuntu"
        fi
        #Ubuntu MongoDB 4.4
        if [[ "$avx_check" == ""  && "$os_name" == "Ubuntu"  && "$architecture" == "amd64" && "$os_version" -le "2010" ]] || [[ "$os_name" == "Ubuntu"  && "$architecture" == "arm64" && "$os_version" -le "2010" ]]; then
        install_mongod="4.4"
        fi
        #Debian MongoDB 4.4
        if [[ "$avx_check" == ""  && "$os_name" == "Debian"  && "$architecture" == "amd64" && "$os_version" -le "9" ]] || [[ "$os_name" == "Debian"  && "$architecture" == "arm64" && "$os_version" -le "9" ]]; then
          install_mongod="4.4"
        fi
        if [[ "$install_mongod" == "4.4" ]]; then
          sudo apt update -y > /dev/null 2>&1
          sudo apt install -y mongodb-org=4.4.18 mongodb-org-server=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-mongos=4.4.18 mongodb-org-tools=4.4.18 > /dev/null 2>&1 && sleep 2
          echo "mongodb-org hold" | sudo dpkg --set-selections > /dev/null 2>&1 && sleep 2
          echo "mongodb-org-server hold" | sudo dpkg --set-selections > /dev/null 2>&1 
          echo "mongodb-org-shell hold" | sudo dpkg --set-selections > /dev/null 2>&1 
          echo "mongodb-org-mongos hold" | sudo dpkg --set-selections > /dev/null 2>&1 
          echo "mongodb-org-tools hold" | sudo dpkg --set-selections > /dev/null 2>&1 
        else
          sudo apt update -y > /dev/null 2>&1
          DEBIAN_FRONTEND=noninteractive sudo apt-get --yes install mongodb-org > /dev/null 2>&1 
        fi
        sudo mkdir -p /var/log/mongodb > /dev/null 2>&1
        sudo mkdir -p /var/lib/mongodb > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Settings privilege... ${NC}"
        sudo chown -R mongodb:mongodb /var/log/mongodb > /dev/null 2>&1
        sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
        sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
        fluxos_clean
        #echo -e "${ARROW} ${CYAN}Restoring Database... ${NC}"
        #mongorestore --drop --archive=/home/$USER/mongoDB_backup.gz > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting mongod service... ${NC}"
        sudo systemctl enable mongod
        sudo systemctl start mongod
        if mongod --version > /dev/null 2>&1; then
          string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
          echo -e "${ARROW} ${CYAN}Service status:${SEA} $(sudo systemctl status mongod | grep -w 'Active' | sed -e 's/^[ \t]*//')${NC}" 
        else
          string_limit_x_mark "MongoDB was not installed................................."
        fi
        echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark...${NC}"
        sudo systemctl restart zelcash > /dev/null 2>&1
        pm2 restart flux > /dev/null 2>&1
        sleep 5
        echo -e ""
      else
        echo -e "${ARROW} ${CYAN}Stopping Flux Watchdog service... ${NC}"
        sudo systemctl stop flux-watchdog > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Stopping Fluxd service... ${NC}"
        sudo systemctl stop fluxd > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Stopping Fluxbench service... ${NC}"
        sudo systemctl stop fluxbenchd > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Stopping FluxOS service... ${NC}"
        sudo systemctl stop fluxos > /dev/null 2>&1
        sudo rm -rf /var/lib/mongodb/*
        fluxos_clean
        echo -e "${ARROW} ${CYAN}Starting MongoDB service... ${NC}"
        sudo systemctl start mongod > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting Syncthing service... ${NC}"
        sudo systemctl start syncthing > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting FluxOS service... ${NC}"
        sudo systemctl start fluxos > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting Fluxd service... ${NC}"
        sudo systemctl start fluxd > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting Fluxbench service... ${NC}"
        sudo systemctl start fluxbenchd > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Starting Flux Watchdog service... ${NC}"
        sudo systemctl start flux-watchdog > /dev/null 2>&1
        if mongod --version > /dev/null 2>&1; then
          string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
          echo -e "${ARROW} ${CYAN}Service status:${SEA} $(sudo systemctl status mongod | grep -w 'Active' | sed -e 's/^[ \t]*//')${NC}" 
        else
          string_limit_x_mark "MongoDB was not installed................................."
        fi
        echo -e ""
      fi
		;;
	esac
}
function node_reconfiguration() {
	reset=""
	if [[ -f $DATA_PATH/install_conf.json ]]; then
		import_config_file "silent"
		get_ip
		if [[ -d $FLUXOS_PATH ]]; then	  
			if [[ "$ZELID" != "" ]]; then
				echo -e "${ARROW} ${CYAN}Creating FluxOS config file...${NC}"
				sudo rm -rf $FLUXOS_PATH/config/userconfig.js > /dev/null 2>&1
				fluxos_conf_create
				reset=0
			fi
		fi
		if [[ -d $FLUX_DAEMON_PATH ]]; then
      if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]]; then
				zelnodeprivkey="$prvkey"
				zelnodeoutpoint="$outpoint"
				zelnodeindex="$index"
				echo -e "${ARROW} ${CYAN}Creating Daemon config file...${NC}"
				sudo rm -rf $FLUX_DAEMON_PATH/flux.conf > /dev/null 2>&1
				flux_daemon_conf_create
				reset=0
			fi
		fi
		if [[ -d $FLUX_WATCHDOG_PATH ]]; then
			echo -e "${ARROW} ${CYAN}Creating Watchdog config file...${NC}"
			sudo rm -rf $FLUX_WATCHDOG_PATH/config.js > /dev/null 2>&1
			fix_action='1'
  			watchdog_conf_create
			reset=0
		fi
		if [[ -d $FLUX_DAEMON_PATH ]]; then
			if [[ ! -z "$upnp_port" && ! -z "$gateway_ip" ]]; then
				reset=1
				upnp_enable
			fi
		fi
		if [[ "$reset" == "0" ]]; then
      if [[ -z $FLUXOS_VERSION ]]; then
        echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark...${NC}"
        sudo systemctl restart zelcash > /dev/null 2>&1
        pm2 restart flux > /dev/null 2>&1
      else
        sudo systemctl restart fluxd > /dev/null 2>&1
        sudo systemctl restart fluxbenchd > /dev/null 2>&1
        sudo systemctl restart fluxos > /dev/null 2>&1
        sudo systemctl restart flux-watchdog > /dev/null 2>&1
      fi
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

if ! whiptail -v > /dev/null 2>&1; then
	sudo apt-get install -y whiptail > /dev/null 2>&1
fi

if ! upnpc -h > /dev/null 2>&1 ; then
	sudo apt install -y miniupnpc > /dev/null 2>&1 && sleep 2
fi

if [[ $(cat /etc/bash.bashrc | grep 'multitoolbox' | wc -l) == "0"  && $FLUXOS_VERSION == "" ]]; then
	echo "alias multitoolbox='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox.sh)'" | sudo tee -a /etc/bash.bashrc
	echo "alias multitoolbox_testnet='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox_testnet.sh)'" | sudo tee -a /etc/bash.bashrc
	alias multitoolbox='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox.sh)'
	alias multitoolbox_testnet='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox_testnet.sh)'
	source /etc/bash.bashrc
fi

if [[ -d /usr/lib/multitoolbox ]]; then
  cd /usr/lib/multitoolbox
  commit_hash=$(sudo git rev-parse --short HEAD)
  commit_date=$(sudo git log -1 --date=format:'%Y-%m-%d %H:%M:%S' --format=%cd)
  ROOT_BRANCH=$(sudo git rev-parse --abbrev-ref HEAD)
  cd
fi

if ! wget --version > /dev/null 2>&1 ; then
	sudo apt install -y wget > /dev/null 2>&1 && sleep 2
fi
clear
sleep 1
echo -e "${BLUE}"
figlet -f slant "Multitoolbox"
echo -e "${YELLOW}================================================================${NC}"
if [[ -n $FLUXOS_VERSION ]]; then
  echo -e "${GREEN}Version: $dversion${NC}"
  echo -e "${GREEN}Commit: $commit_hash${NC}"
  echo -e "${GREEN}Data: $commit_date${NC}"
fi
echo -e "${GREEN}Branch: $ROOT_BRANCH${NC}"
if [[ ! -z $FLUXOS_VERSION ]]; then
  echo -e "${GREEN}FluxOS version: $FLUXOS_VERSION${NC}"
else
  echo -e "${GREEN}OS: Ubuntu 20/22/23, Debian 10/11/12 (if hardware requirements are met)${NC}"
fi
echo -e "${YELLOW}================================================================${NC}"
if [[ -z $FLUXOS_VERSION ]]; then
  echo -e "${CYAN}1  - Install Docker${NC}"
  echo -e "${CYAN}2  - Install FluxNode${NC}"
  echo -e "${CYAN}3  - FluxNode analyzer and fixer${NC}"
  echo -e "${CYAN}4  - Install watchdog for FluxNode${NC}"
  echo -e "${CYAN}5  - Restore Flux blockchain from bootstrap${NC}"
  echo -e "${CYAN}6  - Create FluxNode installation config file${NC}"
  echo -e "${CYAN}7  - Re-install FluxOS${NC}"
  echo -e "${CYAN}8  - Flux Daemon Reconfiguration${NC}"
  echo -e "${CYAN}9  - Create Flux daemon service${NC}"
  echo -e "${CYAN}10 - Create Self-hosting cron ip service ${NC}"
  echo -e "${CYAN}11 - FluxOS config management ${NC}"
  echo -e "${CYAN}12 - MongoDB Repair Assistant${NC}"
  echo -e "${CYAN}13 - Multinode configuration with UPNP communication (Needs Router with UPNP support)${NC}"
  echo -e "${CYAN}14 - Node reconfiguration from install config${NC}"
  echo -e "${CYAN}15 - Hardware benchmark${NC}"
  echo -e "${YELLOW}================================================================${NC}"
else
  echo -e "${CYAN}1 - Re-install FluxOS${NC}"
  echo -e "${CYAN}2 - Flux Daemon Reconfiguration${NC}"
  echo -e "${CYAN}3 - FluxOS Config Management${NC}"
  echo -e "${CYAN}4 - Restore Flux blockchain from bootstrap${NC}"
  echo -e "${CYAN}5 - MongoDB Repair Assistant${NC}"
  echo -e "${CYAN}6 - FluxNode Diagnostics${NC}"
  echo -e "${CYAN}7 - Log Viewer${NC}"
  echo -e "${CYAN}8 - Hardware benchmark${NC}"
  echo -e "${YELLOW}================================================================${NC}"
fi
read -rp "Pick an option and hit ENTER: "
case "$REPLY" in
 1)  
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
		  install_docker
    else
      install_flux
    fi
 ;;
 2) 
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
      install_node
    else
      daemon_reconfiguration
    fi
 ;;
 3)     
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
		  analyzer_and_fixer
    else
      fluxos_reconfiguration
    fi
 ;;
	4)  
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
		  install_watchdog 
    else
      flux_daemon_bootstrap 
    fi  
 ;;
	5)  
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
		  flux_daemon_bootstrap  
    else
      mongod_db_fix 
    fi  
 ;; 
	6)
		clear
		sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
		  create_config
    else
      analyzer_and_fixer
    fi
 ;;
	7)
    clear
    sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
      install_flux
    else
      bash -i "/usr/lib/multitoolbox/log_viewer.sh"
    fi
 ;;
 8)
    clear
    sleep 1
    if [[ -z $FLUXOS_VERSION ]]; then
      daemon_reconfiguration
    else
      echo -e "${GREEN}Module: Hardware benchmark${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      bash -i "/usr/lib/multitoolbox/hardwarebench.sh"
    fi
 ;;
 9)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    echo -e "${GREEN}Module: Flux Daemon service creator${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
      echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
      echo -e "${CYAN}Please switch to the user account.${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
      exit
    fi 
    create_service_scripts
    create_service "install"
    echo -e ""
	;;
	10)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    selfhosting_creator
 ;;
	11)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    fluxos_reconfiguration
    echo -e ""
 ;;
	12)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    mongod_db_fix
    echo -e ""
 ;;
	13)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    multinode
    echo -e ""
 ;;
 	14)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    echo -e "${GREEN}Module: Node reconfiguration from install config${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
      echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
      echo -e "${CYAN}Please switch to the user account.${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
      exit
    fi
    node_reconfiguration
    echo -e ""
 ;;
  15)
    if [[ ! -z $FLUXOS_VERSION ]]; then
      exit
    fi
    clear
    sleep 1
    echo -e "${GREEN}Module: Hardware benchmark${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
      echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
      echo -e "${CYAN}Please switch to the user account.${NC}"
      echo -e "${YELLOW}================================================================${NC}"
      echo -e "${NC}"
      exit
    fi
    bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/hardwarebench.sh)
 ;;
esac
# USED FOR CLEANUP AT END OF SCRIPT
unset ROOT_BRANCH
unset BRANCH_ALREADY_REFERENCED
