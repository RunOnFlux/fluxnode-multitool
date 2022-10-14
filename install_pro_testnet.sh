#!/bin/bash

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/flux_common.sh)"

# Bootstrap settings
BOOTSTRAP_ZIP='https://fluxnodeservice.com/daemon_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE='daemon_bootstrap.tar.gz'
BOOTSTRAP_URL_MONGOD='https://fluxnodeservice.com/mongod_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE_MONGOD='mongod_bootstrap.tar.gz'

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

#Zelflux ports
ZELFRONTPORT=16126
LOCPORT=16127
ZELNODEPORT=16128
#MDBPORT=27017
RPCPORT=16124
PORT=16125


function import_date() {

if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE || -f /home/$USER/.zelcash/zelcash.conf ]]; then

    if [[ -z "$import_settings" ]]; then

        if whiptail --yesno "Would you like to import data from Flux config files Y/N?" 8 60; then
	
	    OLD_CONFIG=0
	
	    if [[ -d /home/$USER/.zelcash ]]; then
	     CONFIG_DIR='.zelcash'
	     CONFIG_FILE='zelcash.conf' 
	     OLD_CONFIG=1
	    fi
	    
            IMPORT_ZELCONF="1"
            echo
            echo -e "${ARROW} ${YELLOW}Imported settings:${NC}"
            zelnodeprivkey=$(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeprivkey=//')
            echo -e "${PIN}${CYAN} Private Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
            zelnodeoutpoint=$(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
            echo -e "${PIN}${CYAN} Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
            zelnodeindex=$(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
            echo -e "${PIN}${CYAN} Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1
	    
	    if [[ "$OLD_CONFIG" == "1" ]]; then 
	       CONFIG_DIR='.flux'
	       CONFIG_FILE='flux.conf' 
	    fi

           if [[ -f ~/$FLUX_DIR/config/userconfig.js ]]; then
               
               ZELID=$(grep -w zelid ~/$FLUX_DIR/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
               
	       if [[ "$ZELID" != "" ]]; then
	         echo -e "${PIN}${CYAN} Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
	         IMPORT_ZELID="1"
	       fi

             #  KDA_A=$(grep -w kadena ~/$FLUX_DIR/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
             # if [[ "$KDA_A" != "" ]]; then
                #  echo -e "${PIN}${CYAN} KDA address = ${GREEN}$KDA_A${NC}" && sleep 1
            # fi

         fi
    fi

else 

    if [[ "$import_settings" == "1" ]]; then
    
            OLD_CONFIG=0
	
	    if [[ -d /home/$USER/.zelcash ]]; then
	     CONFIG_DIR='.zelcash'
	     CONFIG_FILE='zelcash.conf' 
	     OLD_CONFIG=1
	    fi 
    
    IMPORT_ZELCONF="1"
    echo
    echo -e "${ARROW} ${YELLOW}Imported settings:${NC}"
    zelnodeprivkey=$(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeprivkey=//')
    echo -e "${PIN}${CYAN} Private Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
    zelnodeoutpoint=$(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
    echo -e "${PIN}${CYAN} Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
    zelnodeindex=$(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
    echo -e "${PIN}${CYAN} Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1
    
     if [[ "$OLD_CONFIG" == "1" ]]; then 
	  CONFIG_DIR='.flux'
	  CONFIG_FILE='flux.conf' 
     fi
    

         if [[ -f ~/$FLUX_DIR/config/userconfig.js ]]; then
	 
          ZELID=$(grep -w zelid ~/$FLUX_DIR/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
	 
	       if [[ "$ZELID" != "" ]]; then
	         echo -e "${PIN}${CYAN} Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
	         IMPORT_ZELID="1"
	       fi
	       
           # KDA_A=$(grep -w kadena ~/$FLUX_DIR/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
              # if [[ "$KDA_A" != "" ]]; then
                #    echo -e "${PIN}${CYAN} KDA address = ${GREEN}$KDA_A${NC}" && sleep 1
              # fi
          fi
      fi

   fi
fi
sleep 1
echo
}


function install_watchdog() {
echo -e "${ARROW} ${YELLOW}Install watchdog for FluxNode${NC}"
if pm2 -v > /dev/null 2>&1
then
WATCHDOG_INSTALL="1"
echo -e "${ARROW} ${YELLOW}Downloading...${NC}"
cd && git clone https://github.com/RunOnFlux/fluxnode-watchdog.git watchdog > /dev/null 2>&1
echo -e "${ARROW} ${YELLOW}Installing git hooks....${NC}"
wget https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/post-merge > /dev/null 2>&1
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
echo -e "${ARROW} ${YELLOW}Installing watchdog module....${NC}"
cd watchdog && npm install > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Creating config file....${NC}"

#if whiptail --yesno "Would you like enable FluxOS auto update?" 8 60; then
flux_update='1'
#sleep 1
#else
#lux_update='0'
#sleep 1
#fi

#if whiptail --yesno "Would you like enable Flux daemon auto update?" 8 60; then
daemon_update='1'
#sleep 1
#else
#daemon_update='0'
#sleep 1
#fi

#if whiptail --yesno "Would you like enable Flux benchmark auto update?" 8 60; then
bench_update='1'
#sleep 1
#else
#bench_update='0'
#sleep 1
#fi

#if whiptail --yesno "Would you like enable fix action (restart daemon, benchmark, mongodb)?" 8 75; then
fix_action='1'
#sleep 1
#else
#fix_action='0'
#sleep 1
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

if [ -z "$CHOICES" ]; then

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

else

    discord=0;
    ping=0;
    telegram_alert=0;
    telegram_bot_token=0;
    telegram_chat_id=0;
    node_label=0;
    sleep 1
fi


if [[ "$discord" == 0 ]]; then
    ping=0;
fi


if [[ "$telegram_alert" == 0 ]]; then
    telegram_bot_token=0;
    telegram_chat_id=0;
fi

if [[ -f /home/$USER/$CONFIG_DIR/testnet/$CONFIG_FILE ]]; then
  index_from_file=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/testnet/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
  tx_from_file=$(grep -w zelnodeoutpoint /home/$USER/$CONFIG_DIR/testnet/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
  stak_info=$(curl -s -m 5 https://testnet.runonflux.io/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '10000|25000|100000')
	
    if [[ "$stak_info" == "" ]]; then
      stak_info=$(curl -s -m 5 https://testnet.runonflux.io/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '10000|25000|100000')
    fi	
fi

if [[ $stak_info == ?(-)+([0-9]) ]]; then

  case $stak_info in
   "10000") eps_limit=90 ;;
   "25000")  eps_limit=180 ;;
   "100000") eps_limit=300 ;;
  esac
 
else
eps_limit=0;
fi


sudo touch /home/$USER/watchdog/config.js
sudo chown $USER:$USER /home/$USER/watchdog/config.js
    cat << EOF >  /home/$USER/watchdog/config.js
module.exports = {
    label: '${node_label}',
    tier_eps_min: '${eps_limit}',
    zelflux_update: '${flux_update}',
    zelcash_update: '${daemon_update}',
    zelbench_update: '${bench_update}',
    action: '${fix_action}',
    ping: '${ping}',
    web_hook_url: '${discord}',
    telegram_alert: '${telegram_alert}',
    telegram_bot_token: '${telegram_bot_token}',
    telegram_chat_id: '${telegram_chat_id}'
}
EOF

echo -e "${ARROW} ${YELLOW}Starting watchdog...${NC}"
pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
pm2 save > /dev/null 2>&1
if [[ -f /home/$USER/watchdog/watchdog.js ]]
then
current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
#echo -e "${ARROW} ${CYAN}Watchdog ${GREEN}v$current_ver${CYAN} installed successful.${NC}"
string_limit_check_mark "Watchdog v$current_ver installed................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed................................."
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed................................."
fi
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed................................."
fi
}

function mongodb_bootstrap(){

    echo -e ""
    echo -e "${ARROW} ${YELLOW}Restore mongodb datatable from bootstrap${NC}"
      
     DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/mongodb_bootstrap.json | jq -r '.block_height')
     if [[ "$DB_HIGHT" == "" ]]; then
         DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/mongodb_bootstrap.json | jq -r '.block_height')
     fi
    
    #BLOCKHIGHT=$(curl -s -m 6 http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
    echo -e "${ARROW} ${CYAN}Bootstrap block height: ${GREEN}$DB_HIGHT${NC}"
    echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_URL_MONGOD${NC}"
    wget --tries=5 $BOOTSTRAP_URL_MONGOD -q --show-progress 
    
    if [[ -f /home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD ]]; then
    
        echo -e "${ARROW} ${CYAN}Unpacking...${NC}"
        tar xvf $BOOTSTRAP_ZIPFILE_MONGOD -C /home/$USER > /dev/null 2>&1 && sleep 1
        echo -e "${ARROW} ${CYAN}Importing mongodb datatable...${NC}"
        mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop > /dev/null 2>&1
        echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
        sudo rm -rf /home/$USER/dump > /dev/null 2>&1 && sleep 1
        sudo rm -rf $BOOTSTRAP_ZIPFILE_MONGOD > /dev/null 2>&1  && sleep 1


        BLOCKHIGHT_AFTER_BOOTSTRAP=$(mongoexport -d zelcashdata -c scannedheight  --jsonArray --pretty --quiet | jq -r .[].generalScannedHeight)
        echo -e ${ARROW} ${CYAN}Node block height after restored: ${GREEN}$BLOCKHIGHT_AFTER_BOOTSTRAP${NC}
		
     else
     
          echo -e "${ARROW} ${RED}MongoDB bootstrap server offline...try again later use option 5${NC}"   
     fi
     
        echo -e ""
    
    #if [[ "$BLOCKHIGHT_AFTER_BOOTSTRAP" -ge  "$DB_HIGHT" ]]; then
      #echo -e "${ARROW} ${CYAN}Mongo bootstrap installed successful.${NC}"
      #echo -e ""
   # else
     # echo -e "${ARROW} ${CYAN}Mongo bootstrap installation failed.${NC}"
     # echo -e ""
   # fi
  
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
    
    # NEW CLEAN_UP
    
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
      
    #FILE OF OLD ZEL NODE
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
    #sudo rm -rf ~/.zelcash/determ_zelnodes ~/.zelcash/sporks ~/$CONFIG_DIR/database ~/.zelcash/blocks ~/.zelcashchainstate  > /dev/null 2>&1 && sleep 1
    #sudo rm -rf ~/.zelcash  > /dev/null 2>&1 && sleep 1
    sudo rm -rf .zelbenchmark  > /dev/null 2>&1 && sleep 1
    sudo rm -rf /home/$USER/stop_zelcash_service.sh > /dev/null 2>&1
    sudo rm -rf /home/$USER/start_zelcash_service.sh > /dev/null 2>&1
    
    if [[ -d /home/$USER/.zelcash  ]]; then
    
      echo -e "${ARROW} ${CYAN}Moving ~/.zelcash to ~/.flux${NC}"  
      #echo -e "${ARROW} ${CYAN}Renaming zelcash.conf to flux.conf${NC}"  
      sudo mv /home/$USER/.zelcash /home/$USER/.flux > /dev/null 2>&1 && sleep 1
      sudo mv /home/$USER/.flux/zelcash.conf /home/$USER/.flux/flux.conf > /dev/null 2>&1 && sleep 1   
        
    fi
   
    
 if [[ -d /home/$USER/$CONFIG_DIR ]]; then
    
    if [[ -z "$use_old_chain" ]]; then
    
    if  ! whiptail --yesno "Would you like to use old chain from Flux daemon config directory?" 8 60; then
    echo -e "${ARROW} ${CYAN}Removing Flux daemon config directory...${NC}"
    sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 2
    sudo rm -rf /home/$USER/$CONFIG_DIR  > /dev/null 2>&1 && sleep 2
    
    else
        BOOTSTRAP_SKIP="1"
	sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
	sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
	sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
	sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/flux.conf && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/database && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/sporks && sleep 1
    fi
    
    else
    
    if [[ "$use_old_chain" == "1" ]]; then
    
      BOOTSTRAP_SKIP="1"
      sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
      sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
      sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
      sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/flux.conf && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/database && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/sporks && sleep 1
    
    else
    
      echo -e "${ARROW} ${CYAN}Removing Flux daemon config directory...${NC}"
      sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 2
      sudo rm -rf /home/$USER/$CONFIG_DIR  > /dev/null 2>&1 && sleep 2
      
    
    fi
    
    fi
fi

    sudo rm -rf /home/$USER/watchdog > /dev/null 2>&1
    sudo rm -rf /home/$USER/stop_daemon_service.sh > /dev/null 2>&1
    sudo rm -rf /home/$USER/start_daemon_service.sh > /dev/null 2>&1
    echo -e ""
  
  echo -e "${ARROW} ${YELLOW}Checking firewall status...${NC}" && sleep 1
 if [[ $(sudo ufw status | grep "Status: active") ]]; then
   # if [[ -z "$firewall_disable" ]]; then    
     # if   whiptail --yesno "Firewall is active and enabled. Do you want disable it during install process?<Yes>(Recommended)" 8 60; then
         sudo ufw disable > /dev/null 2>&1
	 echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
    #  else	 
	# echo -e "${ARROW} ${CYAN}Firewall status: ${GREEN}Enabled${NC}"
    #  fi
    else
    
     # if [[ "$firewall_disable" == "1" ]]; then
  	 #sudo ufw disable > /dev/null 2>&1
	# echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
     # else
      #  echo -e "${ARROW} ${CYAN}Firewall status: ${GREEN}Enabled${NC}"
     # fi
   # fi
    
   # else
        echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
 fi
 
}


function ssh_port() {
    
    if [[ -z "$ssh_port" ]]; then
    
    SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
    if ! whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56; then
        SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
        echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    else
        echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    fi
    
    else   		
	pettern='^[0-9]+$'
	if [[ $ssh_port =~ $pettern ]] ; then
	  SSHPORT="$ssh_port"
	  echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
	else
	 echo -e "${ARROW} ${CYAN}SSH port must be integer................[${X_MARK}${CYAN}]${NC}}"
	 echo
	 toolbox_close
	fi	   
    fi
}

function ip_confirm() {
    echo -e "${ARROW} ${YELLOW}Detecting IP address...${NC}"
    
    WANIP=$(curl --silent -m 15 https://api4.my-ip.io/ip | tr -dc '[:alnum:].')
    
    if [[ "$WANIP" == "" ]]; then
      WANIP=$(curl --silent -m 15 https://checkip.amazonaws.com | tr -dc '[:alnum:].')    
    fi  
      
    if [[ "$WANIP" == "" ]]; then
      WANIP=$(curl --silent -m 15 https://api.ipify.org | tr -dc '[:alnum:].')
    fi
      
        
    if [[ "$WANIP" == "" ]]; then
      	echo -e "${ARROW} ${CYAN}IP address could not be found, installation stopped .........[${X_MARK}${CYAN}]${NC}"
				echo
				toolbox_close
    fi
   string_limit_check_mark "Detected IP: $WANIP ................................." "Detected IP: ${GREEN}$WANIP${CYAN} ................................."
    
}


function create_conf() {

    echo -e "${ARROW} ${YELLOW}Creating Flux daemon config file...${NC}"
    if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
        echo -e "${ARROW} ${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
        mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
    fi
    
    RPCUSER=$(pwgen -1 8 -n)
    PASSWORD=$(pwgen -1 20 -n)

    if [[ "$IMPORT_ZELCONF" == "0" ]]
    then
    zelnodeprivkey=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode Privkey generated by your Zelcore" 8 72 3>&1 1>&2 2>&3)
    zelnodeoutpoint=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode collateral txid" 8 72 3>&1 1>&2 2>&3)
    zelnodeindex=$(whiptail --title "Flux daemon configuration" --inputbox "Enter your FluxNode collateral output index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
    fi


    if [ "x$PASSWORD" = "x" ]; then
        PASSWORD=${WANIP}-$(date +%s)
    fi
    mkdir -p ~/$CONFIG_DIR > /dev/null 2>&1
    touch ~/$CONFIG_DIR/$CONFIG_FILE
    cat << EOF > ~/$CONFIG_DIR/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcallowip=172.18.0.1
rpcport=$RPCPORT
port=$PORT
zelnode=1
zelnodeprivkey=$zelnodeprivkey
zelnodeoutpoint=$zelnodeoutpoint
zelnodeindex=$zelnodeindex
server=1
daemon=1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
insightexplorer=1
experimentalfeatures=1
testnet=1
listen=1
externalip=$WANIP
bind=0.0.0.0
addnode=testnet.runonflux.io
maxconnections=256
EOF
    sleep 2
 
}

function install_daemon() {

   sudo rm /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1
   sudo rm /etc/apt/sources.list.d/flux.list > /dev/null 2>&1
   
   echo -e "${ARROW} ${YELLOW}Configuring daemon repository and importing public GPG Key${NC}" 
   sudo chown -R $USER:$USER /usr/share/keyrings > /dev/null 2>&1
   
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
   # cleaning 
   sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
	 sudo rm /usr/share/keyrings/zelcash-archive-keyring.gpg > /dev/null 2>&1
	 echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/flux-archive-keyring.gpg] https://apt.fluxos.network/ focal main" | sudo tee /etc/apt/sources.list.d/flux.list  > /dev/null 2>&1
   # downloading key && save it as keyring  
   gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
   if ! gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
      echo -e "${YELLOW}First attempt to retrieve keys failed will try a different keyserver.${NC}"
      sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
      gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://na.pool.sks-keyservers.net:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
   fi
   if ! gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
      echo -e "${YELLOW}Last keyserver also failed will try one last keyserver.${NC}"
      sudo rm /usr/share/keyrings/flux-archive-keyring.gpg > /dev/null 2>&1
      gpg --no-default-keyring --keyring /usr/share/keyrings/flux-archive-keyring.gpg --keyserver hkp://keys.gnupg.net:80 --recv-keys 4B69CA27A986265D > /dev/null 2>&1
   fi
   if gpg -k --keyring /usr/share/keyrings/flux-archive-keyring.gpg Zel > /dev/null 2>&1; then
    flux_package && sleep 2
   else
     echo
     echo -e "${WORNING} ${RED}Importing public GPG Key failed...${NC}"
     echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
     echo
     toolbox_close
   fi 
fi
sudo rm -rf  /tmp/*lux* 2>&1 && sleep 2
if [[ $(dpkg --print-architecture) = *amd* ]]; then
  sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Flux-Linux-halving.tar.gz -P /tmp > /dev/null 2>&1
  sudo tar xzvf /tmp/Flux-Linux-halving.tar.gz -C /tmp  > /dev/null 2>&1
  sudo mv /tmp/fluxd /usr/local/bin > /dev/null 2>&1
  sudo mv /tmp/flux-cli /usr/local/bin > /dev/null 2>&1
  sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Fluxbench-Linux-v3.3.0.tar.gz -P /tmp > /dev/null 2>&1
  sudo tar xzvf /tmp/Fluxbench-Linux-v3.3.0.tar.gz -C /tmp > /dev/null 2>&1
  sudo mv /tmp/fluxbenchd /usr/local/bin > /dev/null 2>&1
  sudo mv /tmp/fluxbench-cli /usr/local/bin > /dev/null 2>&1
else
  sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Flux-arm64-halving.tar.gz -P /tmp > /dev/null 2>&1
  sudo tar xzvf /tmp/Flux-arm64-halving.tar.gz -C /tmp  > /dev/null 2>&1
  sudo mv /tmp/fluxd /usr/local/bin > /dev/null 2>&1
  sudo mv /tmp/flux-cli /usr/local/bin > /dev/null 2>&1
  sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Fluxbench-arm-v3.3.0.tar.gz -P /tmp > /dev/null 2>&1
  sudo tar xzvf /tmp/Fluxbench-arm-v3.3.0.tar.gz -C /tmp > /dev/null 2>&1
  sudo mv /tmp/fluxbenchd /usr/local/bin > /dev/null 2>&1
  sudo mv /tmp/fluxbench-cli /usr/local/bin > /dev/null 2>&1
fi

sudo chmod 755 $COIN_PATH/* > /dev/null 2>&1 && sleep 2
}


function bootstrap() {

    BOOTSTRAP_ZIPFILE="${BOOTSTRAP_ZIP##*/}"
    
    echo -e ""
    echo -e "${ARROW} ${YELLOW}Restore daemon chain from bootstrap${NC}"
    if [[ -z "$bootstrap_url" ]]; then

        if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
            echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
            rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/determ_zelnodes
	
        fi


        if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then		   
	
            if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
	
                echo -e "${ARROW} ${YELLOW}Local bootstrap file detected...${NC}"
	        echo -e "${ARROW} ${YELLOW}Checking if zip file is corrupted...${NC}"
                if unzip -t $BOOTSTRAP_ZIPFILE | grep 'No errors' > /dev/null 2>&1
                then
                    echo -e "${ARROW} ${CYAN}Bootstrap zip file is valid.............[${CHECK_MARK}${CYAN}]${NC}"
                else
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
                   rm -rf $BOOTSTRAP_ZIPFILE
               fi
	    
	    else	    
                check_tar "/home/$USER/$BOOTSTRAP_ZIPFILE"
	    fi
	    
	fi


        if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
	
	
            if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
	        echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
            else
                tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
                sleep 2  
	    fi
	
        else


            CHOICE=$(
            whiptail --title "FLUXNODE INSTALLATION" --menu "Choose a method how to get bootstrap file" 10 47 2  \
                "1)" "Download from source build in script" \
                "2)" "Download from own source" 3>&2 2>&1 1>&3
            )


            case $CHOICE in
	    "1)")   
	        
	        DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/daemon_bootstrap.json | jq -r '.block_height')
		if [[ "$DB_HIGHT" == "" ]]; then
		  DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/daemon_bootstrap.json | jq -r '.block_height')
		fi
		
		echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
	 	echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
       		wget --tries 5 -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
	        tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR" 
		sleep 2
        	#unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1


	    ;;
	    "2)")   
  		BOOTSTRAP_ZIP="$(whiptail --title "Flux daemon bootstrap setup" --inputbox "Enter your URL (zip, tar.gz)" 8 72 3>&1 1>&2 2>&3)"
		echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"		
		BOOTSTRAP_ZIPFILE="${BOOTSTRAP_ZIP##*/}"
		wget --tries 5 -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		
	        if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
 		    echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                    unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
		else	       
		    tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
		    sleep 2
		fi
		#echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
		#unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
	    ;;
            esac

        fi

    else

        if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
            echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
            rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/determ_zelnodes
        fi

        if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
	
            if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
	
                echo -e "${ARROW} ${YELLOW}Local bootstrap file detected...${NC}"
	        echo -e "${ARROW} ${YELLOW}Checking if zip file is corrupted...${NC}"
                if unzip -t $BOOTSTRAP_ZIPFILE | grep 'No errors' > /dev/null 2>&1
                then
                    echo -e "${ARROW} ${CYAN}Bootstrap zip file is valid.............[${CHECK_MARK}${CYAN}]${NC}"
                else
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   printf '\e[A\e[K'
                   echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
                   rm -rf $BOOTSTRAP_ZIPFILE
               fi
	    
	    else	    
                check_tar "/home/$USER/$BOOTSTRAP_ZIPFILE"
	    fi
	    
	fi


        if [[ "$bootstrap_url" == "" ]]; then

            if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then

                if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
	            echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                    unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
                else
                    tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
                    sleep 2  
	        fi
		
            else
	    
	        DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/daemon_bootstrap.json | jq -r '.block_height')
		if [[ "$DB_HIGHT" == "" ]]; then
		  DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/daemon_bootstrap.json | jq -r '.block_height')
		fi
		
		echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
                echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
                wget --tries 5 -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR" 
		sleep 2

	    fi
	    
        else
	
            if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
                tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR" 
		sleep 2
            else
                BOOTSTRAP_ZIP="$bootstrap_url"
                echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"           
		BOOTSTRAP_ZIPFILE="${BOOTSTRAP_ZIP##*/}"
		wget --tries 5 -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		
	        if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
 		    echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                    unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
		else	       
		    tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
		    sleep 2
		fi	
		
            fi
        fi
    fi

    if [[ -z "$bootstrap_zip_del" ]]; then
        if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
            rm -rf $BOOTSTRAP_ZIPFILE
        fi
    else

        if [[ "$bootstrap_zip_del" == "1" ]]; then
          rm -rf $BOOTSTRAP_ZIPFILE
        fi
  
    fi
     

}


function basic_security() {
    echo -e "${ARROW} ${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
    sudo ufw allow 16124/tcp > /dev/null 2>&1
    sudo ufw allow "$SSHPORT"/tcp > /dev/null 2>&1
    sudo ufw allow "$PORT"/tcp > /dev/null 2>&1
    sudo ufw logging on > /dev/null 2>&1
    sudo ufw default deny incoming > /dev/null 2>&1
    
    sudo ufw allow out from any to any port 123  > /dev/null 2>&1
    sudo ufw allow out to any port 80 > /dev/null 2>&1
    sudo ufw allow out to any port 443 > /dev/null 2>&1
    sudo ufw allow out to any port 53 > /dev/null 2>&1
    sudo ufw allow out to any port 16124 > /dev/null 2>&1
    sudo ufw allow out to any port 16125 > /dev/null 2>&1
    sudo ufw allow out to any port 26124 > /dev/null 2>&1
    sudo ufw allow out to any port 26125 > /dev/null 2>&1
    sudo ufw allow out to any port 16127 > /dev/null 2>&1
    sudo ufw allow from any to any port 16127 > /dev/null 2>&1
    
    sudo ufw default deny outgoing > /dev/null 2>&1
    sudo ufw limit OpenSSH > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    sudo ufw reload > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
}


function start_daemon() {

    sudo systemctl enable zelcash.service > /dev/null 2>&1
    sudo systemctl start zelcash > /dev/null 2>&1
    
    NUM='250'
    MSG1='Starting daemon & syncing with chain please be patient this will take about 3 min...'
    MSG2=''
    spinning_timer
    
    if [[ "$($COIN_CLI  getinfo 2>/dev/null  | jq -r '.version' 2>/dev/null)" != "" ]]; then
    # if $COIN_DAEMON > /dev/null 2>&1; then
        
        NUM='2'
        MSG1='Getting info...'
        MSG2="${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
        spinning_timer
        echo && echo
	
	
	daemon_version=$($COIN_CLI getinfo | jq -r '.version')
	string_limit_check_mark "Flux daemon v$daemon_version installed................................." "Flux daemon ${GREEN}v$daemon_version${CYAN} installed................................."
	#echo -e "Zelcash version: ${GREEN}v$zelcash_version${CYAN} installed................................."
	bench_version=$($BENCH_CLI -testnet getinfo | jq -r '.version')
	string_limit_check_mark "Flux benchmark v$bench_version installed................................." "Flux benchmark ${GREEN}v$bench_version${CYAN} installed................................."
	#echo -e "${ARROW} ${CYAN}Zelbench version: ${GREEN}v$zelbench_version${CYAN} installed${NC}"
	echo
	pm2_install
	#zelbench-cli stop > /dev/null 2>&1  && sleep 2
    else
        echo
        echo -e "${WORNING} ${RED}Something is not right the daemon did not start or still loading...${NC}"
	
	if [[ -f /home/$USER/$CONFIG_DIR/debug.log ]]; then
	  error_line=$(egrep -a --color 'Error:' /home/$USER/$CONFIG_DIR/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')	  
	     if [[ "$error_line" != "" ]]; then	  
	       echo -e "${WORNING} ${CYAN}Last error from ~/$CONFIG_DIR/debug.log: ${NC}"
	       echo -e "${WORNING} ${CYAN}$error_line${NC}"
	       echo
	       toolbox_close
	     fi  	       
        fi
	
	
	if whiptail --yesno "Something is not right the daemon did not start or still loading....\nWould you like continue the installation (make sure that flux daemon working) Y/N?" 8 90; then
       
          echo -e "${ARROW} ${CYAN}Problem with daemon noticed but user want continue installation...  ${NC}"
	  echo -n ""

	else
	
	  echo -e "${WORNING} ${RED}Installation stopped by user...${NC}"
	  echo -n ""
	  toolbox_close

	fi

		
    fi
}

#TODO: RESEARCH, This defaults to mongodb 5.0 in install_pro, why not here?
function install_process() {
 
    echo -e "${ARROW} ${YELLOW}Configuring firewall...${NC}"
    sudo ufw allow $ZELFRONTPORT/tcp > /dev/null 2>&1
    sudo ufw allow $LOCPORT/tcp > /dev/null 2>&1
    sudo ufw allow $ZELNODEPORT/tcp > /dev/null 2>&1
    #sudo ufw allow $MDBPORT/tcp > /dev/null 2>&1

    echo -e "${ARROW} ${YELLOW}Configuring service repositories...${NC}"
    
    sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
    sudo rm /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1 
    
    curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1

    if [[ $(lsb_release -d) = *Debian* ]]; then 

        
        if [[ $(lsb_release -cs) = *stretch* || $(lsb_release -cs) = *buster* ]]; then
           echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] http://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/4.4 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1        
        else
	   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1	
        fi


    elif [[ $(lsb_release -d) = *Ubuntu* ]]; then 


        if [[ $(lsb_release -cs) = *focal* || $(lsb_release -cs) = *bionic* || $(lsb_release -cs) = *xenial* ]]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] http://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1       
        else
	    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1  
        fi

    else

      echo -e "${WORNING} ${RED}OS type not supported..${NC}"
      echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
      echo
      toolbox_close    

    fi
    
    
    if ! sysbench --version > /dev/null 2>&1; then
     
        echo
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
   
 docker_check=$(docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" | wc -l)
 resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
 mongod_check=$(mongoexport -d localzelapps -c zelappsinformation --jsonArray --pretty --quiet  | jq -r .[].name | head -n1)

if [[ "$mongod_check" != "" && "$mongod_check" != "null" ]]; then

echo -e "${ARROW} ${YELLOW}Detected Flux MongoDB local apps collection ...${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Cleaning MongoDB Flux local apps collection...${NC}" && sleep 1
echo "db.zelappsinformation.drop()" | mongo localzelapps > /dev/null 2>&1

fi

if [[ $docker_check != 0 ]]; then
echo -e "${ARROW} ${YELLOW}Detected running docker container...${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Removing containers...${NC}"

sudo service docker restart > /dev/null 2>&1 && sleep 5

docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" |
while read line; do
sudo docker stop $line > /dev/null 2>&1 && sleep 2
sudo docker rm $line > /dev/null 2>&1 && sleep 2
done
fi

if [[ $resource_check != 0 ]]; then
echo -e "${ARROW} ${YELLOW}Detected locked resource${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Unmounting locked Flux resource${NC}" && sleep 1
df | egrep 'flux' | awk '{ print $1}' |
while read line; do
sudo umount -l $line && sleep 1
done
fi
   
    if [ -d "./$FLUX_DIR" ]; then
         echo -e "${ARROW} ${YELLOW}Removing any instances of Flux${NC}"
         sudo rm -rf $FLUX_DIR
    fi


    echo -e "${ARROW} ${YELLOW}Flux installing...${NC}"
    git clone https://github.com/RunOnFlux/flux.git zelflux > /dev/null 2>&1
    cd 
    echo -e "${ARROW} ${YELLOW}Creating Flux configuration file...${NC}"
    
    
if [[ "$IMPORT_ZELID" == "0" ]]; then

        while true
        do
                ZELID=$(whiptail --title "Flux Configuration" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)
                if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ]; then
                echo -e "${ARROW} ${CYAN}Zel ID is valid${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
                break
                else
                echo -e "${ARROW} ${CYAN}Zel ID is not valid try again...........[${X_MARK}${CYAN}]${NC}"
                sleep 4
                fi
        done
		
 fi
  


    touch ~/$FLUX_DIR/config/userconfig.js
    cat << EOF > ~/$FLUX_DIR/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
        zelid: '${ZELID}',
        testnet: true
      }
    }
