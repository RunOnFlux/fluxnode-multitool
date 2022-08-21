#!/bin/bash

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

#bootstrap settings
BOOTSTRAP_ZIPFILE='flux_explorer_bootstrap.tar.gz'

#dialog color
export NEWT_COLORS='
title=black,
'

#echo -e "${ARROW} ${CYAN}Importing Common Multitoolbox Resources..."


function round() {
  printf "%.${2}f" "${1}"
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

function bootstrap_server(){
    rand_by_domain=("5" "6" "7" "8" "9" "10" "11" "12")
    richable=()
    richable_eu=()
    richable_us=()
    richable_as=()

    i=0
    len=${#rand_by_domain[@]}
    echo -e "${ARROW} ${CYAN}Checking servers availability... ${NC}"
    while [ $i -lt $len ];
    do
        bootstrap_check=$(curl -sSL -m 10 http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.json 2>/dev/null | jq -r '.block_height' 2>/dev/null)
        if [[ "$bootstrap_check" != "" ]]; then

            if [[ "${rand_by_domain[$i]}" -ge "8" && "${rand_by_domain[$i]}" -le "11" ]]; then
                richable_eu+=( ${rand_by_domain[$i]}  )
            fi

            if [[ "${rand_by_domain[$i]}" -gt "4" &&  "${rand_by_domain[$i]}" -le "7" ]]; then
                richable_us+=( ${rand_by_domain[$i]}  )
            fi

            if [[ "${rand_by_domain[$i]}" -ge "12" ]]; then
                richable_as+=( ${rand_by_domain[$i]}  )
            fi

            richable+=( ${rand_by_domain[$i]} )
        fi

        i=$(($i+1))
    done

    server_found="1"
    if [[ "$continent" == "EU" ]]; then
        len_eu=${#richable_eu[@]}
        if [[ "$len_eu" -gt "0" ]]; then
            richable=( ${richable_eu[*]} )
            echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
        fi
        if [[ "$len_eu" == "0" ]]; then
            continent="EU"
            echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
            len_us=${#richable_us[@]}
            if [[ "$len_us" -gt "0" ]]; then
                richable=( ${richable_us[*]} )
                echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
            fi
            if [[ "$len_us" == "0" ]]; then
                continent="US"
                echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
                server_found="0"
            fi
        fi
    elif [[ "$continent" == "US" ]]; then
        len_us=${#richable_us[@]}
        if [[ "$len_us" -gt "0" ]]; then
            richable=( ${richable_us[*]} )
            echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
        fi
        if [[ "$len_us" == "0" ]]; then
            continent="US"
            echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
            len_as=${#richable_as[@]}
            if [[ "$len_as" -gt "0" ]]; then
                richable=( ${richable_as[*]} )
                echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
            fi
            if [[ "$len_as" == "0" ]]; then
                continent="AS"
                echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
                len_eu=${#richable_eu[@]}
                if [[ "$len_eu" -gt "0" ]]; then
                    richable=( ${richable_eu[*]} )
                    echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
                fi
                if [[ "$len_eu" == "0" ]]; then
                    continent="EU"
                    echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
                    server_found="0"
                fi
            fi
        fi
    elif [[ "$continent" == "AS" ]]; then
        len_as=${#richable_as[@]}
        if [[ "$len_as" -gt "0" ]]; then
            richable=( ${richable_as[*]} )
            echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
        fi
        if [[ "$len_as" == "0" ]]; then
            continent="AS"
            echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
            len_us=${#richable_us[@]}
            if [[ "$len_us" -gt "0" ]]; then
                richable=( ${richable_us[*]} )
                echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
            fi
            if [[ "$len_us" == "0" ]]; then
                continent="US"
                echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
                len_eu=${#richable_eu[@]}
            if [[ "$len_eu" -gt "0" ]]; then
                richable=( ${richable_eu[*]} )
                echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
            fi
            if [[ "$len_eu" == "0" ]]; then
                continent="EU"
                echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
                server_found="0"
            fi
        fi
    fi
    else
        len=${#richable[@]}
        if [[ "$len" -gt "0" ]]; then
            richable=( ${richable[*]} )
            echo -e "${ARROW} ${CYAN}Reachable servers: ${richable[*]}${NC}"
        fi
    
        if [[ "$len" == "0" ]]; then
            Server_offline=1
            return 1
        fi
    fi

    if [[ "$server_found" == "0" ]]; then
        len=${#richable[@]}
        if [[ "$len" == "0" ]]; then
            Server_offline=1
            return 1
        fi
    fi

    Server_offline=0
}

function bootstrap_geolocation(){
    IP=$WANIP
    ip_output=$(curl -s -m 10 http://ip-api.com/json/$1?fields=status,country,timezone 2>/dev/null | jq . 2>/dev/null)
    ip_status=$( jq -r .status 2>/dev/null <<< "$ip_output")

    if [[ "$ip_status" == "success" ]]; then
        country=$(jq -r .country <<< "$ip_output")
        org=$(jq -r .org <<< "$ip_output")
        continent=$(jq -r .timezone <<< "$ip_output")
    else
        country="UKNOW"
        continent="UKNOW"
    fi

    continent=$(cut -f1 -d"/" <<< "$continent" )

    if [[ "$continent" =~ "Europe" ]]; then
        continent="EU"
    elif [[ "$continent" =~ "America" ]]; then
        continent="US"
    elif [[ "$continent" =~ "Asia" ]]; then
        continent="AS"
    else
        continent="ALL"
    fi

    echo -e "${ARROW} ${CYAN}Selecting bootstrap server....${NC}"
    echo -e "${ARROW} ${CYAN}Node Location -> IP:$IP, Country: $country, Continent: $continent ${NC}"
    echo -e "${ARROW} ${CYAN}Searching in $continent....${NC}"
    bootstrap_server $continent
}

function get_ip(){
    WANIP=$(curl -SsL -m 5 https://api4.my-ip.io/ip 2>/dev/null | tr -dc '[:alnum:].')

    if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
        WANIP=$(curl -SsL -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -dc '[:alnum:].')
    fi

    if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
        WANIP=$(curl -SsL -m 5 https://api.ipify.org 2>/dev/null | tr -dc '[:alnum:].')
    fi
}

function selfhosting() {
  
    echo -e "${ARROW} ${YELLOW}Creating cron service for ip rotate...${NC}"
    echo -e "${ARROW} ${CYAN}Adding IP for device...${NC}" && sleep 1
    #added call to get_ip function - when calling option 10 this wasn't called anywhere else so WANIP is always empty
    get_ip
    device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
    

    if [[ "$device_name" != "" && "$WANIP" != "" ]]; then
        sudo ip addr add $WANIP dev $device_name:0  > /dev/null 2>&1
    else
        echo -e "${WORNING} ${CYAN}Problem detected operation aborted! ${NC}" && sleep 1
        echo -e ""
        return 1
    fi

    echo -e "${ARROW} ${CYAN}Creating ip check script...${NC}" && sleep 1
    sudo rm /home/$USER/ip_check.sh > /dev/null 2>&1
    sudo touch /home/$USER/ip_check.sh
    sudo chown $USER:$USER /home/$USER/ip_check.sh
    cat <<'EOF' > /home/$USER/ip_check.sh
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
if [[ $1 == "restart" ]]; then
  # give 3min to connect with internet
  sleep 180
  get_ip
  device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
  if [[ "$device_name" != "" && "$WANIP" != "" ]]; then
   date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
   echo -e "New IP detected, IP: $WANIP was added at $date_timestamp" >> /home/$USER/ip_history.log
   sudo ip addr add $WANIP dev $device_name:0 && sleep 2
  fi
fi
if [[ $1 == "ip_check" ]]; then
  get_ip
  device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
  api_port=$(grep -w apiport /home/$USER/zelflux/config/userconfig.js | grep -o '[[:digit:]]*')
  if [[ "$api_port" == "" ]]; then
  api_port="16127"
  fi
  confirmed_ip=$(curl -SsL -m 10 http://localhost:$api_port/flux/info | jq -r .data.node.status.ip | sed -r 's/:.+//')
  if [[ "$WANIP" != "" && "$confirmed_ip" != "" ]]; then
    if [[ "$WANIP" != "$confirmed_ip" ]]; then
      date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      echo -e "New IP detected, IP: $WANIP was added at $date_timestamp" >> /home/$USER/ip_history.log
      sudo ip addr add $WANIP dev $device_name:0 && sleep 2
    fi
  fi
fi
EOF
    sudo chmod +x /home/$USER/ip_check.sh
    echo -e "${ARROW} ${CYAN}Adding cron jobs...${NC}" && sleep 1

    #crontab_check=$(sudo cat /var/spool/cron/crontabs/$USER | grep -o ip_check | wc -l)
    sudo [ -f /var/spool/cron/crontabs/$USER ] && crontab_check=$(sudo cat /var/spool/cron/crontabs/$USER | grep -o ip_check | wc -l) || crontab_check=0

    if [[ "$crontab_check" == "0" ]]; then
        (crontab -l -u "$USER" 2>/dev/null; echo "@reboot /home/$USER/ip_check.sh restart") | crontab -
        (crontab -l -u "$USER" 2>/dev/null; echo "*/15 * * * * /home/$USER/ip_check.sh ip_check") | crontab -
        echo -e "${ARROW} ${CYAN}Script installed! ${NC}" 
    else 
        echo -e "${ARROW} ${CYAN}Script installed! ${NC}"
    fi
    echo -e "" 
}


function integration_check() {
    FILE_ARRAY=( 'fluxbench-cli' 'fluxbenchd' 'flux-cli' 'fluxd' 'flux-fetch-params.sh' 'flux-tx' )
    ELEMENTS=${#FILE_ARRAY[@]}

    for (( i=0;i<$ELEMENTS;i++)); do
        string="${FILE_ARRAY[${i}]}................................."
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
        echo
        exit
    fi	
    echo -e ""
}


function config_file() {
    if [[ -f /home/$USER/install_conf.json ]]; then
        import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
        #ssh_port=$(cat /home/$USER/install_conf.json | jq -r '.ssh_port')
        #firewall_disable=$(cat /home/$USER/install_conf.json | jq -r '.firewall_disable')
        bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
        bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
        #swapon=$(cat /home/$USER/install_conf.json | jq -r '.swapon')
        #mongo_bootstrap=$(cat /home/$USER/install_conf.json | jq -r '.mongo_bootstrap')
        #watchdog=$(cat /home/$USER/install_conf.json | jq -r '.watchdog')
        use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
        prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
        outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
        index=$(cat /home/$USER/install_conf.json | jq -r '.index')
        ZELID=$(cat /home/$USER/install_conf.json | jq -r '.zelid')
        KDA_A=$(cat /home/$USER/install_conf.json | jq -r '.kda_address')
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

        echo
        echo -e "${ARROW} ${YELLOW}Install config:"

        if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
            echo -e "${PIN}${CYAN} Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        else
            if [[ "$import_settings" == "1" ]]; then
                echo -e "${PIN}${CYAN} Import settings from Flux........................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
            fi
        fi

        if [[ "$use_old_chain" == "1" ]]; then
            echo -e "${PIN}${CYAN} Diuring re-installation old chain will be use....................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        else
            if [[ "$bootstrap_url" == "0" ]]; then
                echo -e "${PIN}${CYAN} Use Flux daemon bootstrap from source build in scripts...........[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
            else
                echo -e "${PIN}${CYAN} Use Flux daemon bootstrap from own source........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
            fi

            if [[ "$bootstrap_zip_del" == "1" ]]; then
                echo -e "${PIN}${CYAN} Remove Flux daemon bootstrap archive file........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
            else
                echo -e "${PIN}${CYAN} Leave Flux daemon bootstrap archive file.........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
            fi
        fi

        #if [[ "$swapon" == "1" ]]; then
        #echo -e "${PIN}${CYAN} Create a file that will be used for swap.........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        #fi

        #if [[ "$mongo_bootstrap" == "1" ]]; then
        #echo -e "${PIN}${CYAN} Use Bootstrap for MongoDB........................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        #fi

        if [[ "$discord" != "" || "$telegram_alert" == '1' ]]; then
        echo -e "${PIN}${CYAN} Enable watchdog notification.....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        else
        echo -e "${PIN}${CYAN} Disable watchdog notification....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
        fi
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

function tar_file_unpack() {
    echo -e "${ARROW} ${YELLOW}Unpacking bootstrap archive file...${NC}"
    pv $1 | tar -zx -C $2
}


function check_tar() {
    echo -e "${ARROW} ${YELLOW}Checking  bootstrap file integration...${NC}"
    if gzip -t "$1" &>/dev/null; then
        echo -e "${ARROW} ${CYAN}Bootstrap file is valid.................[${CHECK_MARK}${CYAN}]${NC}"
    else
        echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
        rm -rf $1
    fi
}

function tar_file_pack() {
    echo -e "${ARROW} ${YELLOW}Creating bootstrap archive file...${NC}"
    tar -czf - $1 | (pv -p --timer --rate --bytes > $2) 2>&1
}

function flux_package() {
    sudo apt-get update -y > /dev/null 2>&1 && sleep 2
    echo -e "${ARROW} ${YELLOW}Flux Daemon && Benchmark installing...${NC}"
    sudo apt install $COIN_NAME $BENCH_NAME -y > /dev/null 2>&1 && sleep 2
    sudo chmod 755 $COIN_PATH/* > /dev/null 2>&1 && sleep 2
    integration_check
}

function zk_params() {
    echo -e "${ARROW} ${YELLOW}Installing zkSNARK params...${NC}"
    bash flux-fetch-params.sh > /dev/null 2>&1 && sleep 2
    sudo chown -R $USER:$USER /home/$USER  > /dev/null 2>&1
}

function create_oldnode_service_scripts() {
    echo -e "${ARROW} ${YELLOW}Creating Flux daemon service scripts...${NC}" && sleep 1
    sudo touch /home/$USER/start_daemon_service.sh
    sudo chown $USER:$USER /home/$USER/start_daemon_service.sh
    cat <<'EOF' > /home/$USER/start_daemon_service.sh
#!/bin/bash

#color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'then
#emoji codes
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"

sleep 2
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
    cat <<'EOF' > /home/$USER/stop_daemon_service.sh
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
    echo -e "${ARROW} ${YELLOW}Creating Flux daemon service...${NC}" && sleep 1
    sudo touch /etc/systemd/system/zelcash.service
    sudo chown $USER:$USER /etc/systemd/system/zelcash.service
    cat << EOF > /etc/systemd/system/zelcash.service
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


function log_rotate() {
    echo -e "${ARROW} ${YELLOW}Configuring log rotate function for $1 logs...${NC}"
    sleep 1
    if [ -f /etc/logrotate.d/$2 ]; then
        sudo rm -rf /etc/logrotate.d/$2
        sleep 2
    fi

    sudo touch /etc/logrotate.d/$2
    sudo chown $USER:$USER /etc/logrotate.d/$2
    cat << EOF > /etc/logrotate.d/$2
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

function install_mongod() {
    echo
    echo -e "${ARROW} ${YELLOW}Removing any instances of Mongodb...${NC}"
    sudo systemctl stop mongod > /dev/null 2>&1 && sleep 1
    sudo apt remove mongod* -y > /dev/null 2>&1 && sleep 1
    sudo apt purge mongod* -y > /dev/null 2>&1 && sleep 1
    sudo apt autoremove -y > /dev/null 2>&1 && sleep 1
    echo -e "${ARROW} ${YELLOW}Mongodb installing...${NC}"
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install mongodb-org -y > /dev/null 2>&1 && sleep 2
    sudo systemctl enable mongod > /dev/null 2>&1
    sudo systemctl start  mongod > /dev/null 2>&1
    if mongod --version > /dev/null 2>&1; then
        #echo -e "${ARROW} ${CYAN}MongoDB version: ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed${NC}"
        string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
        echo
    else
        #echo -e "${ARROW} ${CYAN}MongoDB was not installed${NC}" 
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
    #export NVM_DIR="$HOME/.nvm" && (
    # git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" > /dev/null 2>&1 
    # cd "$NVM_DIR"
    # git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` > /dev/null 2>&1
    #) && \. "$NVM_DIR/nvm.sh"
    #cd
    #curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash > /dev/null 2>&1
    curl -SsL -m 10 https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash > /dev/null 2>&1
    . ~/.profile
    . ~/.bashrc
    sleep 1
    #nvm install v12.16.1
    nvm install 16 > /dev/null 2>&1
    if node -v > /dev/null 2>&1; then
        #echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
        string_limit_check_mark "Nodejs $(node -v) installed................................." "Nodejs ${GREEN}$(node -v)${CYAN} installed................................."
        echo
    else
        #echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
        string_limit_x_mark "Nodejs was not installed................................."
        echo
    fi
}

function check() {
    cd
    pm2 start /home/$USER/$FLUX_DIR/start.sh --restart-delay=30000 --max-restarts=40 --name flux --time  > /dev/null 2>&1
    pm2 save > /dev/null 2>&1
    #sleep 120
    #cd /home/$USER/zelflux
    #pm2 stop flux
    #npm install --legacy-peer-deps > /dev/null 2>&1
    #pm2 start flux 
    #cd

    NUM='400'
    MSG1='Finalizing Flux installation please be patient this will take about ~5min...'
    MSG2="${CYAN}.............[${CHECK_MARK}${CYAN}]${NC}"
    echo && spinning_timer
    echo 

    $BENCH_CLI restartnodebenchmarks  > /dev/null 2>&1

    NUM='250'
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

function display_banner() {
    echo -e "${BLUE}"
    figlet -t -k "FLUXNODE"
    figlet -t -k "INSTALLATION   COMPLETED"
    echo -e "${YELLOW}================================================================================================================================"
    #echo -e "FLUXNODE INSTALATION COMPLITED${NC}"
    #echo -e "${CYAN}COURTESY OF DK808/XK4MiLX${NC}"
    echo
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
	    echo
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
        echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 monit${NC}"
        echo -e "${PIN} ${CYAN}Stop Flux: ${SEA}pm2 stop flux${NC}"
        echo -e "${PIN} ${CYAN}Start Flux: ${SEA}pm2 start flux${NC}"
        echo
    if [[ "$WATCHDOG_INSTALL" == "1" ]]; then
        echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE WATCHDOG.${NC}"
        echo -e "${PIN} ${CYAN}Stop watchdog: ${SEA}pm2 stop watchdog${NC}"
        echo -e "${PIN} ${CYAN}Start watchdog: ${SEA}pm2 start watchdog --watch${NC}"
        echo -e "${PIN} ${CYAN}Restart watchdog: ${SEA}pm2 reload watchdog --watch${NC}"
        echo -e "${PIN} ${CYAN}Error logs: ${SEA}~/watchdog/watchdog_error.log${NC}"
        echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 monit${NC}"
        echo
        echo -e "${PIN} ${RED}IMPORTANT: After installation check ${SEA}'pm2 list'${RED} if not work, type ${SEA}'source /home/$USER/.bashrc'${NC}"
        echo
    fi
    echo -e "${PIN} ${CYAN}To access your frontend to Flux enter this in as your url: ${SEA}${WANIP}:${ZELFRONTPORT}${NC}"
    echo -e "${YELLOW}===================================================================================================================[${GREEN}Duration: $((($(date +%s)-$start_install)/60)) min. $((($(date +%s)-$start_install) % 60)) sec.${YELLOW}]${NC}"
    sleep 1
    cd $HOME
    exec bash
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
            #echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
            string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
            echo
        else
            #echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
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
        config_file

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
            echo -e "${PIN}${CYAN} Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
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
  
            echo -e "${PIN}${CYAN} Tier_eps_min = ${GREEN}$eps_limit${NC}" && sleep 1   
  
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
        else
            echo -e "${ARROW} ${YELLOW}Creating a swapfile skipped...${NC}"
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
            else
                echo -e "${ARROW} ${YELLOW}Creating a swapfile skipped...${NC}"
            fi
        fi
    fi
    sleep 2
}

function install_packages() {
    echo
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

function ip_confirm() {
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
        exit
    fi
    
   string_limit_check_mark "IP: $WANIP ..........................................." "IP: ${GREEN}$WANIP${CYAN} ..........................................." 
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
    #echo -e "${ARROW} ${CYAN}PM2 version: ${GREEN}v$(pm2 -v)${CYAN} installed${NC}"
    string_limit_check_mark "PM2 v$(pm2 -v) installed....................................................." "PM2 ${GREEN}v$(pm2 -v)${CYAN} installed....................................................." 
    PM2_INSTALL="1"
  else
    string_limit_x_mark "PM2 was not installed....................................................."
    echo
  fi 
}


function install_kernel(){
    echo -e "${GREEN}Module: Install Linux Kernel 5.X for Ubuntu 18.04${NC}"
    echo -e "${YELLOW}================================================================${NC}"

    if [[ "$USER" == "root" ]]; then
        echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
        echo -e "${CYAN}Please switch to the user account.${NC}"
        echo -e "${YELLOW}================================================================${NC}"
        echo -e "${NC}"
        exit
    fi

    echo -e "${NC}"
    echo -e "${YELLOW}Installing Linux Kernel 5.x${NC}"
    sudo apt-get install --install-recommends linux-generic-hwe-18.04 -y
    read -p "Would you like to reboot pc Y/N?" -n 1 -r
    echo -e "${NC}"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot -n
    fi
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
    echo -e ""
    
    if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
        echo -e "${WORNING} ${CYAN}First install FluxNode...${NC}"
        echo -e "${WORNING} ${CYAN}Operation stopped...${NC}"
        echo -e ""
        exit
    fi  
    
    sleep 15
    bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/multinode.sh)
}

function create_service_scripts() {
    echo -e "${ARROW} ${YELLOW}Creating Flux daemon service scripts...${NC}" && sleep 1
    sudo touch /home/$USER/start_daemon_service.sh
    sudo chown $USER:$USER /home/$USER/start_daemon_service.sh

    cat <<'EOF' > /home/$USER/start_daemon_service.sh
#!/bin/bash
#color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
sleep 2
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
    cat <<'EOF' > /home/$USER/stop_daemon_service.sh
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

function create_oldnode_service() {
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
        
    echo -e "${ARROW} ${CYAN}Creating Flux daemon service...${NC}" && sleep 1
    sudo touch /etc/systemd/system/zelcash.service
    sudo chown $USER:$USER /etc/systemd/system/zelcash.service
    cat << EOF > /etc/systemd/system/zelcash.service
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



