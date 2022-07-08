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

#dialog color
export NEWT_COLORS='
title=black,
'

function get_ip(){

 WANIP=$(curl -SsL -m 5 https://api4.my-ip.io/ip 2>/dev/null | tr -dc '[:alnum:].')

  if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
   WANIP=$(curl -SsL -m 5 https://checkip.amazonaws.com 2>/dev/null | tr -dc '[:alnum:].')
  fi

  if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
   WANIP=$(curl -SsL -m 5 https://api.ipify.org 2>/dev/null | tr -dc '[:alnum:].')
  fi
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

function server_geolocation(){

ip_output1=$(curl -s -m 10 http://ip-api.com/json/cdn-${rand_by_domain[$i]}.runonflux.io?fields=status,country,timezone 2>/dev/null | jq . 2>/dev/null)
ip_status1=$( jq -r .status 2>/dev/null <<< "$ip_output")

if [[ "$ip_status1" == "success" ]]; then
country1=$(jq -r .country <<< "$ip_output1")
org1=$(jq -r .org <<< "$ip_output1")
continent1=$(jq -r .timezone <<< "$ip_output1")
else
country1="UKNOW"
continent1="UKNOW"
fi

continent1=$(cut -f1 -d"/" <<< "$continent1" )

if [[ "$continent1" =~ "Europe" ]]; then
 server_continent="EU"
fi

if [[ "$continent1" =~ "America" ]]; then
 server_continent="US"
fi

if [[ "$continent1" =~ "Asia" ]]; then
 server_continent="AS"
fi

#echo -e "${ARROW} ${CYAN}Checking bootstrap server location....${NC}"
#echo -e "${ARROW} ${CYAN}Server Location: $country, Continent: $continent ${NC}"

}


function bootstrap_server(){
rand_by_domain=("5" "6" "7" "8" "9" "10" "11")
richable=()
richable_eu=()
richable_us=()
richable_as=()

i=0
len=${#rand_by_domain[@]}
echo -e "${ARROW} ${CYAN}Checking servers availability... ${NC}"
#echo -e "Bootstrap on list: $len"
while [ $i -lt $len ];
do

    server_geolocation ${rand_by_domain[$i]}
    bootstrap_check=$(curl -sSL -m 10 http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.json 2>/dev/null | jq -r '.block_height' 2>/dev/null)
    if [[ "$bootstrap_check" != "" ]]; then
    
       if [[ "$server_continent" == "EU" ]]; then
         richable_eu+=( ${rand_by_domain[$i]}  )
       fi

       if [[ "$server_continent" == "US" ]]; then
         richable_us+=( ${rand_by_domain[$i]}  )
       fi

       if [[ "$server_continent" == "AS" ]]; then
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
   if [[ "$len" == "0" ]]; then
    echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation skipped.. ${NC}" && sleep 1
    Server_offline=1
    return 1
   fi
fi



if [[ "$server_found" == "0" ]]; then
  len=${#richable[@]}
  if [[ "$len" == "0" ]]; then
    echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation skipped.. ${NC}" && sleep 1
    Server_offline=1
    return 1
  fi
fi

Server_offline=0

}

if ! jq --version > /dev/null 2>&1; then
  sudo apt install jq -y > /dev/null 2>&1
fi

get_ip
bootstrap_geolocation

if [[ "$Server_offline" == "1" ]]; then
     exit 1
fi

    #bootstrap_rand_ip
    bootstrap_index=$((${#richable[@]}-1))
    r=$(shuf -i 0-$bootstrap_index -n 1)
    indexb=${richable[$r]}
    BOOTSTRAP_ZIP="http://cdn-$indexb.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.tar.gz"
    echo -e "$BOOTSTRAP_ZIP"