EOF


if [ -d ~/$FLUX_DIR ]
then
current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)

string_limit_check_mark "Flux v$current_ver installed................................." "Flux ${GREEN}v$current_ver${CYAN} installed................................."
#echo -e "${ARROW} ${CYAN}Zelflux version: ${GREEN}v$current_ver${CYAN} installed${NC}"

echo
else
string_limit_x_mark "Flux was not installed................................."
#echo -e "${ARROW} ${CYAN}Zelflux was not installed${NC}"
echo
fi

}


function status_loop() {

network_height_01=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks')
network_height_03=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks')

EXPLORER_BLOCK_HIGHT=$(max "$network_height_01" "$network_height_03")


if [[ "$EXPLORER_BLOCK_HIGHT" == $(${COIN_CLI} getinfo | jq '.blocks') ]]; then
echo
echo -e "${CLOCK}${GREEN} FLUX DAEMON SYNCING...${NC}"


LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))

NUM='2'
MSG1="Syncing progress >> Local block height: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block height: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN}"
MSG2="${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo && echo

else
	
   echo
   echo -e "${CLOCK}${GREEN}FLUX DAEMON SYNCING...${NC}"
   
   f=0
   start_sync=`date +%s`

	
    while true
    do
        
        network_height_01=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks' 2> /dev/null)
        network_height_03=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks' 2> /dev/null)

        EXPLORER_BLOCK_HIGHT=$(max "$network_height_01" "$network_height_03")
	
        LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
	CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
	LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))
	
	if [[ "$LEFT" == "0" ]]; then	
	  time_break='5'
	else
	  time_break='20'
	fi
	
	#if [[ "$CONNECTIONS" == "0" ]]; then
	 # c=$((c+1))
	 # if [[ "$c" > 3 ]]; then
	  # c=0;
	   #LOCAL_BLOCK_HIGHT=""
	#  fi
	
	#fi
	#
	if [[ $LOCAL_BLOCK_HIGHT == "" ]]; then
	
	  f=$((f+1))
	  LOCAL_BLOCK_HIGHT="N/A"
	  LEFT="N/A"
	  CONNECTIONS="N/A"
	  sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
	  sudo systemctl start zelcash > /dev/null 2>&1
	
          NUM='60'
          MSG1="Syncing progress => Local block height: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block height: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN} Failed: ${RED}$f${NC}"
          MSG2=''
          spinning_timer
	  
	 network_height_01=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks' 2> /dev/null)
         network_height_03=$(curl -sk -m 5 https://testnet.runonflux.io/api/status?q=getInfo | jq '.info.blocks' 2> /dev/null)

          EXPLORER_BLOCK_HIGHT=$(max "$network_height_01" "$network_height_03")
	  
       	  LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
	  CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
	  LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))

	fi
	
	NUM="$time_break"
        MSG1="Syncing progress >> Local block height: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block height: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN} Failed: ${RED}$f${NC}"
        MSG2=''
        spinning_timer
	
        if [[ "$EXPLORER_BLOCK_HIGHT" == "$LOCAL_BLOCK_HIGHT" ]]; then	
	    echo -e "${GREEN} Duration: $((($(date +%s)-$start_sync)/60)) min. $((($(date +%s)-$start_sync) % 60)) sec. ${CYAN}.............[${CHECK_MARK}${CYAN}]${NC}"
            break
        fi
    done
    
    fi
    
       
   #pm2 start ~/$FLUX_DIR/start.sh --name flux --time > /dev/null 2>&1

    
 # if [[ -z "$mongo_bootstrap" ]]; then
    
   # if   whiptail --yesno "Would you like to restore Mongodb datatable from bootstrap?" 8 60; then
   #      mongodb_bootstrap
   # else
  #      echo -e "${ARROW} ${YELLOW}Restore Mongodb datatable skipped...${NC}"
   # fi
 #   
 # else
   
  #  if [[ "$mongo_bootstrap" == "1" ]]; then
 #     mongodb_bootstrap
  #  else
  #    echo -e "${ARROW} ${YELLOW}Restore Mongodb datatable skipped...${NC}"
   # fi
   
 # fi
    
    
  #if [[ -z "$watchdog" ]]; then
    #if   whiptail --yesno "Would you like to install watchdog for FluxNode?" 8 60; then
   #install_watchdog
   # else
       # echo -e "${ARROW} ${YELLOW}Watchdog installation skipped...${NC}"
   # fi
 #  else
   
    # if [[ "$watchdog" == "1" ]]; then
    #  install_watchdog
    # else
   #   echo -e "${ARROW} ${YELLOW}Watchdog installation skipped...${NC}"
    # fi
   
 #  fi

    check
    display_banner "-testnet"
}


