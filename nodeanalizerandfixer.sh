#!/bin/bash

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/flux_common.sh)"

#const
REPLACE="0"
FLUXCONF="0"
FLUXRESTART="0"
ZELCONF="0"
BTEST="0"
LC_CHECK="0"
ZELFLUX_PORT1="0"
ZELFLUX_PORT2="0"
FLUX_UPDATE="0"
OWNER="0"
IP_FIX="0"
SCVESION=v4.0

FLUX_DIR='zelflux'
COIN_NAME='zelcash'
COIN_DAEMON='zelcashd'
BENCH_DIR_LOG='.zelbenchmark'
BENCH_DAEMON='zelbenchd'
BENCH_NAME='zelbench'

if [[ -f /usr/local/bin/flux-cli ]]; then
	COIN_CLI='flux-cli'
else
	COIN_CLI='zelcash-cli'
fi

if [[ -f /usr/local/bin/fluxbench-cli ]]; then
	BENCH_CLI='fluxbench-cli'
else
	BENCH_CLI='zelbench-cli'
fi

if [[ -d /home/$USER/.zelcash ]]; then
	CONFIG_DIR='.zelcash'
	CONFIG_FILE='zelcash.conf'
else
	CONFIG_DIR='.flux'
	CONFIG_FILE='flux.conf'
fi

if [[ -d /home/$USER/.zelbenchmark ]]; then
	BENCH_DIR_LOG='.zelbenchmark'
else
	BENCH_DIR_LOG='.fluxbenchmark'
