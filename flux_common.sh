#!/bin/bash
#disable bash history
set +o history
#trap EXIT call and unset vars and enable history if history if off
trap toolbox_close EXIT
function toolbox_close(){
	unset ROOT_BRANCH
	unset BRANCH_ALREADY_REFERENCE
	 if [[ $(set -o | grep history) == *"off"* ]]; then
    set -o history
  fi
}
trap ctrl_c INT
# exit on ctl_c and call toolbox close from EXIT trap
function ctrl_c() {
	exit
}
# Collection of common vars and functions used throughout multitoolbox.
#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
CLOCK="${GREEN}\xE2\x8C\x9B${NC}"
ARROW="${SEA}\xE2\x96\xB6${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
HOT="${ORANGE}\xF0\x9F\x94\xA5${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
RIGHT_ANGLE="${GREEN}\xE2\x88\x9F${NC}"
#bootstrap variable
server_offline="0"
failed_counter="0"
#Explorers
network_url_1="explorer.zelcash.online"
network_url_2="explorer.runonflux.io"
network_url_3="blockbook.zel.network"
#Wallet variable
COIN_NAME='flux'
CONFIG_DIR='.flux'
CONFIG_FILE='flux.conf'
#FluxOS variable
FLUX_DIR='zelflux'
#Ports
RPCPORT=16124
PORT=16125
#dialog color
export NEWT_COLORS='
title=black,
'
##### CONFIGS SECTION ######################################
function watchdog_conf_create(){
	sudo touch /home/$USER/watchdog/config.js
	sudo chown $USER:$USER /home/$USER/watchdog/config.js
	cat <<- EOF >|  /home/$USER/watchdog/config.js
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
}

function fluxos_conf_create(){
  if [[ "$1" == "true" ]]; then
		testnet=true
	else
		testnet=false
	fi
	touch /home/$USER/$FLUX_DIR/config/userconfig.js
	cat <<- EOF >| /home/$USER/$FLUX_DIR/config/userconfig.js
module.exports = {
  initial: {
    ipaddress: '${WANIP}',
    zelid: '${ZELID}',
    kadena: '${KDA_A}',
    development: false,
    blockedPorts: [],
    testnet: $testnet,
  }
}
EOF
}

function flux_daemon_conf_create() {
  explorers=(
      "explorer.runonflux.io"
      "explorer.zelcash.online"
      "blockbook.runonflux.io"
      "explorer.flux.zelcore.io"
  )
  selected_ips=($(curl -s -m 20 https://api.runonflux.io/apps/enterprisenodes | jq -r '.data[] | select(.score >= 2200 and .score <= 3000) | .ip' 2>/dev/null | shuf -n 25))
  nodes=("${selected_ips[@]}" "${explorers[@]}")
  RPCUSER=$(pwgen -1 8 -n)
  PASSWORD=$(pwgen -1 20 -n)
  touch /home/$USER/$CONFIG_DIR/$CONFIG_FILE
  {
    cat <<- EOF
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
    listen=1
    externalip=$WANIP
    bind=0.0.0.0
    maxconnections=256
    # Addnode list
EOF
    IFS=$'\n'
    for node in "${nodes[@]}"; do
      echo "addnode=$node"
    done
  } | sed 's/^[[:space:]]*//' >| /home/$USER/$CONFIG_DIR/$CONFIG_FILE
}

function install_conf_create(){
	sudo touch /home/$USER/install_conf.json
	sudo chown $USER:$USER /home/$USER/install_conf.json
	cat <<- EOF >| /home/$USER/install_conf.json
	{
	  "import_settings": "${import_settings}",
	  "prvkey": "${prvkey}",
	  "outpoint": "${outpoint}",
	  "index": "${index}",
	  "zelid": "${zel_id}",
	  "kda_address": "${kda_address}",
	  "firewall_disable": "${firewall_disable}",
	  "bootstrap_url": "${bootstrap_url}",
	  "bootstrap_zip_del": "${bootstrap_zip_del}",
	  "swapon": "${swapon}",
	  "use_old_chain": "${use_old_chain}",
	  "node_label": "${node_label}",
	  "zelflux_update": "${zelflux_update}",
	  "zelcash_update": "${zelcash_update}",
	  "zelbench_update": "${zelbench_update}",
	  "discord": "${discord}",
	  "ping": "${ping}",
	  "telegram_alert": "${telegram_alert}",
	  "telegram_bot_token": "${telegram_bot_token}",
	  "telegram_chat_id": "${telegram_chat_id}",
	  "eps_limit": "${eps_limit}",
	  "upnp_port": "${upnp_port}",
	  "gateway_ip": "${gateway_ip}",
    "upnp_enabled": "${upnp_enabled}",
	  "thunder": "${thunder:-0}"
	}
	EOF
}

###### SMART CONFIG
function padding() {
msg="$1"
padding=".................................................................................................................."
echo -e "$(printf "%s%s %s\n" "$msg" "${CYAN}${padding:${#msg}}" "${CYAN}[$2${CYAN}]${NC}")"
}

function insert() {
  local file="$1" line="$2" newText="$3"
  sudo sed -i -e "/$line/i"$'\\\n'"$newText"$'\n' "$file"
}

function RemoveLine(){
  sed -i "/$1/d" /home/$USER/zelflux/config/userconfig.js
}

function ClearList() {
  string="\[\]"
  display=""
}

function buildBlockedPortsList() {
  if [[ ! -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
   padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Config file does not exist...${NC}" "${X_MARK}"
   exit
  fi
  if [[ "$1" == ""  || "$2" == "" ]]; then
   padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
   exit
  fi
  key="$1"
  value="$2"
  if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "$key") == "" ]]; then
      insert "/home/$USER/$FLUX_DIR/config/userconfig.js" "testnet" "  $key: $value,"
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}$3${NC}" "${CHECK_MARK}"
      return
  fi
}

function CreateBlockedPortsList() {
  ADD=$(whiptail --inputbox "Enter the ports to the blocked list, separated by commas" 8 85 3>&1 1>&2 2>&3)
  if [[ $? == 1 ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}The operation was canceled${NC}" "${X_MARK}"
     echo -e ""
     exit
  fi
  NumberCheck=$(sed 's/,/1/g' <<< $ADD)
  ADD=$(sed 's/,/ /g' <<< $ADD)
  if ! [[ "$NumberCheck" =~ ^[0-9]+$ ]]; then
    padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Input contains non numerical value${NC}" "${X_MARK}"
    exit
  fi
  array=($ADD)
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  if [[ "${joined%,}" != "" ]]; then
    string="\[${joined%,}\]"
    display="${joined%,}"
  fi
}

function AddBlockedPorts() {
  string=$(grep "blockedPorts" $HOME/$FLUX_DIR/config/userconfig.js |  awk -F'[][]' '{print $2}' )
  delimiter=","
  declare -a array=($(echo $string | tr "$delimiter" " "))
  ADD=$(whiptail --inputbox "Enter the ports to the blocked list, separated by commas" 8 85 3>&1 1>&2 2>&3)
  if [[ $? == 1 ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}The operation was canceled${NC}" "${X_MARK}"
     echo -e ""
     exit
  fi
  NumberCheck=$(sed 's/,/1/g' <<< $ADD)
  ADD=$(sed 's/,/ /g' <<< $ADD)
  if ! [[ "$NumberCheck" =~ ^[0-9]+$ ]]; then
    padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Input contains non numerical value${NC}" "${X_MARK}"
    exit
  fi
  array+=($ADD)
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  string="\[${joined%,}\]"
  display="${joined%,}"

}

function ImportBlockedPorts(){
  array=($(grep -w blockedPorts /home/$USER/$FLUX_DIR/config/userconfig.js | grep -o '[[:digit:]]*'))
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  if [[ "${joined%,}" != "" ]]; then
    blockedPortsList="\[${joined%,}\]"
    display="${joined%,}"
  fi
}

function blocked_ports(){
  CHOICE=$(
    whiptail --title "FluxOS Blocked Ports Management" --menu "Make your choice" 15 40 6 \
     "1)" "Create new list"   \
     "2)" "Add ports" \
     "3)" "Clear list" 3>&2 2>&1 1>&3 )
     
  case $CHOICE in
  "1)")
    CreateBlockedPortsList
    echo -e "${ARROW}${GREEN} BlockedPorts: [$display]${NC}"
    RemoveLine "blockedPorts"
    buildBlockedPortsList "  blockedPorts" "$string" "Blocked ports list crated successful!" "fluxos"
  ;;
  "2)")
    AddBlockedPorts
    echo -e "${ARROW}${GREEN} BlockedPorts: [$display]${NC}"
    RemoveLine "blockedPorts"
    buildBlockedPortsList "  blockedPorts" "$string" "Blocked ports list updated successful!" "fluxos"
  ;;
  "3)")
    ClearList
    RemoveLine "blockedPorts"
    buildBlockedPortsList "  blockedPorts" "$string" "Blocked ports list cleared successful!" "fluxos"
  ;;
  esac
}

function CreateBlockedRepositoryList() {
  ADD=$(whiptail --inputbox "Enter the repositories to the blocked list, separated by commas" 8 85 3>&1 1>&2 2>&3)
  if [[ $? == 1 ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}The operation was canceled${NC}" "${X_MARK}"
     echo -e ""
     exit
  fi
  ADD=$(sed 's/,/ /g' <<< $ADD)
  temp_array=($ADD)
  for i in ${temp_array[@]}
  do
    array+=("'$i'")
  done
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  if [[ "${joined%,}" != "" ]]; then
    string="\[${joined%,}\]"
    display="${joined%,}"
  fi
}

function AddBlockedRepository() {
  string=$(grep "blockedRepositories" $HOME/$FLUX_DIR/config/userconfig.js |  awk -F'[][]' '{print $2}' )
  delimiter=","
  declare -a array=($(echo $string | tr "$delimiter" " "))
  ADD=$(whiptail --inputbox "Enter the repositories to the blocked list, separated by commas" 8 85 3>&1 1>&2 2>&3)
  if [[ $? == 1 ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}The operation was canceled${NC}" "${X_MARK}"
     echo -e ""
     exit
  fi
  ADD=$(sed 's/,/ /g' <<< $ADD)
  temp_array=($ADD)
  for i in ${temp_array[@]}
  do
    array+=("'$i'")
  done
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  string="\[${joined%,}\]"
  display="${joined%,}"
}

function buildBlockedRepositoryList() {
  if [[ ! -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
   padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Config file does not exist...${NC}" "${X_MARK}"
   exit
  fi
  if [[ "$1" == ""  || "$2" == "" ]]; then
   padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
   exit
  fi
  key="$1"
  value="$2"
  if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "$key") == "" ]]; then
      insert "/home/$USER/$FLUX_DIR/config/userconfig.js" "testnet" "  $key: $value,"
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}$3${NC}" "${CHECK_MARK}"
      return
  fi
}

function ImportBlockedRepository() {
  string=$(grep "blockedRepositories" $HOME/$FLUX_DIR/config/userconfig.js |  awk -F'[][]' '{print $2}' )
  delimiter=","
  declare -a array=($(echo $string | tr "$delimiter" " "))
  sorted_unique_ids=($(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  printf -v joined '%s,' "${sorted_unique_ids[@]}"
  if [[ "${joined%,}" != "" ]]; then
    blockedRepositoryList="\[${joined%,}\]"
    display="${joined%,}"
  fi
}

function blocked_repositories(){
  CHOICE=$(
    whiptail --title "FluxOS Blocked Repositories Management" --menu "Make your choice" 15 40 6 \
     "1)" "Create new list"   \
     "2)" "Add Repositories" \
     "3)" "Clear list" 3>&2 2>&1 1>&3 )

  case $CHOICE in
  "1)")
    CreateBlockedRepositoryList
    echo -e "${ARROW}${GREEN} BlockedRepositories: [$display]${NC}"
    RemoveLine "blockedRepositories"
    buildBlockedRepositoryList "  blockedRepositories" "$string" "Blocked repositories list crated successful!" "fluxos"
  ;;
  "2)")
    AddBlockedRepository
    echo -e "${ARROW}${GREEN} BlockedRepositories: [$display]${NC}"
    RemoveLine "blockedRepositories"
    buildBlockedRepositoryList "  blockedRepositories" "$string" "Blocked repositories list updated successful!" "fluxos"
  ;;
  "3)")
    ClearList
    RemoveLine "blockedRepositories"
    buildBlockedRepositoryList "  blockedRepositories" "$string" "Blocked repositories list cleared successful!" "fluxos"
  ;;
  esac
}

function fluxosConfigBackup(){
  ConfigFile="/home/$USER/$FLUX_DIR/config/userconfig.js"
  if [[ -f $ConfigFile ]]; then
    cp -nf $ConfigFile $HOME/userconfig.js.backup
    if [[ -f $HOME/userconfig.js.backup ]]; then
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js backup successfully${NC}" "${CHECK_MARK}"
    else
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js backup failed${NC}" "${X_MARK}"
    fi
  else
    padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js file not exists${NC}" "${X_MARK}"
  fi
}

function fluxosConfigRestore(){
  ConfigFile="/home/$USER/$FLUX_DIR/config/userconfig.js"
  if [[ -d /home/$USER/$FLUX_DIR ]]; then
    if [[ -f $HOME/userconfig.js.backup ]]; then 
      cp -nf $HOME/userconfig.js.backup $ConfigFile
      if [[ -f $ConfigFile ]]; then
        padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js restored successfully${NC}" "${CHECK_MARK}"
      else
        padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js restored failed${NC}" "${X_MARK}"
      fi
    else
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs userconfig.js backup not exists${NC}" "${X_MARK}"
    fi
  else
    padding "${ARROW}${GREEN} [FluxOS] ${CYAN}FluxOs not installed${NC}" "${X_MARK}"
  fi
}

