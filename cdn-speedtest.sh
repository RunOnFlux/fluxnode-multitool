#!/bin/bash

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

#allow user input for download time between 4 and 10 seconds - might help stabalize connection
if [ -z "$1" ]; then
  downloadtime='4'
elif [[ $1 -lt 10 && $1 -ge 4 ]]; then
  downloadtime="$1"
else
    downloadtime='4'
fi

#array of available bootstrap server IDs
rand_by_domain=("5" "6" "7" "8" "9" "10" "11" "12")
size_list=()
i=0
len=${#rand_by_domain[@]}
echo -e ""
echo -e "${YELLOW}Running quick download speed test for flux_explorer_bootstrap...${NC}"
while [ $i -lt $len ];
do
    #test download speed for -m $downloadtime and output to testing
    testing=$(curl -m $downloadtime http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.tar.gz  --output testspeed -fail --silent --show-error 2>&1)
    testing_size=$(grep -Po "\d+" <<< "$testing" | paste - - - - | awk '{printf  "%d\n",$3}')
    mb=$(bc <<<"scale=2; $testing_size / 1048576 / ($downloadtime)" | awk '{printf "%2.2f\n", $1}')
    echo -e "   ${RIGHT_ANGLE} ${GREEN}cdn-${YELLOW}${rand_by_domain[$i]}${GREEN} - Bits Downloaded: ${YELLOW}$testing_size${NC} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
    size_list+=($testing_size)
    i=$(($i+1))
done

sudo rm -rf testspeed > /dev/null 2>&1

arr_max=$(printf '%s\n' "${size_list[@]}" | sort -n | tail -1)
for i in "${!size_list[@]}"; do
    [[ "${size_list[i]}" == "$arr_max" ]] &&
    max_indexes+=($i)
done

# Print the results
mb=$(bc <<<"scale=2; $arr_max / 1048576 / ($downloadtime)" | awk '{printf "%2.2f\n", $1}')
echo -e ""
echo -e "${YELLOW}Best server is: ${GREEN}cdn-${YELLOW}${rand_by_domain[${max_indexes[0]}]} ${GREEN}Average speed: ${YELLOW}$mb ${GREEN}MB/s${NC}"
echo -e "${CHECK_MARK} ${GREEN}Fastest Server: ${YELLOW}http://cdn-${rand_by_domain[${max_indexes[@]}]}.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.tar.gz${NC}"
echo -e ""
