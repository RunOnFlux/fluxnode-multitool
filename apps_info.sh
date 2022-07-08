#!/bin/bash

function max(){

    local m="0"
    for n in "$@"
    do
         if egrep -o "^[0-9]+$" <<< "$n" &>/dev/null; then
            [ "$n" -gt "$m" ] && m="$n"
        fi
    done
    echo "$m"

}

apps_info=$(curl -SsL -m 10 https://api.runonflux.io/apps/globalappsspecifications)
name=($(jq -r .data[].name <<< "$apps_info"))
height=($(jq -r .data[].height <<< "$apps_info"))

network_height_01=$(curl -sk -m 5 https://explorer.runonflux.io/api/status?q=getInfo | jq '.info.blocks')
network_height_03=$(curl -sk -m 5 https://explorer.zelcash.online/api/status?q=getInfo | jq '.info.blocks')
explorer_network_hight=$(max "$network_height_01" "$network_height_03")

echo -e ""
echo -e "Apps count: ${#name[@]}"
echo -e "-------------------------------------"

for((i=0;i<${#name[@]};i++));
do
 expire=$((${height[i]}+22000))
 block_diff=$((expire-explorer_network_hight))
 if [[ "$1" =~ '^[0-9]+$' ]]; then
  block_limit="$1"
 else
  block_limit="1000"
 fi


 if [[ "$block_diff" -le "$block_limit" ]]; then
  echo -e "Apps name: ${name[i]}"
  echo -e "Registered height: ${height[i]}"
  echo -e "Expire height: $expire"
  if [[ "$block_diff" -gt "0" ]]; then
   echo -e "Block till expire: $block_diff"
  else
   echo -e "Info: Apps expired!"
  fi
  echo -e "-------------------------------------"
 fi

done
