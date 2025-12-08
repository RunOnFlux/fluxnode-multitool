#!/bin/bash
#
#   Usage:
#   bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/development/cdn-speedtest.sh) "<test_time_in_s>" "<file_name>" "<array_url_list_via_export>" 
#
#   Example 1 ( for testing custom servers ):
#   export list=("http://cdn-11.runonflux.io/apps/fluxshare/getfile/" "http://cdn-11.runonflux.io/apps/fluxshare/getfile/")
#   bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/development/cdn-speedtest.sh) "6" "flux_explorer_bootstrap.tar.gz" "${list[@]}"
#
#   Example 2 ( for testing cdn with 6s download test of each server )
#   bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/development/cdn-speedtest.sh) "6"
#
#   Example 3 ( for testing cdn with default settings )
#   bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/development/cdn-speedtest.sh)
#
#
#color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
ARROW="${SEA}\xE2\x96\xB6${NC}"
RIGHT_ANGLE="${GREEN}\xE2\x88\x9F${NC}"
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
#global variable
failed_counter="0"

if ! bc -v > /dev/null 2>&1 ; then
	sudo apt install -y bc > /dev/null 2>&1 && sleep 1
fi
if [[ -z $1 ]]; then
	dTime="5"
else
	dTime="$1"
fi
if [[ -z $2 || "$2" == "0" ]]; then
	BOOTSTRAP_FILE="flux_explorer_bootstrap.tar.gz"
else
	BOOTSTRAP_FILE="$2"
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
		testing=$(curl -L -m ${dTime} ${rand_by_domain[$i]}${BOOTSTRAP_FILE}  --output testspeed -fail --silent --show-error 2>&1)
	else
		testing=$(curl -L -m ${dTime} http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/${BOOTSTRAP_FILE}  --output testspeed -fail --silent --show-error 2>&1)
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
	exit
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
mb=$(bc <<<"scale=2; $arr_max / 1048576 / $dTime" | awk '{printf "%2.2f\n", $1}')
if [[ "$custom_url" == "1" ]]; then
	domain=$(sed -e 's|^[^/]*//||' -e 's|/.*$||' <<< ${server_index})
	echo -e "${ARROW} ${CYAN}Best server is: ${YELLOW}${domain} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
else
	echo -e "${ARROW} ${CYAN}Best server is: ${GREEN}cdn-${YELLOW}${rand_by_domain[${max_indexes[0]}]} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
fi
echo -e "${CHECK_MARK} ${GREEN}Fastest Server: ${YELLOW}${DOWNLOAD_URL}${NC}"