function config_builder() {
  ########################################################
  if [[ "$4" == "fluxos" ]]; then
    key="$1"
    value_check=$2
    if [[ "$2" == "false" || "$2" == "true" || "$2" =~ ^[0-9]+$ ]]; then 
     value=$2
    else
     value="\'$2\'"
    fi
    if [[ "$1" == "kadena" ]]; then
     if [[ $( grep "chainid" <<< "$2") == "" ]]; then
       value="\'kadena:$2?chainid=0\'"
     fi
    fi
    if [[ ! -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Config file does not exist...${NC}" "${X_MARK}"
     return
    fi
    if [[ "$1" == ""  || "$2" == "" ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
     return
    fi
    if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "$key") == "" ]]; then
        insert "/home/$USER/$FLUX_DIR/config/userconfig.js" "testnet" "    $key: $value,"
        padding "${ARROW}${GREEN} [FluxOS] ${CYAN}$3 added successfully${NC}" "${CHECK_MARK}"
        return
    fi
    if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "$key" | grep "$value_check") != "" ]]; then
     padding "${ARROW}${GREEN} [FluxOS] ${CYAN}$3 skipped${NC}" "${X_MARK}"
     return
    fi
    if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "$key") != "" ]]; then
      RemoveLine "$key"
      insert "/home/$USER/$FLUX_DIR/config/userconfig.js" "testnet" "    $key: $value,"
      padding "${ARROW}${GREEN} [FluxOS] ${CYAN}$3 changed successfully${NC}" "${CHECK_MARK}"
    fi
  fi
  #####################################################
  if [[ "$4" == "daemon" ]]; then
    if [[ ! -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
       padding "${ARROW}${GREEN} [Daemon] ${CYAN}Config file does not exist...${NC}" "${X_MARK}"
       return
    fi
    if [[ "$1" == ""  || "$2" == "" ]]; then
       padding "${ARROW}${GREEN} [Daemon] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
       return
    fi
    if [[ ! $(grep -w $1 /home/$USER/$CONFIG_DIR/$CONFIG_FILE) && -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
      echo "$1=$2" >> /home/$USER/$CONFIG_DIR/$CONFIG_FILE
      if [[ "$1=$2" == $(grep -w $1 /home/$USER/$CONFIG_DIR/$CONFIG_FILE) ]]; then
         padding "${ARROW}${GREEN} [Daemon] ${CYAN}$3 added successfully${NC}" "${CHECK_MARK}"
	 return
      fi
    fi
    if [[ "$1=$2" == $(grep -w $1 /home/$USER/$CONFIG_DIR/$CONFIG_FILE) ]]; then
        padding "${ARROW}${GREEN} [Daemon] ${CYAN}$3 skipped${NC}" "${X_MARK}"
	return
    else
       sed -i "s/$(grep -e $1 /home/$USER/$CONFIG_DIR/$CONFIG_FILE)/$1=$2/" /home/$USER/$CONFIG_DIR/$CONFIG_FILE
       if [[ "$1=$2" == $(grep -w $1 /home/$USER/$CONFIG_DIR/$CONFIG_FILE) ]]; then
         padding "${ARROW}${GREEN} [Daemon] ${CYAN}$3 replaced successfully${NC}" "${CHECK_MARK}"
       fi
    fi
  fi
  ###################################################
  if [[ "$4" == "benchmark" ]]; then
    if [[ "$1" == ""  || "$2" == "" ]]; then
       padding "${ARROW}${GREEN} [BenchD] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
       return
    fi
    if [[ ! -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
      mkdir -p /home/$USER/.fluxbenchmark > /dev/null 2>&1
      echo "$1=$2" >> /home/$USER/.fluxbenchmark/fluxbench.conf
      if [[ "$1=$2" == $(grep -w $1 /home/$USER/.fluxbenchmark/fluxbench.conf) ]]; then
         padding "${ARROW}${GREEN} [BenchD] ${CYAN}$3 added successfully${NC}" "${CHECK_MARK}"
	 return
      fi
    fi
    if [[ ! $(grep -w $1 /home/$USER/.fluxbenchmark/fluxbench.conf) ]]; then
      echo "$1=$2" >> /home/$USER/.fluxbenchmark/fluxbench.conf
      if [[ "$1=$2" == $(grep -w $1 /home/$USER/.fluxbenchmark/fluxbench.conf) ]]; then
         padding "${ARROW}${GREEN} [BenchD] ${CYAN}$3 added successfully${NC}" "${CHECK_MARK}"
	 return
      fi
    fi
    if [[ "$1=$2" == $(grep -w $1 /home/$USER/.fluxbenchmark/fluxbench.conf) ]]; then
        padding "${ARROW}${GREEN} [BenchD] ${CYAN}$3 skipped${NC}" "${X_MARK}"
    else
       sed -i "s/$(grep -e $1 /home/$USER/.fluxbenchmark/fluxbench.conf)/$1=$2/" /home/$USER/.fluxbenchmark/fluxbench.conf
       if [[ "$1=$2" == $(grep -w $1 /home/$USER/.fluxbenchmark/fluxbench.conf) ]]; then
         padding "${ARROW}${GREEN} [BenchD] ${CYAN}$3 replaced successfully${NC}" "${CHECK_MARK}"
       fi
    fi
  fi
  ###################################################
  if [[ "$4" == "watchdog" ]]; then
   if [[ ! -f /home/$USER/watchdog/config.js ]]; then
       padding "${ARROW}${GREEN} [WatchD] ${CYAN}Config file does not exist...${NC}" "${X_MARK}"
       return
   fi
   if [[ "$1" == ""  || "$2" == "" ]]; then
       padding "${ARROW}${GREEN} [WatchD] ${CYAN}Empty key/value skipped${NC}" "${X_MARK}"
       return
    fi
    if [[ $(cat /home/$USER/watchdog/config.js | grep "$1: '$2'") != "" ]]; then
       padding "${ARROW}${GREEN} [WatchD] ${CYAN}$3 skipped${NC}" "${X_MARK}"
       return
    fi
    if [[ $(cat /home/$USER/watchdog/config.js | grep "$1") != "" ]]; then
      sed -i "s/$(grep -e $1 /home/$USER/watchdog/config.js)/  $1: '$2',/" /home/$USER/watchdog/config.js
      if [[ $(grep -w $2 /home/$USER/watchdog/config.js) != "" ]]; then
        padding "${ARROW}${GREEN} [WatchD] ${CYAN}$3 replaced successfully${NC}" "${CHECK_MARK}"
      fi
    fi
  fi
}

function smart_reconfiguration(){
 watchdog_settings_list=("label", "tier_eps_min", "zelflux_update", "zelcash_update", "zelbench_update", "action", "ping", "web_hook_url", "telegram_alert", "telegram_bot_token", "telegram_chat_id")
 fluxos_settings_list=("kadena", "zelid", "apiport", "ipaddress", "development")
 daemon_settings_list=("zelnodeprivkey", "zelnodeoutpoint", "zelnodeindex")
 benchmark_settings_list=("fluxport", "thunder", "speedtestserverid")
 config_list=$(cat <<-END
{
  "prvkey": [{"key": "zelnodeprivkey", "label": "Identity Key"}],
  "outpoint": [{"key": "zelnodeoutpoint", "label": "Collateral TX ID"}],
  "index": [{"key": "zelnodeindex", "label": "Output Index"}],
  "node_label": [{"key": "label", "label": "Node Label"}],
  "kda_address": [{"key": "kadena", "label": "Kadena Address"}],
  "ping": [{"key": "ping", "label": "Discord Nick Ping"}],
  "zelflux_update": [{"key": "zelflux_update", "label": "FluxOS Auto Update"}],
  "zelcash_update": [{"key": "zelcash_update", "label": "Daemon Auto Update"}],
  "zelbench_update": [{"key": "zelbench_update", "label": "Benchmark Auto Update"}],
  "fluxport": [{"key": "fluxport", "label": "Multi Node Port"}],
  "thunder": [{"key": "thunder", "label": "Thunder Mode"}],
  "speedtestserverid": [{"key": "speedtestserverid", "label": "Speed Test Server ID"}],
  "upnp_port": [{"key": "apiport", "label": "UPnP Port"}],
  "development": [{"key": "development", "label": "Development Mode"}]
 }
END
)

 install_settings=($(jq -r 'keys | @sh' install_conf.json))
 for i in "${install_settings[@]}"
 do

   install_key=$(echo $i | tr -d "'")
   key=$(jq -r .$install_key[].key 2> /dev/null  <<< "$config_list")
   if [[ "$key" == "" ]]; then
    key=$install_key
   fi

   label=$(jq -r .$install_key[].label 2> /dev/null <<< "$config_list")
   if [[ "$label" == "" ]]; then
    label=${install_key^}
   fi

   if [[ $(echo ${daemon_settings_list[@]} | grep -ow "$key" | wc -l)  == "1" ]]; then
     config="daemon"
     value=$(jq -r .$install_key install_conf.json)
     config_builder "$key" "$value" "$label" "$config"
   fi

   if [[ $(echo ${benchmark_settings_list[@]} | grep -ow "$key" | wc -l)  == "1" ]]; then
     config="benchmark"
     value=$(jq -r .$install_key install_conf.json)
     config_builder "$key" "$value" "$label" "$config"
   fi

   if [[ $(echo ${fluxos_settings_list[@]} | grep -ow "$key" | wc -l)  == "1" ]]; then
     config="fluxos"
     value=$(jq -r .$install_key install_conf.json)
     config_builder "$key" "$value" "$label" "$config"
   fi

   if [[ $(echo ${watchdog_settings_list[@]} | grep -ow "$key" | wc -l)  == "1" ]]; then
     config="watchdog"
     value=$(jq -r .$install_key install_conf.json)
     config_builder "$key" "$value" "$label" "$config"
   fi
 done
}

function smart_install_conf(){

        if [[ "$3" == "import" ]]; then
	  return
	fi
	
        if [[ ! -f /home/$USER/install_conf.json ]]; then
                echo "{}" >| install_conf.json
        fi
        echo "$(jq -r --arg key "$1" --arg value "$2" '.[$key]=$value' install_conf.json)" >| install_conf.json
}

function config_smart_create() {

        if [[ "$1" != "import" ]]; then
          rm -rf /home/$USER/install_conf.json
	fi
        #daemon
        if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
                echo -e ""
                echo -e "${ARROW} ${YELLOW}Imported daemon settings:${NC}"
                zelnodeprivkey=$(grep -w zelnodeprivkey /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeprivkey=//' | sed 's/ //g')
                echo -e "${PIN}${CYAN} Identity Key = ${GREEN}$zelnodeprivkey${NC}"
                smart_install_conf "prvkey" "$zelnodeprivkey" "$1"
                zelnodeoutpoint=$(grep -w zelnodeoutpoint /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//' | sed 's/ //g')
                echo -e "${PIN}${CYAN} Collateral TX ID = ${GREEN}$zelnodeoutpoint${NC}"
                smart_install_conf "outpoint" "$zelnodeoutpoint" "$1"
                zelnodeindex=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//' | sed 's/ //g')
                echo -e "${PIN}${CYAN} Output Index = ${GREEN}$zelnodeindex${NC}"
                smart_install_conf "index" "$zelnodeindex" "$1"
        fi
	#Benchmark
	if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
	   echo -e ""
           echo -e "${ARROW} ${YELLOW}Imported Benchmark settings:${NC}"
	   thunder=$(grep -Po "(?<=thunder=)\d+" /home/$USER/.fluxbenchmark/fluxbench.conf)
	   if [[ "$thunder" == "1" ]]; then
             echo -e "${PIN}${CYAN} Thunder Mode = ${GREEN}ENABLED${NC}"
             smart_install_conf "thunder" "$thunder" "$1"
           fi
	   speedtestserverid=$(grep -Po "(?<=speedtestserverid=)\d+" /home/$USER/.fluxbenchmark/fluxbench.conf)
	   if [[ "$speedtestserverid" != "" ]]; then
             echo -e "${PIN}${CYAN} SpeedTest Server ID = ${GREEN}$speedtestserverid${NC}"
             smart_install_conf "speedtestserverid" "$speedtestserverid" "$1"
           fi
	   fluxport=$(grep -Po "(?<=fluxport=)\d+" /home/$USER/.fluxbenchmark/fluxbench.conf)  
	   if [[ "$fluxport" != "" ]]; then
             upnp_enabled=true
             echo -e "${PIN}${CYAN} Flux Port = ${GREEN}$fluxport${NC}"
             smart_install_conf "fluxport" "$fluxport" "$1"
             smart_install_conf "upnp_enabled" "$upnp_enabled" "$1"
      fi 
	fi
        #fluxOS
        if [[ -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
                echo -e ""
                echo -e "${ARROW} ${YELLOW}Imported fluxOS settings:${NC}"
                ZELID=$(grep -w zelid /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
                if [[ "$ZELID" != "" ]]; then
                        echo -e "${PIN}${CYAN} Zel ID = ${GREEN}$ZELID${NC}"
                        smart_install_conf "zelid" "$ZELID" "$1"
                fi
                KDA_A=$(grep -w kadena /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
                if [[ "$KDA_A" != "" ]]; then
                        echo -e "${PIN}${CYAN} KDA address = ${GREEN}$KDA_A${NC}"
                        smart_install_conf "kda_address" "$KDA_A" "$1"
                fi
                upnp_port=$(grep -w apiport /home/$USER/$FLUX_DIR/config/userconfig.js | grep -o '[[:digit:]]*')
                if [[ "$upnp_port" != "" ]]; then
                        gateway_ip=$(ip rout | head -n1 | awk '{print $3}' 2>/dev/null)
                        echo -e "${PIN}${CYAN} API Port = ${GREEN}$upnp_port${NC}"
                        if [[ "$upnp_enabled" == "true" ]]; then
                          echo -e "${PIN}${CYAN} Router IP = ${GREEN}$gateway_ip${NC}"
                        fi
                        smart_install_conf "upnp_port" "$upnp_port" "$1"
                        smart_install_conf "gateway_ip" "$gateway_ip" "$1"
                fi
                
        fi
        #watchdog
        if [[ -f /home/$USER/watchdog/config.js ]]; then
                echo -e ""
                echo -e "${ARROW} ${YELLOW}Imported watchdog settings:${NC}"
                node_label=$(grep -w label /home/$USER/watchdog/config.js | sed -e 's/.*label: .//' | sed -e 's/.\{2\}$//')
                if [[ "$node_label" != "" && "$node_label" != "0" ]]; then
                        echo -e "${PIN}${CYAN} Label = ${GREEN}$node_label${NC}"
                        smart_install_conf "node_label" "$node_label" "$1"
                else
                        echo -e "${PIN}${CYAN} Label = ${RED}Disabled${NC}"
                fi

                eps_limit=$(grep -w tier_eps_min /home/$USER/watchdog/config.js | sed -e 's/.*tier_eps_min: .//' | sed -e 's/.\{2\}$//')
                if [[ "$eps_limit" != "" && "$eps_limit" != "0" ]]; then
                        echo -e "${PIN}${CYAN} Tier_eps_min = ${GREEN}$eps_limit${NC}"
                        smart_install_conf "eps_limit" "$eps_limit" "$1"
                fi

                discord=$(grep -w web_hook_url /home/$USER/watchdog/config.js | sed -e 's/.*web_hook_url: .//' | sed -e 's/.\{2\}$//')
                if [[ "$discord" != "" && "$discord" != "0" ]]; then
                        echo -e "${PIN}${CYAN} Discord alert = ${GREEN}Enabled${NC}"
                        smart_install_conf "discord" "$discord" "$1"
                else
                        echo -e "${PIN}${CYAN} Discord alert = ${RED}Disabled${NC}"
                fi
                ping=$(grep -w ping /home/$USER/watchdog/config.js | sed -e 's/.*ping: .//' | sed -e 's/.\{2\}$//')
                if [[ "$ping" != "" && "$ping" != "0" ]]; then
                        if [[ "$discord" != "" && "$discord" != "0" ]]; then
                                echo -e "${PIN}${CYAN} Discord nick ping = ${GREEN}Enabled${NC}"
                                smart_install_conf "ping" "$ping" "$1"
                        else
                                echo -e "${PIN}${CYAN} Discord nick ping = ${RED}Disabled${NC}"
                        fi
                fi
                telegram_alert=$(grep -w telegram_alert /home/$USER/watchdog/config.js | sed -e 's/.*telegram_alert: .//' | sed -e 's/.\{2\}$//')
                if [[ "$telegram_alert" != "" && "$telegram_alert" != "0" ]]; then
                        echo -e "${PIN}${CYAN} Telegram alert = ${GREEN}Enabled${NC}"
                        smart_install_conf "telegram_alert" "$telegram_alert" "$1"
                else
                        echo -e "${PIN}${CYAN} Telegram alert = ${RED}Disabled${NC}"
                        smart_install_conf "telegram_alert" "0" "$1"
                fi

                telegram_bot_token=$(grep -w telegram_bot_token /home/$USER/watchdog/config.js | sed -e 's/.*telegram_bot_token: .//' | sed -e 's/.\{2\}$//')
                if [[ "$telegram_alert" == "1" ]]; then
                        echo -e "${PIN}${CYAN} Telegram bot token = ${GREEN}$telegram_bot_token${NC}"
                        smart_install_conf "telegram_bot_token" "$telegram_bot_token" "$1"
                fi

                telegram_chat_id=$(grep -w telegram_chat_id /home/$USER/watchdog/config.js | sed -e 's/.*telegram_chat_id: .//' | sed -e 's/.\{1\}$//')
                if [[ "$telegram_alert" == "1" ]]; then
                        echo -e "${PIN}${CYAN} Telegram chat id = ${GREEN}$telegram_chat_id${NC}"
                        smart_install_conf "telegram_chat_id" "$telegram_chat_id" "$1"
                fi

                zelflux_update=$(grep -w zelflux_update /home/$USER/watchdog/config.js | sed -e 's/.*zelflux_update: .//' | egrep -o '[0-9]')
                if [[ "$zelflux_update" == "1" ]]; then
                        echo -e "${PIN}${CYAN} FluxOS auto update = ${GREEN}Enabled${NC}"
                        smart_install_conf "zelflux_update" "1" "$1"
                else
                       echo -e "${PIN}${CYAN} FluxOS auto update = ${GREEN}Disabled${NC}"
                       smart_install_conf "zelflux_update" "0" "$1"
                fi

                zelcash_update=$(grep -w zelcash_update /home/$USER/watchdog/config.js | sed -e 's/.*zelcash_update: .//' | egrep -o '[0-9]')
                if [[ "$zelcash_update" == "1" ]]; then
                        echo -e "${PIN}${CYAN} Daemon auto update = ${GREEN}Enabled${NC}"
                        smart_install_conf "zelcash_update" "1" "$1"
                else
                       echo -e "${PIN}${CYAN} Daemon auto update = ${GREEN}Disabled${NC}"
                       smart_install_conf "zelcash_update" "0" "$1"
                fi

                zelbench_update=$(grep -w zelbench_update /home/$USER/watchdog/config.js | sed -e 's/.*zelbench_update: .//' | egrep -o '[0-9]')
                if [[ "$zelbench_update" == "1" ]]; then
                        echo -e "${PIN}${CYAN} Benchmark auto update = ${GREEN}Enabled${NC}"
                        smart_install_conf "zelbench_update" "1" "$1"
                else
                       echo -e "${PIN}${CYAN} Benchmark auto update = ${GREEN}Disabled${NC}"
                       smart_install_conf "zelbench_update" "0" "$1"
                fi

                action=$(grep -w action /home/$USER/watchdog/config.js | sed -e 's/.*action: .//' | egrep -o '[0-9]')
                if [[ "$action" == "1" ]]; then
                        echo -e "${PIN}${CYAN} Fix action = ${GREEN}Enabled${NC}"
                        smart_install_conf "action" "1" "$1"
                else
                       echo -e "${PIN}${CYAN} Fix action  = ${GREEN}Disabled${NC}"
                       smart_install_conf "action" "0" "$1"
                fi
        fi

	echo -e ""
	if [[ "$1" != "import" ]]; then
	  echo -e "${HOT}${CYAN} Config file created, path: ${GREEN}/home/$USER/install_conf.json${NC}"
	  echo -e ""
	fi
}

function manual_build(){
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
			if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ] || [ $(grep -Eo "^0x[a-fA-F0-9]{40}$" <<< "$zel_id") ]; then
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
		stak_info=$(curl -sSL -m 5 https://$network_url_1/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
		if [[ "$stak_info" == "" ]]; then
			stak_info=$(curl -sSL -m 5 https://$network_url_2/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2> /dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
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
    upnp_enabled=true
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
    upnp_enabled=""
		gateway_ip=""
		upnp_port=""
	fi
	firewall_disable='1'
	swapon='1'
	
	if whiptail --yesno "Would you like enable thunder mode?" 8 60; then
	     thunder='1'
        fi
	
	rm /home/$USER/install_conf.json > /dev/null 2>&1
	install_conf_create
	config_file
	echo -e    
}
###### HELPERS SECTION
function os_check(){
  passed=0
  avx_check=$(cat /proc/cpuinfo | grep -o avx | head -n1)
  os_version=$(lsb_release -rs | tr -d '.')
  architecture=$(dpkg --print-architecture)

  if [[ $(lsb_release -d) = *Debian* ]]; then
    if [[ "$os_version" -le "9" ]]; then
      passed=1
    fi
    if [[ "$os_version" -ge "10" && "$architecture" == "amd64"  &&  "$avx_check" != "" ]]; then
      passed=1
    fi
    if [[ "$os_version" -ge "12" && "$architecture" == "arm64" ]]; then
      passed=1
    fi
  fi
  
  if [[ $(lsb_release -d) = *Ubuntu* ]]; then
    if [[ "$os_version" -le "2010" ]]; then
      passed=1
    fi
    if [[ "$os_version" -ge "2204" && "$architecture" == "amd64"  &&  "$avx_check" != "" ]]; then
      passed=1
    fi
    if [[ "$os_version" -ge "2310" && "$architecture" == "arm64" ]]; then
      passed=1
    fi     
  fi

  if [[ "$passed" == "0" ]]; then 
    echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version $(lsb_release -si) - $(lsb_release -cs) not supported${NC}"
    if [[ "$architecture" == "amd64" ]]; then
      echo -e "${WORNING} ${CYNA}AVX CPU instruction set not found and is required to use MongoDB on $(lsb_release -cs)${NC}"
      echo -e "${WORNING} ${CYNA}The last version supporting CPUs without AVX is Ubuntu 20.04 LTS. Please re-image and retry installation.${NC}"
    fi
    if [[ "$architecture" == "arm64" ]]; then
      echo -e "${WORNING} ${CYNA}ARMv8.2-A or later microarchitecture is required to use MongoDB on $(lsb_release -cs)${NC}"
      echo -e "${WORNING} ${CYNA}If you're using ARM architecture older than ARMv8.2-A, it's recommended to use Ubuntu 20.04 LTS. Please re-image and retry installation.${NC}"
    fi
    echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
    echo
    exit      
  fi
}

function  fluxos_clean(){
   docker_check=$(docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" | wc -l)
   resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
   if [[ $docker_check != 0 ]]; then
     echo -e "${ARROW} ${CYAN}Removing containers...${NC}"
     sudo service docker restart > /dev/null 2>&1 && sleep 2
     docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" |
     while read line; do
       sudo docker stop $line > /dev/null 2>&1 && sleep 2
       sudo docker rm $line > /dev/null 2>&1 && sleep 2
     done
   fi
   if [[ $resource_check != 0 ]]; then
     echo -e "${ARROW} ${CYAN}Unmounting locked FluxOS resource${NC}" && sleep 1
     df | egrep 'flux' | awk '{ print $1}' |
     while read line; do
       sudo umount -l $line && sleep 1
     done
   fi
   if [[ -d /home/$USER/zelflux/ZelApps && $(find /home/$USER/zelflux/ZelApps -maxdepth 1 -mindepth 1 -type d | wc -l) -gt 1 ]]; then
     echo -e "${ARROW} ${CYAN}Cleaning FluxOS Apps directory...${NC}" && sleep 1
     APPS_LIST=($(find /home/$USER/zelflux/ZelApps -maxdepth 1 -mindepth 1 -type d -printf '%P\n'))
     LENGTH=${#APPS_LIST[@]}
     for (( j=0; j<${LENGTH}; j++ ));
     do
       if [[ "${APPS_LIST[$j]}" != "ZelShare" && "${APPS_LIST[$j]}" != "" ]]; then
         echo -e "${ARROW} ${CYAN}Apps directory removed, path: ${GREEN}/home/$USER/zelflux/ZelApps/${APPS_LIST[$j]}${NC}"
         sudo rm -rf /home/$USER/zelflux/ZelApps/${APPS_LIST[$j]}
       fi
     done
   fi
}

function round() {
  LC_NUMERIC=C printf "%.${2}f" "${1}"
}
function insertAfter() {
	local file="$1" line="$2" newText="$3"
	sudo sed -i -e "/$line/a"$'\\\n'"$newText"$'\n' "$file"
}
function max(){
	m="0"
	for n in "$@"
	do        
		if egrep -o "^[0-9]+$" <<< "$n" &>/dev/null; then
			[ "$n" -gt "$m" ] && m="$n"
		fi
	done
	echo "$m"
}
function spinning_timer() {
	animation=( ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ )
	end=$((SECONDS+NUM))
	while [ $SECONDS -lt $end ];
	do
		for i in "${animation[@]}";
		do
		echo -e ""
			echo -ne "${RED}\r\033[1A\033[0K$i ${CYAN}${MSG1}${NC}"
			sleep 0.1
		
		done
	done
	echo -ne "${MSG2}"
}
function string_limit_x_mark() {
	if [[ -z "$2" ]]; then
		string="$1"
		string=${string::50}
	else
		string=$1
		string_color=$2
		string_leght=${#string}
		string_leght_color=${#string_color}
		string_diff=$((string_leght_color-string_leght))
		string=${string_color::50+string_diff}
	fi
	echo -e "${ARROW} ${CYAN}$string[${X_MARK}${CYAN}]${NC}"
}
function string_limit_check_mark_port() {
	if [[ -z "$2" ]]; then
		string="$1"
		string=${string::65}
	else
		string=$1
		string_color=$2
		string_leght=${#string}
		string_leght_color=${#string_color}
		string_diff=$((string_leght_color-string_leght))
		string=${string_color::65+string_diff}
	fi
	echo -e "${PIN}${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
}
function string_limit_check_mark() {
	if [[ -z "$2" ]]; then
		string="$1"
		string=${string::40}
	else
		string=$1
		string_color=$2
		string_leght=${#string}
		string_leght_color=${#string_color}
		string_diff=$((string_leght_color-string_leght))
		string=${string_color::40+string_diff}
	fi
	echo -e "${ARROW} ${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
}
function integration_check() {
	FILE_ARRAY=( 'fluxbench-cli' 'fluxbenchd' 'flux-cli' 'fluxd' 'flux-fetch-params.sh' 'flux-tx' )
	ELEMENTS=${#FILE_ARRAY[@]}
	for (( i=0;i<$ELEMENTS;i++)); do
		string="${FILE_ARRAY[${i}]}......................................"
		string=${string::40}
		if [ -f "$COIN_PATH/${FILE_ARRAY[${i}]}" ]; then
			echo -e "${ARROW}${CYAN} $string[${CHECK_MARK}${CYAN}]${NC}"
		else
			echo -e "${ARROW}${CYAN} $string[${X_MARK}${CYAN}]${NC}"
			CORRUPTED="1"
		fi
	done
	if [[ "$CORRUPTED" == "1" ]]; then
		echo -e "${WORNING} ${CYAN}Flux daemon package corrupted...${NC}"
		echo -e "${WORNING} ${CYAN}Will exit out so try and run the script again...${NC}"
		echo -e ""
		exit
	fi	
	
}

function flux_block_height() {
	if [[ "$1" != "-testnet" ]]; then
		network_height_01=$(curl -sk -m 8 https://$network_url_1/api/status?q=getInfo 2> /dev/null | jq '.info.blocks' 2> /dev/null)
		network_height_02=$(curl -sk -m 8 https://$network_url_2/api/status?q=getInfo 2> /dev/null | jq '.info.blocks' 2> /dev/null)
	else
		network_height_01=$(curl -sk -m 8 https://testnet.runonflux.io/api/status?q=getInfo 2> /dev/null | jq '.info.blocks' 2> /dev/null)
		network_height_02=$(curl -sk -m 8 https://testnet.runonflux.io/api/status?q=getInfo 2> /dev/null | jq '.info.blocks' 2> /dev/null)
	fi
	EXPLORER_BLOCK_HIGHT=$(max "$network_height_01" "$network_height_02")
}

function status_loop() {
	flux_block_height "$1"
	if [[ "$EXPLORER_BLOCK_HIGHT" == $(${COIN_CLI} $1 getinfo | jq '.blocks' 2> /dev/null) ]]; then
		echo -e ""
		echo -e "${CLOCK}${GREEN} FLUX DAEMON SYNCING...${NC}"
		LOCAL_BLOCK_HIGHT=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.blocks' 2> /dev/null)
		CONNECTIONS=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.connections' 2> /dev/null)
		LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))
		NUM='2'
		MSG1="Syncing progress >> Local block height: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block height: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN}"
		MSG2="${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
		spinning_timer
		echo && echo
	else
		echo -e ""
		echo -e "${CLOCK}${GREEN}FLUX DAEMON SYNCING...${NC}"
		f=0
		start_sync=`date +%s`
		while true
		do
	    flux_block_height "$1"
			LOCAL_BLOCK_HIGHT=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.blocks' 2> /dev/null)
			CONNECTIONS=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.connections' 2> /dev/null)
			LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))
			if [[ "$LEFT" == "0" ]]; then	
				time_break='5'
			else
				time_break='20'
			fi
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
        flux_block_height "$1"
				LOCAL_BLOCK_HIGHT=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.blocks')
				CONNECTIONS=$(${COIN_CLI} $1 getinfo 2> /dev/null | jq '.connections')
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
}

function import_config_file() {
	if [[ -f /home/$USER/install_conf.json ]]; then
		import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
		#Daemon
		bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
		bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
		use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
		prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
		outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
		index=$(cat /home/$USER/install_conf.json | jq -r '.index')
		#FluxOS
		ZELID=$(cat /home/$USER/install_conf.json | jq -r '.zelid')
		KDA_A=$(cat /home/$USER/install_conf.json | jq -r '.kda_address')
		#Benchmark
		thunder=$(cat /home/$USER/install_conf.json | jq -r '.thunder')
		#WatchDog
		fix_action=$(cat /home/$USER/install_conf.json | jq -r '.action')
		flux_update=$(cat /home/$USER/install_conf.json | jq -r '.zelflux_update')
		daemon_update=$(cat /home/$USER/install_conf.json | jq -r '.zelcash_update')
		bench_update=$(cat /home/$USER/install_conf.json | jq -r '.zelbench_update')
		node_label=$(cat /home/$USER/install_conf.json | jq -r '.node_label')
		eps_limit=$(cat /home/$USER/install_conf.json | jq -r '.eps_limit')
		discord=$(cat /home/$USER/install_conf.json | jq -r '.discord')
		ping=$(cat /home/$USER/install_conf.json | jq -r '.ping')
		telegram_alert=$(cat /home/$USER/install_conf.json | jq -r '.telegram_alert')
		telegram_bot_token=$(cat /home/$USER/install_conf.json | jq -r '.telegram_bot_token')
		telegram_chat_id=$(cat /home/$USER/install_conf.json | jq -r '.telegram_chat_id')
		#UPnP
    upnp_enabled=$(cat /home/$USER/install_conf.json | jq -r '.upnp_enabled')
		upnp_port=$(cat /home/$USER/install_conf.json | jq -r '.upnp_port')
		gateway_ip=$(cat /home/$USER/install_conf.json | jq -r '.gateway_ip')
		if [[ "$1" != "silent" ]]; then
			echo -e ""
			echo -e "${ARROW} ${YELLOW}Install config:"
			if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
				echo -e "${PIN}${CYAN} Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
			else
				if [[ "$import_settings" == "1" ]]; then
					echo -e "${PIN}${CYAN} Import installation configurations...............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
				fi
			fi

			if [[ "$use_old_chain" == "1" ]]; then
				echo -e "${PIN}${CYAN} Diuring re-installation old chain will be use....................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
			else
				if [[ "$bootstrap_url" == "0" || "$bootstrap_url" == "" || $bootstrap_url == "null" ]]; then
					echo -e "${PIN}${CYAN} Use Flux daemon bootstrap from source build in script............[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
				else
					echo -e "${PIN}${CYAN} Use Flux daemon bootstrap from own source........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
				fi
				if [[ "$bootstrap_zip_del" == "1" || -z "$bootstrap_zip_del" ]]; then
					echo -e "${PIN}${CYAN} Remove Flux daemon bootstrap archive file........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
				else
					echo -e "${PIN}${CYAN} Leave Flux daemon bootstrap archive file.........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
				fi
			fi

			if [[ ! -z "$gateway_ip" && ! -z "$upnp_port" ]]; then 
			       if [[ "$upnp_port" != "null" ]]; then
			         echo -e "${PIN}${CYAN} Enable UPnP configuration........................................[${CHECK_MARK}${CYAN}]${NC}" 
			       fi
			fi

			if [[ "$discord" != "" && "$discord" != "0" ]] || [[ "$telegram_alert" == '1' ]]; then
				echo -e "${PIN}${CYAN} Enable watchdog notification.....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
			else
				echo -e "${PIN}${CYAN} Disable watchdog notification....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
			fi
			
			if [[ "$thunder" == "1" ]]; then
                                echo -e "${PIN}${CYAN} Enable thunder mode..............................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
                        fi
                 fi
    fi
}
function get_ip() {
	WANIP=$(curl --silent -m 15 https://api4.my-ip.io/ip | tr -dc '[:alnum:].')
	if [[ "$WANIP" == "" || "$WANIP" = *htmlhead* ]]; then
		WANIP=$(curl --silent -m 15 https://checkip.amazonaws.com | tr -dc '[:alnum:].')    
	fi  
	if [[ "$WANIP" == "" || "$WANIP" = *htmlhead* ]]; then
		WANIP=$(curl --silent -m 15 https://api.ipify.org | tr -dc '[:alnum:].')
	fi
	if [[ "$1" == "install" ]]; then
		if [[ "$WANIP" == "" || "$WANIP" = *htmlhead* ]]; then
			echo -e "${ARROW} ${CYAN}IP address could not be found, installation stopped .........[${X_MARK}${CYAN}]${NC}"
			echo
			exit
		fi
		string_limit_check_mark "IP: $WANIP ..........................................." "IP: ${GREEN}$WANIP${CYAN} ..........................................."
	fi
}
function check_benchmarks() {
	var_benchmark=$($BENCH_CLI getbenchmarks | jq ".$1")
	limit=$2
	if [[ $(echo "$limit>$var_benchmark" | bc) == "1" ]]; then
		var_round=$(round "$var_benchmark" 2)
		echo -e "${X_MARK} ${CYAN}$3 $var_round $4${NC}"
	fi
}
function display_banner() {
	echo -e "${BLUE}"
	figlet -t -k "FLUXNODE"
	figlet -t -k "INSTALLATION   COMPLETED"
	echo -e "${YELLOW}================================================================================================================================"
	echo -e ""
	if pm2 -v > /dev/null 2>&1; then
		pm2_flux_status=$(pm2 info flux 2> /dev/null | grep 'status' | sed -r 's/│//gi' | sed 's/status.//g' | xargs)
		if [[ "$pm2_flux_status" == "online" ]]; then
			pm2_flux_uptime=$(pm2 info flux | grep 'uptime' | sed -r 's/│//gi' | sed 's/uptime//g' | xargs)
			pm2_flux_restarts=$(pm2 info flux | grep 'restarts' | sed -r 's/│//gi' | xargs)
			echo -e "${BOOK} ${CYAN}Pm2 Flux info => status: ${GREEN}$pm2_flux_status${CYAN}, uptime: ${GREEN}$pm2_flux_uptime${NC} ${SEA}$pm2_flux_restarts${NC}" 
		else
			if [[ "$pm2_flux_status" != "" ]]; then
				pm2_flux_restarts=$(pm2 info flux | grep 'restarts' | sed -r 's/│//gi' | xargs)
				echo -e "${PIN} ${CYAN}PM2 Flux status: ${RED}$pm2_flux_status${NC}, restarts: ${RED}$pm2_flux_restarts${NC}" 
			fi
		fi
		echo -e ""
	fi
	echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE FLUX DAEMON.${NC}" 
	echo -e "${PIN} ${CYAN}Start Flux daemon: ${SEA}sudo systemctl start zelcash${NC}"
	echo -e "${PIN} ${CYAN}Stop Flux daemon: ${SEA}sudo systemctl stop zelcash${NC}"
	echo -e "${PIN} ${CYAN}Help list: ${SEA}${COIN_CLI} help${NC}"
	echo
	echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE BENCHMARK.${NC}" 
	echo -e "${PIN} ${CYAN}Get info: ${SEA}${BENCH_CLI} $1 getinfo${NC}"
	echo -e "${PIN} ${CYAN}Check benchmark: ${SEA}${BENCH_CLI} $1 getbenchmarks${NC}"
	echo -e "${PIN} ${CYAN}Restart benchmark: ${SEA}${BENCH_CLI} $1 restartnodebenchmarks${NC}"
	echo -e "${PIN} ${CYAN}Stop benchmark: ${SEA}${BENCH_CLI} $1 stop${NC}"
	echo -e "${PIN} ${CYAN}Start benchmark: ${SEA}sudo systemctl restart zelcash${NC}"
	echo
	echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE FLUX.${NC}"
	echo -e "${PIN} ${CYAN}Summary info: ${SEA}pm2 info flux${NC}"
	echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 logs flux${NC}"
	echo -e "${PIN} ${CYAN}Stop Flux: ${SEA}pm2 stop flux${NC}"
	echo -e "${PIN} ${CYAN}Start Flux: ${SEA}pm2 start flux${NC}"
	echo -e ""
	if [[ "$WATCHDOG_INSTALL" == "1" ]]; then
		echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE WATCHDOG.${NC}"
		echo -e "${PIN} ${CYAN}Stop watchdog: ${SEA}pm2 stop watchdog${NC}"
		echo -e "${PIN} ${CYAN}Start watchdog: ${SEA}pm2 start watchdog --watch${NC}"
		echo -e "${PIN} ${CYAN}Restart watchdog: ${SEA}pm2 reload watchdog --watch${NC}"
		echo -e "${PIN} ${CYAN}Error logs: ${SEA}~/watchdog/watchdog_error.log${NC}"
		echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 logs watchdog${NC}"
		echo
		echo -e "${PIN} ${RED}IMPORTANT: After installation check ${SEA}'pm2 list'${RED} if not work, type ${SEA}'source /home/$USER/.bashrc'${NC}"
		echo -e ""
	fi
	echo -e "${PIN} ${CYAN}To access your frontend to Flux enter this in as your url: ${SEA}${WANIP}:${ZELFRONTPORT}${NC}"
	echo -e "${YELLOW}===================================================================================================================[${GREEN}Duration: $((($(date +%s)-$start_install)/60)) min. $((($(date +%s)-$start_install) % 60)) sec.${YELLOW}]${NC}"
	sleep 1
	cd $HOME
	exec bash
}
function create_swap() {
	if [[ -z "$swapon" ]]; then
		#echo -e "${YELLOW}Creating swap if none detected...${NC}" && sleep 1
		MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
		gb=$(awk "BEGIN {print $MEM/1048576}")
		GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
		if [ "$GB" -lt 2 ]; then
			(( swapsize=GB*2 ))
			swap="$swapsize"G
		elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
			swap=4G
		elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
			swap=2G
		fi
		if ! grep -q "swapfile" /etc/fstab; then
			#  if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
			sudo fallocate -l "$swap" /swapfile > /dev/null 2>&1
			sudo chmod 600 /swapfile > /dev/null 2>&1
			sudo mkswap /swapfile > /dev/null 2>&1
			sudo swapon /swapfile > /dev/null 2>&1
			echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null 2>&1
			echo -e "${ARROW} ${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
		fi
	else
		if [[ "$swapon" == "1" ]]; then
			MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
			gb=$(awk "BEGIN {print $MEM/1048576}")
			GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
			if [ "$GB" -lt 2 ]; then
				(( swapsize=GB*2 ))
				swap="$swapsize"G
			elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
				swap=4G
			elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
				swap=2G
			fi
			if ! grep -q "swapfile" /etc/fstab; then
				sudo fallocate -l "$swap" /swapfile > /dev/null 2>&1
				sudo chmod 600 /swapfile > /dev/null 2>&1
				sudo mkswap /swapfile > /dev/null 2>&1
				sudo swapon /swapfile > /dev/null 2>&1
				echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null 2>&1
				echo -e "${ARROW} ${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
			fi
		fi
	fi
	sleep 2
}
######### EDIT FUNCTION
function daemon_reconfiguration(){
	echo -e "${GREEN}Module: Flux Daemon Reconfiguration${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
	fi
	config_veryfity
	echo -e ""
	echo -e "${ARROW} ${YELLOW}Fill in all the fields that you want to replace${NC}"
	sleep 2
	skip_change='3'
	zelnodeprivkey="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Identity Key generated by your Zelcore" 8 72 3>&1 1>&2 2>&3)"
	sleep 1
	zelnodeoutpoint="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Collateral TX ID" 8 72 3>&1 1>&2 2>&3)"
	sleep 1
	zelnodeindex="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Output Index" 8 60 3>&1 1>&2 2>&3)"
	sleep 1
	if [[ "$zelnodeprivkey" == "" ]]; then
		skip_change=$((skip_change-1))
		echo -e "${ARROW} ${CYAN}Replace FluxNode Identity Key skipped....................[${CHECK_MARK}${CYAN}]${NC}"
	fi
	if [[ "$zelnodeoutpoint" == "" ]]; then
		skip_change=$((skip_change-1))
		echo -e "${ARROW} ${CYAN}Replace FluxNode Collateral TX ID skipped ..................[${CHECK_MARK}${CYAN}]${NC}"
	fi
	if [[ "$zelnodeindex" == "" ]]; then
	skip_change=$((skip_change-1))
		echo -e "${ARROW} ${CYAN}Replace FluxNode Output Index skipped......................[${CHECK_MARK}${CYAN}]${NC}"
	fi
	if [[ "$skip_change" == "0" ]]; then
		echo -e "${ARROW} ${YELLOW}All fields are empty changes skipped...${NC}"
		echo
		exit
	fi
	echo -e "${ARROW} ${CYAN}Stopping Flux daemon service...${NC}"
	sudo systemctl stop $COIN_NAME  > /dev/null 2>&1 && sleep 2
	sudo fuser -k 16125/tcp > /dev/null 2>&1
	if [[ "$zelnodeprivkey" != "" ]]; then
		if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "${ARROW} ${CYAN}Replace FluxNode Identity Key skipped....................[${CHECK_MARK}${CYAN}]${NC}"
					else
					sed -i "s/$(grep -e zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeprivkey=$zelnodeprivkey/" ~/$CONFIG_DIR/$CONFIG_FILE
									if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
													echo -e "${ARROW} ${CYAN}FluxNode Identity Key replaced successful................[${CHECK_MARK}${CYAN}]${NC}"			
									fi
		fi
	fi

	if [[ "$zelnodeoutpoint" != "" ]]; then
		if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "${ARROW} ${CYAN}Replace FluxNode Collateral TX ID outpoint skipped ..................[${CHECK_MARK}${CYAN}]${NC}"
		else
			sed -i "s/$(grep -e zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeoutpoint=$zelnodeoutpoint/" ~/$CONFIG_DIR/$CONFIG_FILE
			if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
				echo -e "${ARROW} ${CYAN}FluxNode Collateral TX ID replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
			fi
	 fi
	fi

	if [[ "$zelnodeindex" != "" ]]; then
		if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "${ARROW} ${CYAN}Replace FluxNode Output Index skipped......................[${CHECK_MARK}${CYAN}]${NC}"
		else
			sed -i "s/$(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeindex=$zelnodeindex/" ~/$CONFIG_DIR/$CONFIG_FILE
			if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
				echo -e "${ARROW} ${CYAN}FluxNode Output Index replaced successful..................[${CHECK_MARK}${CYAN}]${NC}"
			fi
		fi
	fi
	pm2 restart flux > /dev/null 2>&1
	sudo systemctl start $COIN_NAME  > /dev/null 2>&1 && sleep 2
	NUM='35'
	MSG1='Restarting daemon service...'
	MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
	spinning_timer
	echo -e "" && echo -e ""
}
function replace_kadena {

  if [[ -z "$KDA_A"  ]]; then
		while true
		do
			KDA_A=$(whiptail --inputbox "Please enter your Kadena address from Zelcore" 8 85 3>&1 1>&2 2>&3)
			KDA_A=$(grep -Eo "^k:[0-9a-z]{64}\b" <<< "$KDA_A")
			if [[ "$KDA_A" != "" && "$KDA_A" != *kadena* && "$KDA_A" = *k:*  ]]; then    
				echo -e "${ARROW} ${CYAN}Kadena address is valid.................[${CHECK_MARK}${CYAN}]${NC}"				    
				sleep 2
				break
			else	     
				echo -e "${ARROW} ${CYAN}Kadena address is not valid.............[${X_MARK}${CYAN}]${NC}"
				sleep 2		     
			fi
		done
	fi	
	kda_address="kadena:$KDA_A?chainid=0"
	if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep "kadena") != "" ]]; then
    config_builder "kadena" "$kda_address" "Kadena address" "fluxos"
		##insertAfter "/home/$USER/zelflux/config/userconfig.js" "zelid" "    kadena: '$kda_address',"
		##echo -e "${ARROW} ${CYAN}Kadena address set successfully........................[${CHECK_MARK}${CYAN}]${NC}"
	fi
}
function replace_zelid() {
	while true
	do
		new_zelid="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
		if [ $(printf "%s" "$new_zelid" | wc -c) -eq "34" ] || [ $(printf "%s" "$new_zelid" | wc -c) -eq "33" ] || [ $(grep -Eo "^0x[a-fA-F0-9]{40}$" <<< "$new_zelid") ]; then
			string_limit_check_mark "Zel ID is valid..........................................."
			break
		else
			string_limit_x_mark "Zel ID is not valid try again..........................................."
			sleep 2
		fi
	done

 
	if [[ $(grep -w $new_zelid /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
		echo -e "${ARROW} ${CYAN}Replace ZEL ID skipped............................[${CHECK_MARK}${CYAN}]${NC}"
	else
		config_builder "zelid" "$new_zelid" "ZEL ID" "fluxos"
		#if [[ $(grep -w $new_zelid /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
			#echo -e "${ARROW} ${CYAN}ZEL ID replaced successful........................[${CHECK_MARK}${CYAN}]${NC}"
		#fi
	fi
}

function thunder_mode(){

 if [[ -d $HOME/.fluxbenchmark ]]; then
   sudo chown -R $USER:$USER $HOME/.fluxbenchmark > /dev/null 2>&1
 else
   mkdir -p $HOME/.fluxbenchmark > /dev/null 2>&1
 fi
 
 if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
   if [[ $(grep -e "thunder" /home/$USER/.fluxbenchmark/fluxbench.conf) == "" ]]; then
     config_builder "thunder" "1" "Thunder Mode" "benchmark"
   else
     sed -i "/$(grep -e "thunder" /home/$USER/.fluxbenchmark/fluxbench.conf)/d" /home/$USER/.fluxbenchmark/fluxbench.conf > /dev/null 2>&1
     echo -e "${ARROW}${GREEN} [BenchD] ${CYAN}Thunder Mode disabled successful${NC}" "${CHECK_MARK}"
   fi
 else
   config_builder "thunder" "1" "Thunder Mode" "benchmark"
 fi
 if [[ "$1" == "" ]]; then
   echo -e "${ARROW}${GREEN} [BenchD] ${CYAN}Restarting service... ${NC}"
   sudo systemctl restart zelcash > /dev/null 2>&1
 fi
 
}

function development_mode(){
  if [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "development: 'false'") != "" ]] || [[ $(cat /home/$USER/$FLUX_DIR/config/userconfig.js | grep "development: false") ]]; then
    echo -e "${ARROW}${GREEN} [FluxOS] ${CYAN}Enabling development mode... ${NC}"
    config_builder "development" "true" "Development Mode" "fluxos"
    cd $HOME/$FLUX_DIR
    git checkout development > /dev/null 2>&1
    pm2 restart flux > /dev/null 2>&1
  else
    echo -e "${ARROW}${GREEN} [FluxOS] ${CYAN}Disabling development mode... ${NC}"
    config_builder "development" "false" "Development Mode" "fluxos"
    cd $HOME/$FLUX_DIR
    git checkout master > /dev/null 2>&1
    pm2 restart flux > /dev/null 2>&1
  fi
}

function fluxos_reconfiguration {
 echo -e "${GREEN}Module: FluxOS reconfiguration${NC}"
 echo -e "${YELLOW}================================================================${NC}"
 if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
 fi
 if ! [[ -f /home/$USER/zelflux/config/userconfig.js ]]; then
	 echo -e "${WORNING} ${CYAN}FluxOS userconfig.js not exist, operation aborted${NC}"
	 echo -e ""
	 exit
 fi
 CHOICE=$(
 whiptail --title "FluxOS Configuration" --menu "Make your choice" 15 40 6 \
 "1)" "Replace ZELID"   \
 "2)" "Add/Replace kadena address" \
 "3)" "Enable/Disable thunder mode" \
 "4)" "Enable/Disable development mode" \
 "5)" "Blocked Ports Management" \
 "6)" "Blocked Repositories Management" \
 "7)" "FluxOS config backup" \
 "8)" "FluxOS config restore" 3>&2 2>&1 1>&3
	)
		case $CHOICE in
		"1)")
		replace_zelid
		;;
		"2)")
		replace_kadena
		;;
		"3)")
		thunder_mode
		;;
	  "4)")
		development_mode
		;;
	  "5)")
		blocked_ports
		;;
    "6)")
		blocked_repositories
		;;
  	"7)")
		fluxosConfigBackup
		;;	
  	"8)")
		fluxosConfigRestore
		;;	
	esac
}
######### BOOTSTRAP SECTION ############################
function tar_file_unpack() {
	local TARFILE=$1
	local DEST_DIR=$2
	local MIME_TYPE=$(file -b --mime-type $TARFILE)
	local GZIP=""
	# tar is application/x-tar
	[[ "$MIME_TYPE" == "application/gzip" ]] && GZIP="-z"
	echo -e "${ARROW} ${CYAN}Unpacking daemon bootstrap please be patient...${NC}"
	pv $TARFILE | tar $GZIP -x -C $DEST_DIR
}
function check_tar() {
	echo -e "${ARROW} ${CYAN}Checking file integrity...${NC}"
	if tar -tf "$1" &>/dev/null; then
		echo -e "${ARROW} ${CYAN}Bootstrap file is valid.................[${CHECK_MARK}${CYAN}]${NC}"
	else
		echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
		rm -rf $1
	fi
}
function tar_file_pack() {
	echo -e "${ARROW} ${CYAN}Creating bootstrap archive file...${NC}"
	tar -czf - $1 | (pv -p --timer --rate --bytes > $2) 2>&1
}
function cdn_speedtest() {
	if [[ -z $1 || "$1" == "0" ]]; then
		BOOTSTRAP_FILE="flux_explorer_bootstrap.tar.gz"
	else
		BOOTSTRAP_FILE="$1"
	fi
	if [[ -z $2 ]]; then
		dTime="5"
	else
		dTime="$2"
	fi
	if [[ -z $3 ]]; then
		rand_by_domain=("5" "6" "7" "8" "9" "10" "11" "12")
	else
		msg="$3"
		shift
		shift
		rand_by_domain=("$@")
		custom_url="1"
	fi
	size_list=()
	i=0
	len=${#rand_by_domain[@]}
	echo -e "${ARROW} ${CYAN}Running quick download speed test for ${BOOTSTRAP_FILE}, Servers: ${GREEN}$len${NC}"
	start_test=`date +%s`
	while [ $i -lt $len ];
   do
		if [[ "$custom_url" == "1" ]]; then
			testing=$(curl -m ${dTime} ${rand_by_domain[$i]}${BOOTSTRAP_FILE}  --output testspeed -fail --silent --show-error 2>&1)
		else
			testing=$(curl -m ${dTime} http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/${BOOTSTRAP_FILE}  --output testspeed -fail --silent --show-error 2>&1)
		fi
		testing_size=$(grep -Po "\d+" <<< "$testing" | paste - - - - | awk '{printf  "%d\n",$3}')
		mb=$(bc <<<"scale=2; $testing_size / 1048576 / $dTime" | awk '{printf "%2.2f\n", $1}')
		if [[ "$custom_url" == "1" ]]; then
			domain=$(sed -e 's|^[^/]*//||' -e 's|/.*$||' <<< ${rand_by_domain[$i]})
			echo -e "  ${RIGHT_ANGLE} ${GREEN}URL - ${YELLOW}${domain}${GREEN} - Bits Downloaded: ${YELLOW}$testing_size${NC} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
		else
			echo -e "  ${RIGHT_ANGLE} ${GREEN}cdn-${YELLOW}${rand_by_domain[$i]}${GREEN} - Bits Downloaded: ${YELLOW}$testing_size${NC} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
		fi
		size_list+=($testing_size)
		if [[ "$testing_size" == "0" ]]; then
			failed_counter=$(($failed_counter+1))
		fi
		i=$(($i+1))
	done
	rServerList=$((${#size_list[@]}-$failed_counter))
	echo -e "${ARROW} ${CYAN}Valid servers: ${GREEN}${rServerList} ${CYAN}- Duration: ${GREEN}$((($(date +%s)-$start_test)/60)) min. $((($(date +%s)-$start_test) % 60)) sec.${NC}"
	sudo rm -rf testspeed > /dev/null 2>&1
	if [[ "$rServerList" == "0" ]]; then
	server_offline="1"
	return 
	fi
	arr_max=$(printf '%s\n' "${size_list[@]}" | sort -n | tail -1)
	for i in "${!size_list[@]}"; do
		[[ "${size_list[i]}" == "$arr_max" ]] &&
		max_indexes+=($i)
	done
	server_index=${rand_by_domain[${max_indexes[0]}]}
	if [[ "$custom_url" == "1" ]]; then
		BOOTSTRAP_URL="$server_index"
	else
		BOOTSTRAP_URL="http://cdn-${server_index}.runonflux.io/apps/fluxshare/getfile/"
	fi
	DOWNLOAD_URL="${BOOTSTRAP_URL}${BOOTSTRAP_FILE}"
   #Print the results
	mb=$(bc <<<"scale=2; $arr_max / 1048576 / $dTime" | awk '{printf "%2.2f\n", $1}')
	if [[ "$custom_url" == "1" ]]; then
		domain=$(sed -e 's|^[^/]*//||' -e 's|/.*$||' <<< ${server_index})
		echo -e "${ARROW} ${CYAN}Best server is: ${YELLOW}${domain} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
	else
		echo -e "${ARROW} ${CYAN}Best server is: ${GREEN}cdn-${YELLOW}${rand_by_domain[${max_indexes[0]}]} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
	fi
   #echo -e "${CHECK_MARK} ${GREEN}Fastest Server: ${YELLOW}$DOWNLOAD_URL${NC}"
}
function bootstrap_new() {
	echo -e "${ARROW} ${YELLOW}Restore daemon chain from bootstrap${NC}"
	if ! wget --version > /dev/null 2>&1 ; then
		sudo apt install -y wget > /dev/null 2>&1 && sleep 2
	fi
	if ! wget --version > /dev/null 2>&1 ; then
		echo -e "${WORNING} ${CYAN}Wget not installed, operation aborted.. ${NC}" && sleep 1
		echo -e ""
		return
	fi
	Mode="$1"
	bootstrap_local
	if [[ -f "$FILE_PATH" ]]; then
		if [[ "$Mode" != "install" ]]; then
			start_service
			if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
				sudo rm -rf $FILE_PATH > /dev/null 2>&1 && sleep 2
			fi
		fi
		return
	else
		if [[ ! -f /home/$USER/install_conf.json ]]; then
			bootstrap_manual
			if [[ "$Mode" != "install" && "$server_offline" == "0" ]]; then
				start_service
				if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
					sudo rm -rf $FILE_PATH /dev/null 2>&1 && sleep 2
				fi
			fi
			return
		fi
	fi

	if [[  "$bootstrap_url" == "0"  || "$bootstrap_url" == "" || "$bootstrap_url" == "null" ]]; then
		cdn_speedtest "0" "6"
		if [[ "$server_offline" == "1" ]]; then
			echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation aborted.. ${NC}" && sleep 1
			echo -e ""
			return 1
		fi
		if [[ "$Mode" != "install" ]]; then
			stop_service
		fi
		echo -e "${ARROW} ${CAYN}Downloading File: ${GREEN}$DOWNLOAD_URL ${NC}"
		wget --tries 5 -O $BOOTSTRAP_FILE $DOWNLOAD_URL -q --show-progress
		tar_file_unpack "/home/$USER/$BOOTSTRAP_FILE" "/home/$USER/$CONFIG_DIR"
	else
	  if [[ "$Mode" != "install" ]]; then
			stop_service
		fi
		DOWNLOAD_URL="$bootstrap_url"
		echo -e "${ARROW} ${CAYN}Downloading File: ${GREEN}$DOWNLOAD_URL ${NC}"
		wget --tries 5 -O $BOOTSTRAP_FILE $DOWNLOAD_URL -q --show-progress
		tar_file_unpack "/home/$USER/$BOOTSTRAP_FILE" "/home/$USER/$CONFIG_DIR"
	fi

	if [[ "$Mode" != "install" ]]; then
		start_service
	fi

	if [[ -z "$bootstrap_zip_del" ]]; then
		rm -rf /home/$USER/$BOOTSTRAP_FILE > /dev/null 2>&1
	else
		if [[ "$bootstrap_zip_del" == "1" ]]; then
			rm -rf /home/$USER/$BOOTSTRAP_FILE > /dev/null 2>&1
		fi
	fi
}
function bootstrap_manual() {
	CHOICE=$(
		whiptail --title "FluxNode Installation" --menu "Choose a method how to get bootstrap file" 10 47 2  \
		"1)" "Download from source build in script" \
		"2)" "Download from own source" 3>&2 2>&1 1>&3
	)
	case $CHOICE in
	"1)")
		#server_list=("http://cdn-11.runonflux.io/apps/fluxshare/getfile/" "http://cdn-12.runonflux.io/apps/fluxshare/getfile/" "http://cdn-13.runonflux.io/apps/fluxshare/getfile/" "http://cdn-10.runonflux.io/apps/fluxshare/getfile/")
		#cdn_speedtest "0" "8" "${server_list[@]}"
		cdn_speedtest "0" "6"
		if [[ "$server_offline" == "1" ]]; then
			echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation aborted.. ${NC}" && sleep 1
			echo -e ""
			return 1
		fi
		DB_HIGHT=$(curl -sSL -m 10 "${BOOTSTRAP_URL}flux_explorer_bootstrap.json" | jq -r '.block_height' 2>/dev/null)
		if [[ "$DB_HIGHT" == "" ]]; then
			DB_HIGHT=$(curl -sSL -m 10 "${BOOTSTRAP_URL}flux_explorer_bootstrap.json" | jq -r '.block_height' 2>/dev/null)
		fi
		if [[ "$DB_HIGHT" != "" ]]; then
			echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
		fi
		echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$DOWNLOAD_URL ${NC}"
		wget --tries 5 -O $BOOTSTRAP_FILE $DOWNLOAD_URL -q --show-progress
		if [[ "$Mode" != "install" ]]; then
			stop_service
		fi
		tar_file_unpack "/home/$USER/$BOOTSTRAP_FILE" "/home/$USER/$CONFIG_DIR"
		sleep 1
	;;
	"2)")
		DOWNLOAD_URL="$(whiptail --title "Flux daemon bootstrap setup" --inputbox "Enter your URL (zip, tar.gz)" 8 72 3>&1 1>&2 2>&3)"
		echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$DOWNLOAD_URL ${NC}"
		BOOTSTRAP_FILE="${DOWNLOAD_URL##*/}"
		wget --tries 5 -O $BOOTSTRAP_FILE $DOWNLOAD_URL -q --show-progress
		if [[ "$Mode" != "install" ]]; then
			stop_service
		fi
		if [[ "$BOOTSTRAP_FILE" == *".zip"* ]]; then
			echo -e "${ARROW} ${CYAN}Unpacking wallet bootstrap please be patient...${NC}"
			unzip -o $BOOTSTRAP_FILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
		else
			tar_file_unpack "/home/$USER/$BOOTSTRAP_FILE" "/home/$USER/$CONFIG_DIR"
			sleep 1
		fi
	;;
	esac
}
function bootstrap_local() {
	local BOOTSTRAP_STEM="flux_explorer_bootstrap"
	local BOOTSTRAP_FILES=($(ls /home/$USER/$BOOTSTRAP_STEM.{tar,tar.gz} 2>/dev/null))

	if [ "$BOOTSTRAP_FILES" -a ${#BOOTSTRAP_FILES[@]} ]; then
		# we take the first bootstrap file
		FILE_PATH="/home/$USER/$BOOTSTRAP_FILES"
		echo -e "${ARROW} ${CYAN}Local bootstrap file detected...${NC}"
		check_tar "$FILE_PATH"
		if [ -f "$FILE_PATH" ]; then
			if [[ "$Mode" != "install" ]]; then
				stop_service
			fi
			tar_file_unpack "$FILE_PATH" "/home/$USER/$CONFIG_DIR"
		fi
	fi
}
function flux_chain_date_wipe() {
	if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
		echo -e "${ARROW} ${CYAN}Removing blocks, chainstate, determ_zelnodes directories...${NC}"
		rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/determ_zelnodes > /dev/null 2>&1
	fi
}
function stop_service() {
	pm2 stop watchdog > /dev/null 2>&1 && sleep 2
	echo -e "${ARROW} ${CYAN}Stopping Flux daemon service${NC}"
	sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
	sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
	flux_chain_date_wipe
}
function start_service() {
	sudo systemctl start zelcash  > /dev/null 2>&1 && sleep 2
	NUM='35'
	MSG1='Starting Flux daemon service...'
	MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
	spinning_timer
	echo -e "" && echo -e ""
	pm2 restart flux > /dev/null 2>&1 && sleep 2
	pm2 start watchdog --watch > /dev/null 2>&1 && sleep 2
}
######### INSTALLATION SECTION ############################
function install_mongod() {
  source_set=0
	echo -e ""
	echo -e "${ARROW} ${YELLOW}Removing any instances of Mongodb...${NC}"
	sudo systemctl stop mongod > /dev/null 2>&1 
	sudo apt remove -f mongod* -y > /dev/null 2>&1 
	sudo apt purge --allow-change-held-packages mongod* -y > /dev/null 2>&1 
	sudo apt autoremove -y > /dev/null 2>&1 
 	sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
	sudo rm /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1 
	echo -e "${ARROW} ${YELLOW}Mongodb installing...${NC}"
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
    curl -fsSL https://pgp.mongodb.com/server-4.4.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    source_set=2
  fi
  #Debian MongoDB 4.4
  if [[ "$avx_check" == ""  && "$os_name" == "Debian"  && "$architecture" == "amd64" && "$os_version" -le "9" ]] || [[ "$os_name" == "Debian"  && "$architecture" == "arm64" && "$os_version" -le "9" ]]; then
    curl -fsSL https://pgp.mongodb.com/server-4.4.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/4.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    source_set=2
  fi
  #ARM MongoDB 7.0
  if [[ "$architecture" == "arm64" ]]; then
    if [[ "$os_name" == "Debian" && "$os_version" -ge "12" ]]; then
      curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
		  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null 2>&1
      source_set=1
    fi
    if [[ "$os_name" == "Ubuntu" && "$os_version" -ge "2304" ]]; then
      curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null 2>&1 
      source_set=1
    fi
  fi
  #AVX with AMD64
  if [[ "$avx_check" != ""  && "$architecture" == "amd64" ]]; then
    if [[ "$os_name" == "Ubuntu" ]]; then
      if [[ "$os_version" -ge "2004" ]]; then
         if [[ "$os_version" == "2004" ]]; then
           codename="focal"
         else
           codename="jammy"
         fi
         curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
         echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu ${codename}/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null 2>&1 
         source_set=1
      else
         curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
         echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null 2>&1 
         source_set=1
      fi
    fi
    if [[ "$os_name" == "Debian" ]]; then
      if [[ "$os_version" -le "9" ]]; then
         curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
         echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null 2>&1
         source_set=1
      else
         curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg > /dev/null 2>&1
         echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null 2>&1
         source_set=1
      fi
    fi 
  fi
  if [[ "$source_set" == "0" ]]; then
    echo -e "${WORNING} ${RED}OS type $(lsb_release -si) not supported..${NC}"
    echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
    echo
    exit    
  fi
	sudo apt-get update -y > /dev/null 2>&1
  if [[ "$source_set" == "2" ]]; then
	  sudo apt install -y mongodb-org=4.4.18 mongodb-org-server=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-mongos=4.4.18 mongodb-org-tools=4.4.18 > /dev/null 2>&1 && sleep 2
	  echo "mongodb-org hold" | sudo dpkg --set-selections > /dev/null 2>&1
    echo "mongodb-org-server hold" | sudo dpkg --set-selections > /dev/null 2>&1 
    echo "mongodb-org-shell hold" | sudo dpkg --set-selections > /dev/null 2>&1 
    echo "mongodb-org-mongos hold" | sudo dpkg --set-selections > /dev/null 2>&1 
    echo "mongodb-org-tools hold" | sudo dpkg --set-selections > /dev/null 2>&1 
	else
	  DEBIAN_FRONTEND=noninteractive sudo apt-get --yes install mongodb-org > /dev/null 2>&1 
	fi
  sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
  sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
	sudo systemctl enable mongod > /dev/null 2>&1
	sudo systemctl start  mongod > /dev/null 2>&1
	if mongod --version > /dev/null 2>&1; then
		string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
		echo
	else
		string_limit_x_mark "MongoDB was not installed................................."
		echo
	fi
}
function install_nodejs() {
	echo -e "${ARROW} ${YELLOW}Removing any instances of Nodejs...${NC}"
	n-uninstall -y > /dev/null 2>&1 && sleep 1
	rm -rf ~/n
	sudo apt-get remove nodejs npm nvm -y > /dev/null 2>&1 && sleep 1
	sudo apt-get purge nodejs nvm -y > /dev/null 2>&1 && sleep 1
	sudo rm -rf /usr/local/bin/npm
	sudo rm -rf /usr/local/share/man/man1/node*
	sudo rm -rf /usr/local/lib/dtrace/node.d
	sudo rm -rf ~/.npm
	sudo rm -rf ~/.nvm
	sudo rm -rf ~/.pm2
	sudo rm -rf ~/.node-gyp
	sudo rm -rf /opt/local/bin/node
	sudo rm -rf opt/local/include/node
	sudo rm -rf /opt/local/lib/node_modules
	sudo rm -rf /usr/local/lib/node*
	sudo rm -rf /usr/local/include/node*
	sudo rm -rf /usr/local/bin/node*
	echo -e "${ARROW} ${YELLOW}Nodejs installing...${NC}"
	curl -SsL -m 10 https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash > /dev/null 2>&1
	. ~/.profile
	. ~/.bashrc
	sleep 1
	nvm install 20.9.0 > /dev/null 2>&1
	if node -v > /dev/null 2>&1; then
		string_limit_check_mark "Nodejs $(node -v) installed................................." "Nodejs ${GREEN}$(node -v)${CYAN} installed................................."
		echo
	else
		string_limit_x_mark "Nodejs was not installed................................."
		echo
	fi
}
function start_install() {
	start_install=`date +%s`
	sudo echo -e "$USER ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo 
	if jq --version > /dev/null 2>&1; then
		echo -e ""
	else
		echo -e ""
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
	if [ "$USER" = "root" ]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}root${CYAN}, please switch to the username you just created.${NC}"
		sleep 4
		exit
	fi
	start_dir=$(pwd)
	correct_dir="/home/$USER"
	echo -e "${ARROW} ${YELLOW}Checking directory....${NC}"
	if [[ "$start_dir" == "$correct_dir" ]]; then
		echo -e "${ARROW} ${CYAN}Correct directory ${GREEN}$(pwd)${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
	else
		echo -e "${ARROW} ${CYAN}Bad directory switching...${NC}"
		cd
		echo -e "${ARROW} ${CYAN}Current directory ${GREEN}$(pwd)${CYAN}${NC}"
	fi
	sleep 1
	import_config_file
	if [[ -z "$index" || -z "$outpoint" || -z "$prvkey" ]]; then
		import_date
	else
		if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != ""  && "$ZELID" != ""  ]]; then
			IMPORT_ZELCONF="1"
			IMPORT_ZELID="1"
			echo -e ""
			echo -e "${ARROW} ${YELLOW}Install conf settings:${NC}"
			zelnodeprivkey="$prvkey"
			echo -e "${PIN}${CYAN} Identity Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
			zelnodeoutpoint="$outpoint"
			echo -e "${PIN}${CYAN} Collateral TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
			zelnodeindex="$index"
			echo -e "${PIN}${CYAN} Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1
			if [[ "$ZELID" != "" ]]; then
				echo -e "${PIN}${CYAN} Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
			fi
			if [[ "$KDA_A" != "" ]]; then
				echo -e "${PIN}${CYAN} KDA address = ${GREEN}$KDA_A${NC}" && sleep 1
			fi
			echo -e ""
			echo -e "${ARROW} ${YELLOW}Watchdog conf settings:${NC}"
			if [[ "$node_label" != "" && "$node_label" != "0" ]]; then
					echo -e "${PIN}${CYAN} Label = ${GREEN}Enabled${NC}" && sleep 1
			else
					echo -e "${PIN}${CYAN} Label = ${RED}Disabled${NC}" && sleep 1
			fi
			if [[ "$eps_limit" != "" && "$eps_limit" != "0" ]]; then
				echo -e "${PIN}${CYAN} Tier_eps_min = ${GREEN}$eps_limit${NC}"   
			fi  
			if [[ "$discord" != "" && "$discord" != "0" ]]; then
					echo -e "${PIN}${CYAN} Discord alert = ${GREEN}Enabled${NC}" && sleep 1
			else
					echo -e "${PIN}${CYAN} Discord alert = ${RED}Disabled${NC}" && sleep 1
			fi
			if [[ "$ping" != "" && "$ping" != "0" ]]; then      
				if [[ "$discord" != "" && "$discord" != "0" ]]; then
					echo -e "${PIN}${CYAN} Discord ping = ${GREEN}Enabled${NC}" && sleep 1
				else
					echo -e "${PIN}${CYAN} Discord ping = ${RED}Disabled${NC}" && sleep 1
				fi
			fi
			if [[ "$telegram_alert" != "" && "$telegram_alert" != "0" ]]; then
				echo -e "${PIN}${CYAN} Telegram alert = ${GREEN}Enabled${NC}" && sleep 1
			else
				echo -e "${PIN}${CYAN} Telegram alert = ${RED}Disabled${NC}" && sleep 1
			fi
			if [[ "$telegram_alert" == "1" ]]; then
					echo -e "${PIN}${CYAN} Telegram bot token = ${GREEN}$telegram_alert${NC}" && sleep 1	
			fi
			if [[ "$telegram_alert" == "1" ]]; then
					echo -e "${PIN}${CYAN} Telegram chat id = ${GREEN}$telegram_chat_id${NC}" && sleep 1	
			fi
			echo -e ""
		fi
	fi
}
function install_packages() {
	echo -e "${ARROW} ${YELLOW}Installing Packages...${NC}"
	if [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
		sudo apt-get install dirmngr apt-transport-https -y > /dev/null 2>&1
	fi
	if ! dirmngr --v > /dev/null 2>&1; then
		sudo apt install dirmngr -y > /dev/null 2>&1
	fi
	sudo apt-get install software-properties-common ca-certificates -y > /dev/null 2>&1
	sudo apt-get update -y > /dev/null 2>&1
	sudo apt-get --with-new-pkgs upgrade -y > /dev/null 2>&1
	sudo apt-get install nano htop pwgen ufw figlet tmux jq zip gzip pv unzip git -y > /dev/null 2>&1
	sudo apt-get install build-essential libtool pkg-config -y > /dev/null 2>&1
	sudo apt-get install libc6-dev m4 g++-multilib -y > /dev/null 2>&1
	sudo apt-get install autoconf ncurses-dev python python-zmq -y > /dev/null 2>&1
	sudo apt-get install wget curl bc bsdmainutils automake fail2ban -y > /dev/null 2>&1
	sudo apt-get remove sysbench -y > /dev/null 2>&1
	echo -e "${ARROW} ${YELLOW}Packages complete...${NC}"
}
function pm2_install(){
	tmux kill-server > /dev/null 2>&1 && sleep 1
	echo -e "${ARROW} ${CYAN}PM2 installing...${NC}"
	npm install pm2@latest -g > /dev/null 2>&1
	if pm2 -v > /dev/null 2>&1; then
		rm restart_zelflux.sh > /dev/null 2>&1
		echo -e "${ARROW} ${CYAN}Configuring PM2...${NC}"
		pm2 startup systemd -u $USER > /dev/null 2>&1
		sudo env PATH=$PATH:/home/$USER/.nvm/versions/node/$(node -v)/bin pm2 startup systemd -u $USER --hp /home/$USER > /dev/null 2>&1
		pm2 start ~/$FLUX_DIR/start.sh --name flux > /dev/null 2>&1
		pm2 save > /dev/null 2>&1
		pm2 install pm2-logrotate > /dev/null 2>&1
		pm2 set pm2-logrotate:max_size 6M > /dev/null 2>&1
		pm2 set pm2-logrotate:retain 6 > /dev/null 2>&1
		pm2 set pm2-logrotate:compress true > /dev/null 2>&1
		pm2 set pm2-logrotate:workerInterval 3600 > /dev/null 2>&1
		pm2 set pm2-logrotate:rotateInterval '0 12 * * 0' > /dev/null 2>&1
		source ~/.bashrc
		string_limit_check_mark "PM2 v$(pm2 -v) installed....................................................." "PM2 ${GREEN}v$(pm2 -v)${CYAN} installed....................................................." 
		PM2_INSTALL="1"
	else
		string_limit_x_mark "PM2 was not installed....................................................."
		echo
	fi 
}
function finalizing() {
	cd
	pm2 start /home/$USER/$FLUX_DIR/start.sh --max-memory-restart 1500M --restart-delay 30000 --max-restarts 40 --name flux --time  > /dev/null 2>&1
	pm2 save > /dev/null 2>&1
	#sleep 120
	#cd /home/$USER/zelflux
	#pm2 stop flux
	#npm install --legacy-peer-deps > /dev/null 2>&1
	#pm2 start flux 
	#cd
	NUM='300'
	MSG1='Finalizing Flux installation please be patient this will take about ~5min...'
	MSG2="${CYAN}.............[${CHECK_MARK}${CYAN}]${NC}"
	echo && spinning_timer
	echo 
	
	if [[ "$gateway_ip" != "" && "$upnp_port" != "" ]] && [[ "$upnp_port" != "null" ]] ; then
	  error_check=$(tail -n10 /home/$USER/.pm2/logs/flux-out.log | grep "UPnP failed")
          if [[ "$error_check" != "" ]]; then
	    echo -e "${WORNING} ${RED}Problem with UPnP detected, FluxOS Shutting down...${NC}"
	    echo -e ""
	  fi
	fi
	
	$BENCH_CLI restartnodebenchmarks  > /dev/null 2>&1
	NUM='300'
	MSG1='Restarting benchmark...'
	MSG2="${CYAN}.............[${CHECK_MARK}${CYAN}]${NC}"
	spinning_timer
	echo && echo		
	echo -e "${BOOK}${YELLOW} Flux benchmarks:${NC}"
	echo -e "${YELLOW}======================${NC}"
	bench_benchmarks=$($BENCH_CLI getbenchmarks)
	if [[ "bench_benchmarks" != "" ]]; then
		bench_status=$(jq -r '.status' <<< "$bench_benchmarks")
		if [[ "$bench_status" == "failed" ]]; then
			echo -e "${ARROW} ${CYAN}Flux benchmark failed...............[${X_MARK}${CYAN}]${NC}"
			check_benchmarks "eps" "89.99" " CPU speed" "< 90.00 events per second"
			check_benchmarks "ddwrite" "159.99" " Disk write speed" "< 160.00 events per second"
		else
			echo -e "${BOOK}${CYAN} STATUS: ${GREEN}$bench_status${NC}"
			bench_cores=$(jq -r '.cores' <<< "$bench_benchmarks")
			echo -e "${BOOK}${CYAN} CORES: ${GREEN}$bench_cores${NC}"
			bench_ram=$(jq -r '.ram' <<< "$bench_benchmarks")
			bench_ram=$(round "$bench_ram" 2)
			echo -e "${BOOK}${CYAN} RAM: ${GREEN}$bench_ram${NC}"
			bench_ssd=$(jq -r '.ssd' <<< "$bench_benchmarks")
			bench_ssd=$(round "$bench_ssd" 2)
			echo -e "${BOOK}${CYAN} SSD: ${GREEN}$bench_ssd${NC}"
			bench_hdd=$(jq -r '.hdd' <<< "$bench_benchmarks")
			bench_hdd=$(round "$bench_hdd" 2)
			echo -e "${BOOK}${CYAN} HDD: ${GREEN}$bench_hdd${NC}"
			bench_ddwrite=$(jq -r '.ddwrite' <<< "$bench_benchmarks")
			bench_ddwrite=$(round "$bench_ddwrite" 2)
			echo -e "${BOOK}${CYAN} DDWRITE: ${GREEN}$bench_ddwrite${NC}"
			bench_eps=$(jq -r '.eps' <<< "$bench_benchmarks")
			bench_eps=$(round "$bench_eps" 2)
			echo -e "${BOOK}${CYAN} EPS: ${GREEN}$bench_eps${NC}"
		fi
	else
		echo -e "${ARROW} ${CYAN}Flux benchmark not responding.................[${X_MARK}${CYAN}]${NC}"
	fi
}
function zk_params() {
	echo -e "${ARROW} ${YELLOW}Installing zkSNARK params...${NC}"
	bash flux-fetch-params.sh > /dev/null 2>&1 && sleep 2
	sudo chown -R $USER:$USER /home/$USER  > /dev/null 2>&1
}
function flux_package() {
	sudo apt-get update -y > /dev/null 2>&1 && sleep 2
	echo -e "${ARROW} ${YELLOW}Flux Daemon && Benchmark installing...${NC}"
	DEBIAN_FRONTEND=noninteractive sudo apt-get --yes install $COIN_NAME $BENCH_NAME > /dev/null 2>&1 && sleep 2
	sudo chmod 755 $COIN_PATH/* > /dev/null 2>&1 && sleep 2
	integration_check
}
function create_service_scripts() {
 echo -e "${ARROW} ${YELLOW}Creating Flux daemon service scripts...${NC}" && sleep 1
 sudo touch /home/$USER/start_daemon_service.sh
 sudo chown $USER:$USER /home/$USER/start_daemon_service.sh
 cat <<-'EOF' > /home/$USER/start_daemon_service.sh
	#!/bin/bash
	#color codes
	RED='\033[1;31m'
	CYAN='\033[1;36m'
	NC='\033[0m'
	#emoji codes
	BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
	WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
	directory="/usr/local/bin"
	current_user="$USER"
	sleep 2
	# Check if the directory exists
  if [ -d "$directory" ]; then
      echo "Checking for files in $directory..."
      # Use find to search for all files in the directory
      all_files=$(find "$directory" -maxdepth 1)
      if [ -n "$all_files" ]; then
          # Identify files not owned by the current user
          non_user_files=$(find "$directory" -maxdepth 1 ! -user "$current_user")
          if [ -n "$non_user_files" ]; then
              echo "Files not owned by $current_user found:"
              echo "$non_user_files"
              # Change ownership of non-user files to the current user
              echo "Changing ownership to $current_user..."
              sudo chown "$current_user":"$current_user" $non_user_files
              echo "Ownership changed successfully."
          else
              echo "All files are owned by $current_user."
          fi
      else
          echo "No files found in $directory."
      fi
  else
      echo "Directory $directory does not exist."
  fi
	echo -e "${BOOK} ${CYAN}Pre-start process starting...${NC}"
	echo -e "${BOOK} ${CYAN}Checking if benchmark or daemon is running${NC}"
	bench_status_pind=$(pgrep fluxbenchd)
	daemon_status_pind=$(pgrep fluxd)
	if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
	  echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
	else
	  if [[ "$bench_status_pind" != "" ]]; then
		echo -e "${WORNING} Running benchmark process detected${NC}"
		echo -e "${WORNING} Killing benchmark...${NC}"
		sudo killall -9 fluxbenchd > /dev/null 2>&1  && sleep 2
	  fi
	  if [[ "$daemon_status_pind" != "" ]]; then
		echo -e "${WORNING} Running daemon process detected${NC}"
		echo -e "${WORNING} Killing daemon...${NC}"
		sudo killall -9 fluxd > /dev/null 2>&1  && sleep 2
	  fi
	  sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
	fi
	bench_status_pind=$(pgrep zelbenchd)
	daemon_status_pind=$(pgrep zelcashd)
	if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
	  echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
	else
	  if [[ "$bench_status_pind" != "" ]]; then
		echo -e "${WORNING} Running benchmark process detected${NC}"
		echo -e "${WORNING} Killing benchmark...${NC}"
		sudo killall -9 zelbenchd > /dev/null 2>&1  && sleep 2
	  fi
	  if [[ "$daemon_status_pind" != "" ]]; then
		echo -e "${WORNING} Running daemon process detected${NC}"
		echo -e "${WORNING} Killing daemon...${NC}"
		sudo killall -9 zelcashd > /dev/null 2>&1  && sleep 2
	  fi
	  sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
  fi
  if [[ -f /usr/local/bin/fluxd ]]; then
	bash -c "fluxd"
	 exit
  else
	  bash -c "zelcashd"
	  exit
  fi
	EOF
	sudo touch /home/$USER/stop_daemon_service.sh
	sudo chown $USER:$USER /home/$USER/stop_daemon_service.sh
	cat <<-'EOF' > /home/$USER/stop_daemon_service.sh
	#!/bin/bash
	if [[ -f /usr/local/bin/flux-cli ]]; then
	   bash -c "flux-cli stop"
	else
	   bash -c "zelcash-cli stop"
	fi
	exit
	EOF
	sudo chmod +x /home/$USER/stop_daemon_service.sh
	sudo chmod +x /home/$USER/start_daemon_service.sh
}
function create_service() {
	if [[ "$1" != "install" ]]; then
		echo -e "${GREEN}Module: Flux Daemon service creator${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
			echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
			echo -e "${CYAN}Please switch to the user account.${NC}"
			echo -e "${YELLOW}================================================================${NC}"
			echo -e "${NC}"
			exit
		fi 
		echo -e ""
		echo -e "${ARROW} ${CYAN}Cleaning...${NC}" && sleep 1
		sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
		sudo rm -rf /home/$USER/start_daemon_service.sh > /dev/null 2>&1  
		sudo rm -rf /home/$USER/stop_daemon_service.sh > /dev/null 2>&1 
		sudo rm -rf /home/$USER/start_zelcash_service.sh > /dev/null 2>&1  
		sudo rm -rf /home/$USER/stop_zelcash_service.sh > /dev/null 2>&1 
		sudo rm -rf /etc/systemd/system/zelcash.service > /dev/null 2>&1
	fi
	echo -e "${ARROW} ${YELLOW}Creating Flux daemon service...${NC}" && sleep 1
	sudo touch /etc/systemd/system/zelcash.service
	sudo chown $USER:$USER /etc/systemd/system/zelcash.service
	cat <<-EOF > /etc/systemd/system/zelcash.service
		[Unit]
		Description=Flux daemon service
		After=network.target
		[Service]
		Type=forking
		User=$USER
		Group=$USER
		ExecStart=/home/$USER/start_daemon_service.sh
		ExecStop=-/home/$USER/stop_daemon_service.sh
		Restart=always
		RestartSec=10
		PrivateTmp=true
		TimeoutStopSec=60s
		TimeoutStartSec=15s
		StartLimitInterval=120s
		StartLimitBurst=5
		[Install]
		WantedBy=multi-user.target
	EOF
	sudo chown root:root /etc/systemd/system/zelcash.service
	sudo systemctl daemon-reload
}
#### LOGS SECTION
function log_rotate() {
	echo -e "${ARROW} ${YELLOW}Configuring log rotate function for $1 logs...${NC}"
	sleep 1
	if [ -f /etc/logrotate.d/$2 ]; then
		sudo rm -rf /etc/logrotate.d/$2
		sleep 1
	fi
	sudo touch /etc/logrotate.d/$2
	sudo chown $USER:$USER /etc/logrotate.d/$2
	cat <<-EOF > /etc/logrotate.d/$2
	$3 {
	compress
	copytruncate
	missingok
	$4
	rotate $5
	}
	EOF
	sudo chown root:root /etc/logrotate.d/$2
}
#### UPnP
function upnp_enable() {
  if [[ -d $HOME/.fluxbenchmark ]]; then
    sudo chown -R $USER:$USER $HOME/.fluxbenchmark > /dev/null 2>&1
  fi
	try="0"
	echo -e ""
	echo -e "${ARROW}${YELLOW} Creating UPnP configuration...${NC}"
	if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
		echo -e "${WORNING} ${CYAN}Missing FluxOS configuration file - install/re-install Flux Node...${NC}" 
		echo -e ""
		return
	fi
	while true
	do
		echo -e "${ARROW}${CYAN} Checking port validation.....${NC}"
		# Check if upnp_port is set
		if [[ -z "$upnp_port" ]]; then
			FLUX_PORT=$(whiptail --inputbox "Enter your FluxOS port (Ports allowed are: 16127, 16137, 16147, 16157, 16167, 16177, 16187, 16197)" 8 80 3>&1 1>&2 2>&3)
		else
			FLUX_PORT="$upnp_port"
		fi
		if [[ $FLUX_PORT == "16127" || $FLUX_PORT == "16137" || $FLUX_PORT == "16147" || $FLUX_PORT == "16157" || $FLUX_PORT == "16167" || $FLUX_PORT == "16177" || $FLUX_PORT == "16187" || $FLUX_PORT == "16197" ]]; then
			string_limit_check_mark "Port is valid..........................................."
			break
		else
			string_limit_x_mark "Port $FLUX_PORT is not allowed..............................."
			sleep 1
			try=$(($try+1))
			if [[ "$try" -gt "3" ]]; then
				echo -e "${WORNING} ${CYAN}You have reached the maximum number of attempts...${NC}" 
				echo -e ""
				exit
			fi
		fi
	done
	#if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep "apiport") != "" ]]; then
		#sed -i "s/$(grep -e apiport /home/$USER/zelflux/config/userconfig.js)/apiport: '$FLUX_PORT',/" /home/$USER/zelflux/config/userconfig.js
		#if [[ $(grep -w $FLUX_PORT /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
			#echo -e "${ARROW} ${CYAN}FluxOS port replaced successfully...................[${CHECK_MARK}${CYAN}]${NC}"
		#fi
	#else
		#insertAfter "/home/$USER/zelflux/config/userconfig.js" "zelid" "apiport: '$FLUX_PORT',"
		#echo -e "${ARROW} ${CYAN}FluxOS port set successfully........................[${CHECK_MARK}${CYAN}]${NC}"
	#fi
	config_builder "apiport" "$FLUX_PORT" "MultiPort Mode" "fluxos"
	if [[ ! -d /home/$USER/.fluxbenchmark ]]; then
		sudo mkdir -p /home/$USER/.fluxbenchmark 2>/dev/null
		config_builder "fluxport" "$FLUX_PORT" "MultiPort Mode" "benchmark"
	else
		config_builder "fluxport" "$FLUX_PORT" "MultiPort Mode" "benchmark"
	fi
	if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
		#API PORT
		sudo ufw allow $FLUX_PORT > /dev/null 2>&1
		#HOME UI PORT
		sudo ufw allow $(($FLUX_PORT-1)) > /dev/null 2>&1
		#if ! route -h > /dev/null 2>&1 ; then
		# sudo apt install net-tools > /dev/null 2>&1
		#fi  
		#router_ip=$(route -n | sed -nr 's/(0\.0\.0\.0) +([^ ]+) +\1.*/\2/p' 2>/dev/null)
		if [[ -z "$gateway_ip" ]]; then
			router_ip=$(ip rout | head -n1 | awk '{print $3}' 2>/dev/null)
		else
			router_ip="$gateway_ip"
		fi
		if [[ "$router_ip" != "" ]]; then
			if [[ -z "$gateway_ip" ]]; then
				if (whiptail --yesno "Is your router's IP $router_ip ?" 8 70); then
					is_correct="0"
				fi
			else
				is_correct="0"
			fi
			if [[ "$is_correct" == "0" ]]; then
        config_builder "routerIP" "$router_ip" "RouterIP" "fluxos"
				sudo ufw allow out from any to 239.255.255.250 port 1900 proto udp > /dev/null 2>&1
				sudo ufw allow from $router_ip port 1900 to any proto udp > /dev/null 2>&1
				sudo ufw allow out from any to $router_ip proto tcp > /dev/null 2>&1
				sudo ufw allow from $router_ip to any proto udp > /dev/null 2>&1
			else
				while true  
				do
					
					router_ip=$(whiptail --inputbox "Enter your router's IP" 8 60 3>&1 1>&2 2>&3)
	
					if [[ "$router_ip" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
						echo -e "${ARROW} ${CYAN}IP $router_ip format is valid........................[${CHECK_MARK}${CYAN}]${NC}"
						break
					else
						string_limit_x_mark "IP $router_ip is not valid ..............................."
						sleep 1
					fi
			
				done
        config_builder "routerIP" "$router_ip" "RouterIP" "fluxos"
				sudo ufw allow out from any to 239.255.255.250 port 1900 proto udp > /dev/null 2>&1
				sudo ufw allow from $router_ip port 1900 to any proto udp > /dev/null 2>&1
				sudo ufw allow out from any to $router_ip proto tcp > /dev/null 2>&1
				sudo ufw allow from $router_ip to any proto udp > /dev/null 2>&1
			fi
		else
			while true  
			do
					router_ip=$(whiptail --inputbox "Enter your router's IP" 8 60 3>&1 1>&2 2>&3)
					if [[ "$router_ip" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
						echo -e "${ARROW} ${CYAN}IP $router_ip format is valid........................[${CHECK_MARK}${CYAN}]${NC}"
						break
					else
						string_limit_x_mark "IP $router_ip is not valid ..............................."
						sleep 1
					fi
			done
      config_builder "routerIP" "$router_ip" "RouterIP" "fluxos"
			sudo ufw allow out from any to 239.255.255.250 port 1900 proto udp > /dev/null 2>&1
			sudo ufw allow from $router_ip port 1900 to any proto udp > /dev/null 2>&1
			sudo ufw allow out from any to $router_ip proto tcp > /dev/null 2>&1
			sudo ufw allow from $router_ip to any proto udp > /dev/null 2>&1
		fi
	fi
	if [[ "$1" != "install" ]]; then
		echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark.....${NC}"
		sudo systemctl restart zelcash  > /dev/null 2>&1
		pm2 restart flux  > /dev/null 2>&1
		sleep 150
		echo -e "${ARROW}${CYAN} Checking FluxOS logs... ${NC}"
		error_check=$(tail -n10 /home/$USER/.pm2/logs/flux-out.log | grep "UPnP failed")
		if [[ "$error_check" == "" ]]; then
			echo -e ""
			LOCAL_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
			ZELFRONTPORT=$(($FLUX_PORT-1))
			echo -e "${PIN} ${CYAN}To access your FluxOS use this url: ${SEA}http://${LOCAL_IP}:$ZELFRONTPORT${NC}"
			echo -e ""
		else
			echo -e "${WORNING} ${RED}Problem with UPnP detected, FluxOS Shutting down...${NC}"
			echo -e ""
		fi
	else
			LOCAL_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
			ZELFRONTPORT=$(($FLUX_PORT-1))
	fi
}
#### TESTNET
function testnet_binary(){
	sudo rm -rf  /tmp/*lux* 2>&1 && sleep 2
	if [[ $(dpkg --print-architecture) = *amd* ]]; then
	  #DAEMON
		sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Flux-Linux-halving.tar.gz -P /tmp > /dev/null 2>&1
		sudo tar xzvf /tmp/Flux-Linux-halving.tar.gz -C /tmp  > /dev/null 2>&1
		sudo mv /tmp/fluxd /usr/local/bin > /dev/null 2>&1
		sudo mv /tmp/flux-cli /usr/local/bin > /dev/null 2>&1
    #BENCHMARK
		sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Fluxbench-Linux-v3.3.0.tar.gz -P /tmp > /dev/null 2>&1
		sudo tar xzvf /tmp/Fluxbench-Linux-v3.3.0.tar.gz -C /tmp > /dev/null 2>&1
		sudo mv /tmp/fluxbenchd /usr/local/bin > /dev/null 2>&1
		sudo mv /tmp/fluxbench-cli /usr/local/bin > /dev/null 2>&1
	else
		#DAEMON
		sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Flux-arm64-halving.tar.gz -P /tmp > /dev/null 2>&1
		sudo tar xzvf /tmp/Flux-arm64-halving.tar.gz -C /tmp  > /dev/null 2>&1
		sudo mv /tmp/fluxd /usr/local/bin > /dev/null 2>&1
		sudo mv /tmp/flux-cli /usr/local/bin > /dev/null 2>&1
		#BENCHMARK
		sudo wget https://github.com/RunOnFlux/fluxd/releases/download/halving-test-2/Fluxbench-arm-v3.3.0.tar.gz -P /tmp > /dev/null 2>&1
		sudo tar xzvf /tmp/Fluxbench-arm-v3.3.0.tar.gz -C /tmp > /dev/null 2>&1
		sudo mv /tmp/fluxbenchd /usr/local/bin > /dev/null 2>&1
		sudo mv /tmp/fluxbench-cli /usr/local/bin > /dev/null 2>&1
	fi
	sudo chmod 755 $COIN_PATH/* > /dev/null 2>&1 && sleep 2
}
#### MULTITOOLBOX OPTIONS SECTION
function selfhosting_creator(){

	echo -e "${GREEN}Module: Self-hosting ip cron service${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	echo -e ""
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
	fi

	CHOICE=$(
	whiptail --title "FluxOS Selfhosting Configuration" --menu "Make your choice" 15 40 6 \
	"1)" "Auto Detection (Recommended)"   \
	"2)" "Manual Configuration (Advance)"   \
	"3)" "Removing service"  3>&2 2>&1 1>&3
		)
			case $CHOICE in
			"1)")
			  echo -e "${ARROW} ${YELLOW}Creating cron service for ip rotate...${NC}"
			  if [[ -f /home/$USER/device_conf.json ]]; then
				  sudo rm -rf /home/$USER/device_conf.json
					echo -e "${ARROW} ${CYAN}Removing config file, path: ${GREEN}/home/$USER/device_conf.json${NC}"	
				fi
				selfhosting
			;;
			"2)")
			  echo -e "${ARROW} ${YELLOW}Creating cron service for ip rotate.....${NC}"
				#device_setup=$(whiptail --inputbox "Enter your device name" 8 60 3>&1 1>&2 2>&3)
				deviceList=($(sudo route -n |  awk '{ if ($8 != "" && $8 != "Iface" && $8 != "docker0" ) printf("%s\n", $8); }' | uniq))
				elements=${#deviceList[@]}
				choices=();
				for (( i=0;i<$elements;i++)); do
					if [[ "$i"  == "0" ]]; then
						choices+=("${deviceList[i]}" "" "ON");
					else
						choices+=("${deviceList[i]}" "" "OFF");
					fi
				done;
				device_setup=$(
						whiptail --title " SELECT YOUR DEVICE INTERFACE "         \
										--radiolist " \n Use the UP/DOWN arrows to highlight the device name you want. Press Spacebar on the device name you want to select, THEN press ENTER." 25 55 10 \
										"${choices[@]}" \
										3>&2 2>&1 1>&3
				);
				if [[ "$device_setup" != "" ]]; then
					if [[ ! -f /home/$USER/device_conf.json ]]; then 
						echo "{}" > device_conf.json 
					fi 
					echo "$(jq -r --arg value "$device_setup" '.device_name=$value' device_conf.json)" > device_conf.json
					echo -e "${ARROW} ${CYAN}Config created successful, path: ${SEA}/home/$USER/device_conf.json${CYAN}, device name: ${GREEN}$device_setup${NC}"
				else
					echo -e "${ARROW} ${CYAN}Operation aborted, device interface was not selected...${NC}"
					echo -e ""
					exit
				fi
				selfhosting
			;;
			"3)")
			echo -e "${ARROW} ${YELLOW}Disabling cron service for IP rotate...${NC}"
			echo -e "${ARROW} ${CYAN}Removing cron jobs...${NC}"
			crontab -u $USER -l | grep -v 'ip_check'  | crontab -u $USER -
			echo -e "${ARROW} ${CYAN}Removing of files related to IP rotation...${NC}"
			rm -rf /home/$USER/device_conf.json > /dev/null 2>&1
			rm -rf /home/$USER/ip_check.sh > /dev/null 2>&1
			echo -e ""
		esac
}

function selfhosting() {
	if [[ "$1" == "install" ]]; then
		echo -e "${ARROW} ${YELLOW}Creating cron service for ip rotate...${NC}"
	fi

	echo -e "${ARROW} ${CYAN}Adding IP for device...${NC}" && sleep 1
	if [[ "$1" != "install" ]]; then
		get_ip
	fi

	if [[ -z "$device_setup" ]]; then
		device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
		if [[ "$device_name" != "" ]]; then
			echo -e "${ARROW} ${CYAN}Device auto detection, name: ${GREEN}$device_name ${NC}"
		fi
	else
   		 device_name="$device_setup"
	fi

	if [[ "$device_name" != "" && "$WANIP" != "" ]]; then
	  echo -e "${ARROW} ${CYAN}Detected IP: ${GREEN}$WANIP ${NC}"
		sudo ip addr add $WANIP dev $device_name > /dev/null 2>&1
	else
		echo -e "${WORNING} ${CYAN}Problem detected operation aborted! ${NC}" && sleep 1
		echo -e ""
		return 1
	fi
	echo -e "${ARROW} ${CYAN}Creating IP check script...${NC}" && sleep 1
	sudo rm /home/$USER/ip_check.sh > /dev/null 2>&1
	sudo touch /home/$USER/ip_check.sh
	sudo chown $USER:$USER /home/$USER/ip_check.sh
	cat <<-'EOF' > /home/$USER/ip_check.sh
	#!/bin/bash

	function get_ip(){
	WANIP=$(curl --silent -m 10 https://api4.my-ip.io/ip | tr -dc '[:alnum:].')
	if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
	  WANIP=$(curl --silent -m 10 https://checkip.amazonaws.com | tr -dc '[:alnum:].')    
	fi    
	if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
	  WANIP=$(curl --silent -m 10 https://api.ipify.org | tr -dc '[:alnum:].')
	fi
	}

	function get_device_name(){
		if [[ -f /home/$USER/device_conf.json ]]; then
			device_name=$(jq -r .device_name /home/$USER/device_conf.json)
		else
			device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
		fi
	}

	if [[ $1 == "restart" ]]; then
	  #give 3min to connect with internet
	  sleep 180
		get_ip
		get_device_name
	  if [[ "$device_name" != "" && "$WANIP" != "" ]]; then
		date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
		echo -e "New IP detected during $1, IP: $WANIP was added to $device_name at $date_timestamp" >> /home/$USER/ip_history.log
		sudo ip addr add $WANIP dev $device_name && sleep 2
	  fi
	fi
	if [[ $1 == "ip_check" ]]; then
	  get_ip
	  get_device_name
	  api_port=$(grep -w apiport /home/$USER/zelflux/config/userconfig.js | grep -o '[[:digit:]]*')
	  if [[ "$api_port" == "" ]]; then
		api_port="16127"
	  fi
	  confirmed_ip=$(curl -SsL -m 10 http://localhost:$api_port/flux/info 2>/dev/null | jq -r .data.node.status.ip | sed -r 's/:.+//')
	  if [[ "$WANIP" != "" && "$confirmed_ip" != "" && "$confirmed_ip" != "null" ]]; then
		 if [[ "$WANIP" != "$confirmed_ip" ]]; then
			date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
			echo -e "New IP detected during $1, IP: $WANIP was added to $device_name at $date_timestamp" >> /home/$USER/ip_history.log
			sudo ip addr add $WANIP dev $device_name && sleep 2
		 fi
	  fi
	fi
	EOF
	sudo chmod +x /home/$USER/ip_check.sh
	sudo [ -f /var/spool/cron/crontabs/$USER ] && crontab_check=$(sudo cat /var/spool/cron/crontabs/$USER | grep -o ip_check | wc -l) || crontab_check=0
	
	if [[ "$crontab_check" != "0" ]]; then
	  echo -e "${ARROW} ${CYAN}Removing old cron jobs...${NC}"
	  crontab -u $USER -l | grep -v 'ip_check'  | crontab -u $USER -
	fi
	
	echo -e "${ARROW} ${CYAN}Adding cron jobs...${NC}" && sleep 1
	(crontab -l -u "$USER" 2>/dev/null; echo "@reboot env USER=\$LOGNAME \$HOME/ip_check.sh restart") | crontab -
	(crontab -l -u "$USER" 2>/dev/null; echo "*/15 * * * * env USER=\$LOGNAME \$HOME/ip_check.sh ip_check") | crontab -
	echo -e "${ARROW} ${CYAN}Script installed! ${NC}" 
	echo -e "" 
}
function multinode(){
	echo -e "${GREEN}Module: Multinode configuration with UPNP communication (Needs Router with UPNP support)${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
	fi
	echo -e ""
	echo -e "${ARROW}  ${CYAN}OPTION ALLOWS YOU: ${NC}"
	echo -e "${HOT} ${CYAN}Run node as selfhosting with upnp communication ${NC}"
	echo -e "${HOT} ${CYAN}Create up to 8 node using same public address ${NC}"
	echo -e ""
	echo -e "${ARROW}  ${RED}IMPORTANT:${NC}"
	echo -e "${BOOK} ${RED}Each node need to set different port for communication${NC}"
	echo -e "${BOOK} ${RED}If FluxOs fails to communicate with router or upnp fails it will shutdown FluxOS... ${NC}"
	echo -e ""
	echo -e "${YELLOW}================================================================${NC}"
	if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
	  echo -e ""
		echo -e "${WORNING} ${CYAN}First install FluxNode...${NC}"
		echo -e "${WORNING} ${CYAN}Operation stopped...${NC}"
		echo -e ""
		exit
	fi  
	sleep 8
	bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/multinode.sh)
}
function install_watchtower(){
	echo -e "${GREEN}Module: Install flux_watchtower for docker images autoupdate${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
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
function analyzer_and_fixer(){
	echo -e "${GREEN}Module: FluxNode analyzer and fixer${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
		echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
		echo -e "${CYAN}Please switch to the user account.${NC}"
		echo -e "${YELLOW}================================================================${NC}"
		echo -e "${NC}"
		exit
	fi
	bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/nodeanalizerandfixer.sh)
}