fi
get_ip
#function
function show_time() {
	num=$1
	min=0
	hour=0
	day=0
	if((num>59));then
		((sec=num%60))
		((num=num/60))
			if((num>59));then
				((min=num%60))
				((num=num/60))
					if((num>23));then
						((hour=num%24))
						((day=num/24))
					else
						((hour=num))
					fi
			else
					((min=num))
			fi
	else
		((sec=num))
	fi
	echo -e "${PIN} ${CYAN}Last error was \c"
	echo -e "${RED}$day"d "$hour"h "$min"m "$sec"s"${CYAN} ago.${NC}"
}
function check_listen_ports(){
	if ! lsof -v > /dev/null 2>&1; then
		sudo apt-get install lsof -y > /dev/null 2>&1 && sleep 1
	fi
	if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
		FluxAPI=$(grep -Po "(?<=fluxport=)\d+" /home/$USER/.fluxbenchmark/fluxbench.conf)
		FLUXOS_CONFIG=$(grep -Po "$FluxAPI" /home/$USER/zelflux/config/userconfig.js)
		if [[ "$FLUXOS_CONFIG" != "" ]]; then
			FluxUI=$(($FluxAPI-1))
			UPNP=1
		else
			FluxAPI=16127
			FluxUI=16126
			UPNP=0
		fi
	else
		FluxAPI=16127
		FluxUI=16126
		UPNP=0
	fi
	if sudo lsof -i  -n | grep LISTEN | grep 27017 | grep mongod > /dev/null 2>&1; then
		echo -e "${CHECK_MARK} ${CYAN} Mongod listen on port 27017${NC}"
	else
		echo -e "${X_MARK} ${CYAN} Mongod not listen${NC}"
	fi
	if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep fluxd > /dev/null 2>&1; then
		echo -e "${CHECK_MARK} ${CYAN} Flux daemon listen on port 16125${NC}"
	else
		if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep zelcashd > /dev/null 2>&1; then
			echo -e "${CHECK_MARK} ${CYAN} Flux daemon listen on port 16125${NC}"
		else
			echo -e "${X_MARK} ${CYAN} Flux daemon not listen${NC}"
		fi
	fi
	if sudo lsof -i  -n | grep LISTEN | grep 16224 | grep bench > /dev/null 2>&1; then
		echo -e "${CHECK_MARK} ${CYAN} Flux benchmark listen on port 16224${NC}"
	else
		echo -e "${X_MARK} ${CYAN} Flux benchmark not listen${NC}"
	fi
	if sudo lsof -i  -n | grep LISTEN | grep $FluxUI | grep node > /dev/null 2>&1; then
		ZELFLUX_PORT1="1"
	fi
	if sudo lsof -i  -n | grep LISTEN | grep $FluxAPI | grep node > /dev/null 2>&1 ; then
		ZELFLUX_PORT2="1"
	fi
	if [[ "$ZELFLUX_PORT1" == "1" && "$ZELFLUX_PORT2" == "1"  ]]; then
		echo -e "${CHECK_MARK} ${CYAN} Flux listen on ports $FluxUI/$FluxAPI ${NC}"
	else
		echo -e "${X_MARK} ${CYAN} Flux not listen${NC}"
	fi
	echo -e ""
	echo -e "${BOOK} ${YELLOW}FluxOS networking: ${NC}"
	if [[ "$UPNP" == "1" ]]; then
		echo -e "${PIN} ${CYAN}UPnP MODE: ${GREEN}ENABLED${NC}"
	else
		echo -e "${PIN} ${CYAN}UPnP MODE: ${RED}DISABLED${NC}"
	fi
	echo -e "${PIN} ${CYAN}FluxAPI PORT: ${ORANGE}$FluxAPI ${NC}"
	echo -e "${PIN} ${CYAN}FluxUI PORT: ${ORANGE}$FluxUI ${NC}"
	if [[ -f /home/$USER/.pm2/logs/flux-out.log ]]; then
	error_check=$(tail -n10 /home/$USER/.pm2/logs/flux-out.log | grep "UPnP failed")
		if [[ "$error_check" != "" ]]; then
			echo -e ""
			echo -e "${ARROW} ${YELLOW}Checking FluxOS logs... ${NC}"
			echo -e "${WORNING} ${RED}Problem with UPnP detected, FluxOS Shutting down..."
			echo -e ""
		fi
	fi
}
function get_last_benchmark(){
	if [[ "$2" == "check" ]]; then
	
		info_check=$(grep 'Found' /home/$USER/$BENCH_DIR_LOG/debug.log | egrep 'Found|Historical' | grep $1 | tail -n1 | egrep -o '[0-9]+(\.[0-9]+)|([0-9]+)' | tail -n1 | awk '{printf "%.2f\n", $1}')
		if [[ "$info_check"  == "" ]]; then
			skipp_debug=1
			return 1
		fi
	
	fi


	if [[ "$1" == "cores" ]]; then
			cores=$(grep 'Found' /home/$USER/$BENCH_DIR_LOG/debug.log | egrep 'Found|Historical' | grep 'cores' | tail -n1 | egrep -Eo '[^ ]+$')
			echo -e "${PIN}${CYAN} CORES: ${GREEN}$cores${NC}"
	fi

	if [[ "$1" == "HDD" ||  "$1" == "DD_WRITE" || "$1" == "ram" || "$1" == "eps" ]] && [[ "$2" != "check" ]]; then

		info=$(grep 'Found' /home/$USER/$BENCH_DIR_LOG/debug.log | egrep 'Found|Historical' | grep $1 | tail -n1 | egrep -o '[0-9]+(\.[0-9]+)|([0-9]+)' | tail -n1 | awk '{printf "%.2f\n", $1}')

		if [[ "$1" == "ram" ]]; then
			echo -e "${PIN}${CYAN} RAM: ${GREEN}$info${NC}"
		fi

		if [[ "$1" == "eps" ]]; then
			echo -e "${PIN}${CYAN} EPS: ${GREEN}$info${NC}"
		fi

		if [[ "$1" == "DD_WRITE" ]]; then
			echo -e "${PIN}${CYAN} DD_WRITE: ${GREEN}$info${NC}"
		fi

		if [[ "$1" == "HDD" ]]; then
			echo -e "${PIN}${CYAN} HDD: ${GREEN}$info${NC}"
		fi
	fi
}
function integration(){
	PATH_TO_FOLDER=( /usr/local/bin/ ) 
	if [[ -f /usr/local/bin/fluxd ]]; then
		FILE_ARRAY=( 'fluxbench-cli' 'fluxbenchd' 'flux-cli' 'fluxd' 'flux-fetch-params.sh' 'flux-tx' )
	else
		FILE_ARRAY=( 'zelbench-cli' 'zelbenchd' 'zelcash-cli' 'zelcashd' 'zelcash-fetch-params.sh' 'zelcash-tx' )
	fi
	ELEMENTS=${#FILE_ARRAY[@]}
	NOT_FOUND="0"
	for (( i=0;i<$ELEMENTS;i++)); do
		if [ -f $PATH_TO_FOLDER${FILE_ARRAY[${i}]} ]; then
				echo -e "${CHECK_MARK} ${CYAN} ${FILE_ARRAY[${i}]}"
		else
				echo -e "${X_MARK} ${CYAN} ${FILE_ARRAY[${i}]}"
				NOT_FOUND="1"
		fi 
	done
}

if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
	echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
	echo -e "${CYAN}Please switch to the user accont.${NC}"
	echo -e "${YELLOW}================================================================${NC}"
	echo -e "${NC}"
	exit
fi
sleep 1
if ! bc -v > /dev/null 2>&1 ; then
	sudo apt install -y bc > /dev/null 2>&1 && sleep 1
fi
echo -e "${NC}"
if [ -f /home/$USER/$BENCH_DIR_LOG/debug.log ]; then
	echo -e "${BOOK} ${YELLOW}Checking Flux benchmark $BENCH_DIR_LOG/debug.log${NC}"
	if [[ $(egrep -ac -wi --color 'Failed' /home/$USER/$BENCH_DIR_LOG/debug.log) != "0" ]]; then
		echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(egrep -ac --color 'Failed' /home/$USER/$BENCH_DIR_LOG/debug.log)${CYAN} error events${NC}"
		#egrep -wi --color 'warning|error|critical|failed' ~/.zelbenchmark/debug.log
		error_line=$(egrep -a --color 'Failed' /home/$USER/$BENCH_DIR_LOG/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
		event_date=$(egrep -a --color 'Failed' /home/$USER/$BENCH_DIR_LOG/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
		echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
		event_time_uxtime=$(date -ud "$event_date" +"%s")
		event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
		event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
		echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
		event_time="$event_time_uxtime"
		now_date=$(date +%s)
		tdiff=$((now_date-event_time))
		show_time "$tdiff"
		echo -e "${PIN} ${CYAN}Creating Flux benchmark_debug_error.log${NC}"
		egrep -a --color 'Failed' /home/$USER/$BENCH_DIR_LOG/debug.log > /home/$USER/benchmark_debug_error.log
		echo -e ""
	else
		echo -e "${GREEN}\xF0\x9F\x94\x8A ${CYAN}Found: ${GREEN}0 errors${NC}"
		echo -e ""
	fi
	skipp_debug=0
	get_last_benchmark "HDD" "check"
	if [[ "$skipp_debug" == "0" ]]; then
		echo -e "${BOOK} ${YELLOW}Last benchmark from ~/$BENCH_DIR_LOG/debug.log${NC}"
		get_last_benchmark "HDD"
		get_last_benchmark "DD_WRITE"
		get_last_benchmark "ram"
		get_last_benchmark "cores"
		echo -e ""
	fi
fi
if [ -f /home/$USER/$CONFIG_DIR/debug.log ]; then
	echo -e "${BOOK} ${YELLOW}Checking Flux daemon ~/$CONFIG_DIR/debug.log${NC}"
	if [[ $(egrep -ac -wi --color 'error|failed' /home/$USER//$CONFIG_DIR/debug.log) != "0" ]]; then
		echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(egrep -ac -wi --color 'error|failed' /home/$USER/$CONFIG_DIR/debug.log)${CYAN} error events, ${RED}$(egrep -ac -wi --color 'benchmarking' /home/$USER/$CONFIG_DIR/debug.log) ${CYAN}related to benchmark${NC}"
		if [[ $(egrep -ac -wi --color 'benchmarking' /home/$USER/$CONFIG_DIR/debug.log) != "0" ]]; then
			echo -e "${BOOK} ${CYAN}FluxBench errors info:${NC}"
			error_line=$(egrep -a --color 'benchmarking' /home/$USER/$CONFIG_DIR/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
			event_date=$(egrep -a --color 'benchmarking' /home/$USER/$CONFIG_DIR/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
			echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
			event_time_uxtime=$(date -ud "$event_date" +"%s")
			event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
			event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
			echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
			event_time="$event_time_uxtime"
			now_date=$(date +%s)
			tdiff=$((now_date-event_time))
			show_time "$tdiff"
		fi
		echo -e "${PIN} ${CYAN}Creating flux_daemon_debug_error.log${NC}"
		egrep -a --color 'error|failed' /home/$USER/$CONFIG_DIR/debug.log > /home/$USER/flux_daemon_debug_error.log
		echo -e ""
	else
		echo -e "${GREEN}\xF0\x9F\x94\x8A ${CYAN}Found: ${GREEN}0 errors${NC}"
		echo -e ""
	fi
fi
usercheck=$(getent group docker)
if [[ "$usercheck" =~ "," ]]; then
	echo -e ""
	echo -e "${WORNING} ${CYAN} Detected multiple users in docker group...${NC}"
	echo -e "${WORNING} ${CYAN} More then one instance of flux daemon will cause it to malfunction...${NC}"
	echo -e "${WORNING} ${CYAN} If u installed FluxOS on more then one user you need delete one instance of it...${NC}"
	echo -e "${WORNING} ${CYAN} To check the list of users type: getent group docker ${NC}"
	echo -e "${WORNING} ${CYAN} To remove unwanted users type: sudo deluser --remove-home user_name ${NC}"
	echo -e "${WORNING} ${CYAN} To reboot server type: sudo reboot -n ${NC}"
fi
if [[ "$($BENCH_CLI  getinfo 2>/dev/null  | jq -r '.version' 2>/dev/null)" != "" ]]; then
	echo -e "${BOOK} ${YELLOW}Flux benchmark status:${NC}"
	bench_getatus=$($BENCH_CLI getstatus)
	bench_status=$(jq -r '.status' <<< "$bench_getatus")
	bench_benchmark=$(jq -r '.benchmarking' <<< "$bench_getatus")
	bench_back=$(jq -r '.zelback' <<< "$bench_getatus")
	if [[ "$bench_back" == "null" ]]; then
		bench_back=$(jq -r '.flux' <<< "$bench_getatus")
	fi

	bench_getinfo=$($BENCH_CLI getinfo)
	bench_version=$(jq -r '.version' <<< "$bench_getinfo")

	if [[ "$bench_benchmark" == "failed" || "$bench_benchmark" == "toaster" ]]; then
		bench_benchmark_color="${RED}$bench_benchmark"
	else
		bench_benchmark_color="${SEA}$bench_benchmark"
	fi

	if [[ "$bench_status" == "online" ]]; then
		bench_status_color="${SEA}$bench_status"
	else
		bench_status_color="${RED}$bench_status"
	fi

	if [[ "$bench_back" == "connected" ]]; then
		bench_back_color="${SEA}$bench_back"
	else
		bench_back_color="${RED}$bench_back"
	fi

	echo -e "${PIN} ${CYAN}Flux benchmark version: ${SEA}$bench_version${NC}"
	echo -e "${PIN} ${CYAN}Flux benchmark status: $bench_status_color${NC}"
	echo -e "${PIN} ${CYAN}Benchmark: $bench_benchmark_color${NC}"
	echo -e "${PIN} ${CYAN}Flux: $bench_back_color${NC}"
	echo -e "${NC}"

	if [[ "$bench_benchmark" == "running" ]]; then
		echo -e "${ARROW} ${CYAN} Benchmarking hasn't completed, please wait until benchmarking has completed.${NC}"
	fi

	if [[ "$bench_benchmark" == "CUMULUS" || "$bench_benchmark" == "NIMBUS" || "$bench_benchmark" == "STRATUS" ]]; then
		echo -e "${CHECK_MARK} ${CYAN} Flux benchmark working correct, all requirements met.${NC}"
	fi

	if [[ "$bench_benchmark" == "failed" ]]; then
		echo -e "${X_MARK} ${CYAN} Flux benchmark problem detected, check benchmark debug.log${NC}"
	fi

	core=$($BENCH_CLI getbenchmarks | jq '.cores')
	if [[ "$bench_benchmark" == "failed" && "$core" > "0" ]]; then
		BTEST="1"
		echo -e "${X_MARK} ${CYAN} Flux benchmark working correct but minimum system requirements not met.${NC}"
		check_benchmarks "eps" "89.99" " CPU speed" "< 90.00 events per second"
		check_benchmarks "ddwrite" "159.99" " Disk write speed" "< 160.00 events per second"
	fi
	#if [[ "$zelbench_benchmark" == "toaster" || "$zelbench_benchmark" == "failed" ]]; then
	##lc_numeric_var=$(locale | grep LC_NUMERIC | sed -e 's/.*LC_NUMERIC=//')
	##lc_numeric_need='"en_US.UTF-8"'
	##if [ "$lc_numeric_var" == "$lc_numeric_need" ]
	##then
	##echo -e "${CHECK_MARK} ${CYAN} LC_NUMERIC is correct${NC}"
	##else
	##echo -e "${X_MARK} ${CYAN} You need set LC_NUMERIC to en_US.UTF-8${NC}"
	##LC_CHECK="1"
	##fi
	#fi
	if [[ "$bench_back" == "disconnected" ]]; then
		echo -e "${X_MARK} ${CYAN} FluxBack does not work properly${NC}"
		if [[ "$WANIP" != "" ]]; then
			back_error_check=$(curl -s -m 5 http://$WANIP:$FluxAPI/zelid/loginphrase | jq -r .status )
			if [[ "$back_error_check" != "success" &&  "$back_error_check" != "" ]]; then
				back_error=$(curl -s -m 8 http://$WANIP:$FluxAPI/zelid/loginphrase | jq -r .data.message.message 2>/dev/null )
				if [[ "$back_error" != "" ]]; then
					echo -e "${X_MARK} ${CYAN} FluxBack error: ${RED}$back_error${NC}"
				else
					back_error=$(curl -s -m 8 http://$WANIP:$FluxAPI/zelid/loginphrase | jq -r .data.message 2>/dev/null )
					if [[ "$back_error" != "" ]]; then  
						echo -e "${X_MARK} ${CYAN} FluxBack error: ${RED}$back_error${NC}"
					fi           
				fi
			fi
		fi
		device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
		local_device_ip=$(ip a list $device_name | grep -o $WANIP )
		if [[ "$WANIP" != "" ]]; then
			if [[ "$local_device_ip" == "$WANIP" ]]; then
				echo -e "${CHECK_MARK} ${CYAN} Public IP(${GREEN}$WANIP${CYAN}) matches local device(${GREEN}$device_name${CYAN}) IP(${GREEN}$local_device_ip${CYAN})${NC}"
			else
				echo -e "${X_MARK} ${CYAN} Public IP(${GREEN}$WANIP${CYAN}) not matches local device(${GREEN}$device_name${CYAN}) IP${NC}"
				echo -e "${ARROW} ${CYAN} If you under NAT use option 10 from multitoolbox (self-hosting)${NC}"
				## dev_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2"0"}')
				## sudo ip addr add "$WANPI" dev "$dev_name"
				# IP_FIX="1"
			fi
		else 
			echo -e "${ARROW} ${CYAN} Local device(${GREEN}$device_name${CYAN}) IP veryfication failed...${NC}"
		fi
	fi
	echo -e "${NC}"
fi
if [[ "$($COIN_CLI  getinfo 2>/dev/null  | jq -r '.version' 2>/dev/null)" != "" ]]; then
	echo -e "${BOOK} ${YELLOW}Flux deamon information:${NC}"
	daemon_getinfo=$($COIN_CLI getinfo)
	version=$(jq -r '.version' <<< "$daemon_getinfo")
	blocks_hight=$(jq -r '.blocks' <<< "$daemon_getinfo")
	protocolversion=$(jq -r '.protocolversion' <<< "$daemon_getinfo")
	connections=$(jq -r '.connections' <<< "$daemon_getinfo")
	error=$(jq -r '.error' <<< "$daemon_getinfo")
	if [[ "$error" != "" && "$error" != null ]]; then
		echo
		echo -e "${X_MARK} ${CYAN} Flux daemon error detected: ${RED}$error${CYAN}) IP${NC}"
	fi
	echo -e "${PIN} ${CYAN}Version: ${SEA}$version${NC}"
	echo -e "${PIN} ${CYAN}Protocolversion: ${SEA}$protocolversion${NC}"
	echo -e "${PIN} ${CYAN}Connections: ${SEA}$connections${NC}"
	echo -e "${PIN} ${CYAN}Blocks: ${SEA}$blocks_hight${NC}"
	network_height_01=$(curl -sk -m 5 https://$network_url_1/api/status?q=getInfo getinfo 2>/dev/null | jq '.info.blocks' 2> /dev/null)
	network_height_02=$(curl -sk -m 5 https://$network_url_2/api/status?q=getInfo getinfo 2>/dev/null | jq '.info.blocks' 2> /dev/null)
	explorer_network_hight=$(max "$network_height_01" "$network_height_02")
	block_diff=$((explorer_network_hight-blocks_hight))
	if [[ "$explorer_network_hight" != "0" ]]; then
		if [[ "$block_diff" < 10 ]]; then
			echo -e "${PIN} ${CYAN}Status: ${GREEN}synced${NC}"
		else
			echo -e "${PIN} ${CYAN}Status: ${RED}not synced${NC}"
		fi
	else
		echo -e "${PIN} ${CYAN}Info: ${RED}sync check skipped...${NC}"
	fi
	echo -e ""
	echo -e "${BOOK} ${YELLOW}Checking node status:${NC}"
	getzelnodestatus=$($COIN_CLI getzelnodestatus)
	node_status=$(jq -r '.status' <<< "$getzelnodestatus")
	collateral=$(jq -r '.collateral' <<< "$getzelnodestatus")
	if [[ "$node_status" == "CONFIRMED" ]]; then
		node_status_color="${SEA}$node_status"
	elif [[ "$node_status" == "STARTED" ]];then
		node_status_color="${YELLOW}$node_status"
	else
		node_status_color="${RED}$node_status"
	fi
	echo -e "${PIN} ${CYAN}Node status: $node_status_color${NC}"
	if [[ "$node_status" == "DOS" ]]; then
		blocks_till=$($COIN_CLI  getdoslist | jq .[] | grep "$collateral" -A5 -B1 | jq .eligible_in)
		dos_till=$((blocks_hight+blocks_till))
		echo -e "${PIN} ${RED}DOS ${CYAN}Till: ${ORANGE}$dos_till ${CYAN}EXPIRE_COUNT: ${ORANGE}$blocks_till${CYAN} Time left: ${RED}~$((2*blocks_till)) min. ${NC}"
	fi
	echo -e "${PIN} ${CYAN}Collateral: ${SEA}$collateral${NC}"
	echo -e ""
	if [[ "$node_status" != "CONFIRMED" ]]; then
		if whiptail --yesno "Would you like to verify $CONFIG_FILE Y/N?" 8 60; then
			ZELCONF="1"
			zelnodeprivkey="$(whiptail --title "Deamon configuration" --inputbox "Enter your FluxNode Identity Key generated by your Zelcore" 8 72 3>&1 1>&2 2>&3)"
			zelnodeoutpoint="$(whiptail --title "Deamon configuration" --inputbox "Enter your FluxNode Collateral TX ID" 8 72 3>&1 1>&2 2>&3)"
			zelnodeindex="$(whiptail --title "Deamon configuration" --inputbox "Enter your FluxNode Output Index usually a 0/1" 8 60 3>&1 1>&2 2>&3)"
		fi
	fi
	flux_communication=$(curl -SsL -m 10 http://"$WANIP":"$FluxAPI"/flux/checkcommunication 2>/dev/null | jq -r .data.message 2>/dev/null)
	if [[ "$flux_communication" != "null" && "$flux_communication" != "" ]]; then
		echo -e "${BOOK} ${YELLOW}Checking FluxOS communication: ${NC}"
		echo -e "${ARROW} ${CYAN}$flux_communication${NC}"
		echo -e ""
	fi
	if [[ "$explorer_network_hight" != "0" ]]; then
		echo -e "${BOOK} ${YELLOW}Checking collateral:${NC}"
		txhash=$(grep -o "\w*" <<< "$collateral")
		txhash=$(sed -n "2p" <<< "$txhash")
		txhash=$(egrep "\w{10,50}" <<< "$txhash")
		if [[ "$txhash" != "" ]]; then
			stak_info=""

			if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
				index_from_file=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
				stak_info=$(curl -s -m 10 https://$network_url_1/api/tx/$txhash  2>/dev/null | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId"  2>/dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
				if [[ "$stak_info" == "" ]]; then
					stak_info=$(curl -s -m 10 https://$network_url_2/api/tx/$txhash 2>/dev/null | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" 2>/dev/null | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
				fi
			fi

			if [[ "$stak_info" != "" ]]; then
				type=$(awk '{print $1}' <<< "$stak_info")
				conf=$($COIN_CLI gettxout $txhash $index_from_file | jq .confirmations)
				if [[ $conf == ?(-)+([0-9]) ]]; then
					if [ "$conf" -ge "100" ]; then
		 			 echo -e "${CHECK_MARK} ${CYAN} Confirmations numbers >= 100($conf)${NC}"
					else
						echo -e "${X_MARK} ${CYAN} Confirmations numbers < 100($conf)${NC}"
	 			 	fi
				else
					echo -e "${X_MARK} ${CYAN} FluxNode outpoint is not valid${NC}"
				fi
				if [[ $type == ?(-)+([0-9]) ]]; then
					case $type in
						"1000") echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}CUMULUS${NC}" ;;
						"12500")  echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}NIMBUS${NC}";;
						"40000") echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}STRATUS${NC}";;
					esac
					case $bench_benchmark in
						"CUMULUS")  bench_benchmark_value=1000 ;;
						"NIMBUS")  bench_benchmark_value=12500 ;;
						"STRATUS") bench_benchmark_value=40000 ;;
					esac
						if [[ -z bench_benchmark_value ]]; then
							echo -e ""
	 		 			else
							if [[ "$bench_benchmark_value" -ge "$type" ]]; then
								case $type in
									"1000")  bench_benchmark_value_name="CUMULUS" ;;
									"12500")  bench_benchmark_value_name="NIMBUS" ;;
									"40000") bench_benchmark_value_name="STRATUS" ;;
								esac
							else
								case $type in
									"1000")  bench_benchmark_value_name="CUMULUS" ;;
									"12500")  bench_benchmark_value_name="NIMBUS" ;;
									"40000") bench_benchmark_value_name="STRATUS" ;;
								esac
								if [[ "$bench_benchmark" == "running" ]]; then
									echo -en ""
								else
									echo -en ""	
								fi
							fi
						fi	
				fi
			else
				echo -e "${X_MARK} ${CYAN} Flux collateral check skipped...${NC}"
			fi
				#url_to_check="https://explorer.zel.cash/api/tx/$txhash"
				#type=$(wget -nv -qO - $url_to_check | jq '.vout' | grep '"value"' | egrep -o '10000|25000|100000')
				#type=$(zelcash-cli gettxout $txhash 0 | jq .value)
		fi
	fi
fi

echo -e "${NC}"
echo -e "${BOOK} ${YELLOW}Checking listen ports:${NC}"
check_listen_ports
echo -e "${NC}"
echo -e "${BOOK} ${YELLOW}Daemon files integrity checking:${NC}"
integration
echo -e ""
echo -e "${BOOK} ${YELLOW}Checking service:${NC}"
docker_working=0
docker_running=$(sudo systemctl status docker 2> /dev/null  | grep 'running' | grep -o 'since.*')
docker_inactive=$(sudo systemctl status docker 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')
mongod_running=$(sudo systemctl status mongod 2> /dev/null | grep 'running' | grep -o 'since.*')
mongod_inactive=$(sudo systemctl status mongod 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')
daemon_running=$(sudo systemctl status zelcash 2> /dev/null | grep 'running' | grep -o 'since.*')
daemon_inactive=$(sudo systemctl status zelcash 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')

if sudo systemctl list-units | grep docker.service | egrep -wi 'running' > /dev/null 2>&1; then
	echo -e "${CHECK_MARK}  ${CYAN}Docker service running ${SEA}$docker_running${NC}"
	#docker_working=1
else
	if [[ "$docker_inactive" != "" ]]; then
		echo -e "${X_MARK}  ${CYAN}Docker service not running ${RED}$docker_inactive${NC}"
	else
		echo -e "${X_MARK}  ${CYAN}Docker is not installed${NC}"
	fi
fi
verifity_mongod=0
if sudo systemctl list-units | grep mongod | egrep -wi 'running' > /dev/null 2>&1; then
	echo -e "${CHECK_MARK} ${CYAN} MongoDB service running ${SEA}$mongod_running${NC}"
else
	if [[ "$mongod_inactive" != "" ]]; then
		echo -e "${X_MARK} ${CYAN} MongoDB service not running ${RED}$mongod_inactive${NC}"
		verifity_mongod=1
	else
		echo -e "${X_MARK} ${CYAN} MongoDB service is not installed${NC}"
	fi
fi

if sudo systemctl list-units | grep zelcash | egrep -wi 'running' > /dev/null 2>&1; then
	echo -e "${CHECK_MARK} ${CYAN} Flux daemon service running ${SEA}$daemon_running${NC}"
else
	if [[ "$daemon_inactive" != "" ]]; then
		echo -e "${X_MARK} ${CYAN} Flux daemon service not running ${RED}$daemon_inactive${NC}"
	else
		echo -e "${X_MARK} ${CYAN} Flux daemon service is not installed${NC}"
	fi
fi
echo -e ""
if [[ "$verifity_mongod" != "0" ]]; then
	mongod_lib_dir_ownership=$(ls -l /var/lib/mongodb | awk '{print $3}' | tail -n1)
	mongod_log_dir_ownership=$(ls -l /var/log/mongodb | awk '{print $3}' | tail -n1)
	if [[ -f /tmp/mongodb-27017.sock ]]; then
		mongod_tmp_sock_ownership=$(ls -l /tmp/mongodb-27017.sock | awk '{print $3}')
	else
	 mongod_tmp_sock_ownership="mongodb"
	fi

	if [[ "$mongod_lib_dir_ownership" != "mongodb" || "$mongod_log_dir_ownership" != "mongodb" || "$mongod_tmp_sock_ownership" != "mongodb" ]]; then
		echo -e "${BOOK} ${YELLOW}Checking MongoDB:${NC}"
		echo -e "${X_MARK} ${CYAN} MongodDB directory/ownership detected!"
		echo -e ""
		if [[ ! -d /var/lib/mongodb ]]; then 
				sudo mkdir /var/lib/mongodb > /dev/null 2>&1    
		fi
		sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
		if [[ ! -d /var/log/mongodb ]]; then
				sudo mkdir /var/log/mongodb > /dev/null 2>&1
		fi
		sudo chown -R mongodb:mongodb /var/log/mongodb > /dev/null 2>&1      
		chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
	fi
fi
echo -e "${BOOK} ${YELLOW}Checking FluxOS:${NC}"
if pm2 -v > /dev/null 2>&1; then
	pm2_flux_status=$(pm2 info flux 2> /dev/null | grep 'status' | sed -r 's/│//gi' | sed 's/status.//g' | xargs)
	if [[ "$pm2_flux_status" == "online" ]]; then
		pm2_flux_uptime=$(pm2 info flux | grep 'uptime' | sed -r 's/│//gi' | sed 's/uptime//g' | xargs)
		pm2_flux_restarts=$(pm2 info flux | grep 'restarts' | sed -r 's/│//gi' | xargs)
		echo -e "${CHECK_MARK} ${CYAN} Pm2 FluxOS info => status: ${GREEN}$pm2_flux_status${CYAN}, uptime: ${GREEN}$pm2_flux_uptime${NC} ${SEA}$pm2_flux_restarts${NC}"
	else
		if [[ "$pm2_flux_status" != "" ]]; then
			echo -e "${X_MARK} ${CYAN} Pm2 FluxOS status: ${RED}$pm2_flux_status ${NC}" 
		fi
	fi
	pm2_flux_status=$(pm2 info zelflux 2> /dev/null | grep 'status' | sed -r 's/│//gi' | sed 's/status.//g' | xargs)
	if [[ "$pm2_flux_status" == "online" ]]; then
		pm2_flux_uptime=$(pm2 info zelflux | grep 'uptime' | sed -r 's/│//gi' | sed 's/uptime//g' | xargs)
		pm2_flux_restarts=$(pm2 info zelflux | grep 'restarts' | sed -r 's/│//gi' | xargs)
		echo -e "${CHECK_MARK} ${CYAN} Pm2 Flux info => status: ${GREEN}$pm2_flux_status${CYAN}, uptime: ${GREEN}$pm2_flux_uptime${NC} ${SEA}$pm2_flux_restarts${NC}"
	else
		if [[ "$pm2_flux_status" != "" ]]; then
			echo -e "${X_MARK} ${CYAN} Pm2 FluxOS status: ${RED}$pm2_flux_status ${NC}" 
		fi
	fi

else
	echo -e "${X_MARK} ${CYAN} Pm2 is not installed${NC}"
fi
if [[ $(curl -s -m 5 --head "$WANIP:$FluxUI" | head -n 1 | grep "200 OK") ]]; then
	echo -e "${CHECK_MARK} ${CYAN} FluxOS front is working${NC}"
else
	echo -e "${X_MARK} ${CYAN} FluxOS front is not working${NC}"
fi
if [[ -d /home/$USER/$FLUX_DIR ]]; then
	FILE=/home/$USER/$FLUX_DIR/config/userconfig.js
	if [[ -f "$FILE" ]]; then
		current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
		required_ver=$(curl -sS --max-time 10 https://raw.githubusercontent.com/RunOnFlux/flux/master/package.json | jq -r '.version')
		if [[ "$required_ver" != "" ]]; then
			if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
					echo -e "${CHECK_MARK} ${CYAN} You have the current version of FluxOS ${GREEN}(v$required_ver)${NC}"     
			else
					echo -e "${HOT} ${CYAN}New version of FluxOS available ${SEA}$required_ver${NC}"
					FLUX_UPDATE="1"
			fi
		fi
		echo -e "${CHECK_MARK} ${CYAN} FluxOS config  ~/$FLUX_DIR/config/userconfig.js exists${NC}"
		ZELIDLG=`echo -n $(grep -w zelid /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e "s/'//g" | sed -e "s/,//g" | sed -e "s/.*zelid://g") | wc -m`
		if [[ "$ZELIDLG" -eq "35" || "$ZELIDLG" -eq "34" || "$ZELIDLG" -eq "33" ]]; then
		echo -e "${CHECK_MARK} ${CYAN} Zel ID is valid${NC}"
		elif [[ "$ZELIDLG" == "0" || "$ZELIDLG" == "2" ]]; then
		echo -e "${X_MARK} ${CYAN} Zel ID is missing...${NC}"
		else
		echo -e "${X_MARK} ${CYAN} Zel ID is not valid${NC}"
		fi

		if [[ -f ~/$FLUX_DIR/error.log ]]; then
			echo -e ""
			echo -e "${BOOK} ${YELLOW}FluxOS error.log file detected, check ~/zelflux/error.log"
			echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(wc -l  < /home/$USER/$FLUX_DIR/error.log)${CYAN} error events${NC}"
			error_line=$(cat /home/$USER/$FLUX_DIR/error.log | grep 'Error' | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{3\}Z//' | xargs)
			echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
			event_date=$(cat /home/$USER/$FLUX_DIR/error.log | grep 'Error' | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{3\}Z')
			event_time_uxtime=$(date -d "$event_date" +"%s")
			event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
			event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
			echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
			now_date=$(date +%s)
			tdiff=$((now_date-event_time_uxtime))
			show_time "$tdiff"
		fi
	else
		FLUXCONF="1"
		echo -e "${X_MARK} ${CYAN}Flux config ~/$FLUX_DIR/config/userconfig.js does not exists${NC}"
	fi
else
	echo -e "${X_MARK} ${CYAN}Directory ~/$FLUX_DIR does not exists${CYAN}"
fi
if [[ "$ZELCONF" == "1" ]]; then
	echo -e ""
	echo -e "${BOOK} ${YELLOW}Checking ~/$CONFIG_DIR/$CONFIG_FILE${NC}"
	if [[ $zelnodeprivkey == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeprivkey=//') ]]; then
	echo -e "${CHECK_MARK} ${CYAN} FluxNode Identity Key matches${NC}"
	else
	REPLACE="1"
	echo -e "${X_MARK} ${CYAN} FluxNode Identity Key does not match${NC}"
	fi

	if [[ $zelnodeoutpoint == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//') ]]; then
		echo -e "${CHECK_MARK} ${CYAN} FluxNode Collateral TX ID matches${NC}"
	else
		REPLACE="1"
		echo -e "${X_MARK} ${CYAN} FluxNode Collateral TX ID does not match${NC}"
	fi

	if [[ $zelnodeindex == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//') ]]; then
		echo -e "${CHECK_MARK} ${CYAN} FluxNode Output Index matches${NC}"
	else
		REPLACE="1"
		echo -e "${X_MARK} ${CYAN} FluxNode Output Index does not match${NC}"
	fi

fi
if [[ -f /home/$USER/watchdog/package.json ]]; then
	echo -e ""
	echo -e "${BOOK} ${YELLOW}Checking Watchdog:${NC}"
	current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
	required_ver=$(curl -sS https://raw.githubusercontent.com/RunOnFlux/fluxnode-watchdog/master/package.json | jq -r '.version')
	if [[ "$required_ver" != "" ]]; then
		if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
			echo -e "${CHECK_MARK} ${CYAN} You have the current version of Watchdog ${GREEN}(v$required_ver)${NC}"     
		else
			echo -e "${HOT} ${CYAN}New version of Watchdog available ${SEA}$required_ver${NC}"
		fi
	fi
fi
if [[ -f /home/$USER/watchdog/watchdog_error.log ]]; then
	echo -e ""
	echo -e "${BOOK} ${YELLOW}Watchdog watchdog_error.log file detected, check ~/watchdog/watchdog_error.log"
	echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(wc -l  < /home/$USER/watchdog/watchdog_error.log)${CYAN} error events${NC}"
	error_line=$(cat /home/$USER/watchdog/watchdog_error.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
	echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
	event_date=$(cat /home/$USER/watchdog/watchdog_error.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}' | head -n1)
	event_time_uxtime=$(date -ud "$event_date" +"%s")
	event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
	event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
	echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
	now_date=$(date +%s)
	tdiff=$((now_date-event_time_uxtime))
	show_time "$tdiff"
fi 
echo -e "${YELLOW}===================================================${NC}"
if [[ "$FLUX_UPDATE" == "1" ]]; then
	read -p "Would you like to update Flux Y/N?" -n 1 -r
	echo -e ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cd /home/$USER/$FLUX_DIR && git pull > /dev/null 2>&1 && cd
		current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
		required_ver=$(curl -sS https://raw.githubusercontent.com/RunOnFlux/flux/master/package.json | jq -r '.version')
		if [[ "$required_ver" == "$current_ver" ]]; then
			echo -e "${CHECK_MARK} ${CYAN}Flux updated successfully.${NC}"
			echo -e ""
		else
			echo -e "${X_MARK} ${CYAN}Flux was not updated.${NC}"
			echo -e ""
		fi
	fi
fi
if [[ "$REPLACE" == "1" ]]; then
	read -p "Would you like to correct daemon config errors Y/N?" -n 1 -r
	echo -e ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo -e "${YELLOW}Stopping Flux daemon serivce...${NC}"
		sudo systemctl stop "$COIN_NAME"
		sudo fuser -k 16125/tcp > /dev/null 2>&1
		echo -e ""
		if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "\c"
		else
			if [[ "$zelnodeprivkey" == "" ]]; then
				echo -e " ${CYAN}FluxNode Identity Key skipped...............${NC}"
			else
				sed -i "s/$(grep -e zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeprivkey=$zelnodeprivkey/" ~/$CONFIG_DIR/$CONFIG_FILE
				if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
						echo -e " ${CYAN}FluxNode Identity Key replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
				fi
			fi
		fi

		if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "\c"
		else
			if [[ "$zelnodeoutpoint" == "" ]]; then
				echo -e " ${CYAN}FluxNode Collateral TX ID skipped...............${NC}"
			else
				sed -i "s/$(grep -e zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeoutpoint=$zelnodeoutpoint/" ~/$CONFIG_DIR/$CONFIG_FILE
				if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
								echo -e " ${CYAN}FluxNode Collateral TX ID replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
				fi
			fi
		fi

		if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
			echo -e "\c"
		else
			if [[ "$zelnodeindex" == "" ]]; then
				echo -e " ${CYAN}FluxNode Output Index skipped...............${NC}"
			else
				sed -i "s/$(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeindex=$zelnodeindex/" ~/$CONFIG_DIR/$CONFIG_FILE
				if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
								echo -e " ${CYAN}FluxNode Output Index replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
				fi
			fi
		fi
		echo -e ""
		sudo systemctl start "$COIN_NAME"
		NUM='35'
		MSG1=' Restarting Flux daemon serivce...'
		MSG2="${CYAN}............[${CHECK_MARK}${CYAN}]${NC}"
		spinning_timer
		echo -e ""
	fi
fi
echo -e ""