#end of functions
    start_install
    wipe_clean
    ssh_port
    ip_confirm
    create_swap
    install_packages
    create_conf
    install_daemon
    zk_params
    #if [[ "$BOOTSTRAP_SKIP" == "0" ]]; then
   # bootstrap
   # fi
    create_service_scripts
    create_service "install"
    
 #   if whiptail --yesno "Is the fluxnode being installed on a vps?" 8 60; then   
     # echo -e "${ARROW} ${YELLOW}Cron service for rotate ip skipped...${NC}"
  #  else
      # if whiptail --yesno "Would you like to install cron service for rotate ip (required for dynamic ip)?" 8 60; then
         selfhosting
     #  else
       #  echo -e "${ARROW} ${YELLOW}Cron service for rotate ip skipped...${NC}"
      # fi 
   # fi
    
    install_process
    start_daemon
    log_rotate "Flux benchmark" "bench_debug_log" "/home/$USER/$BENCH_DIR_LOG/debug.log" "monthly" "2"
    log_rotate "Flux daemon" "daemon_debug_log" "/home/$USER/$CONFIG_DIR/debug.log" "daily" "7"
    log_rotate "MongoDB" "mongod_debug_log" "/var/log/mongodb/*.log" "daily" "14"
    log_rotate "Docker" "docker_debug_log" "/var/lib/docker/containers/*/*.log" "daily" "7"
    basic_security
    status_loop
