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

function string_limit_check_mark() {
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
echo -e "${ARROW} ${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
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

 function insertAfter
{
   local file="$1" line="$2" newText="$3"
   sudo sed -i -e "/$line/a"$'\\\n'"$newText"$'\n' "$file"
}



function upnp_enable() {

try="0"

 if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
       echo -e "${WORNING} ${CYAN}Missing FluxOS configuration file - install/re-install Flux Node...${NC}" 
       echo -e ""
       exit
 fi

  while true
     do

        echo -e "${ARROW}${YELLOW} Checking port validation.....${NC}"
        FLUX_PORT=$(whiptail --inputbox "Enter your FluxOS port (Ports allowed are: 16127, 16137, 16147, 16157, 16167, 16177, 16187, 16197)" 8 80 3>&1 1>&2 2>&3)
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

if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep "apiport") != "" ]]; then

  sed -i "s/$(grep -e apiport /home/$USER/zelflux/config/userconfig.js)/apiport: '$FLUX_PORT',/" /home/$USER/zelflux/config/userconfig.js

  if [[ $(grep -w $FLUX_PORT /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
     echo -e "${ARROW} ${CYAN}FluxOS port replaced successfully...................[${CHECK_MARK}${CYAN}]${NC}"
  fi

else

   insertAfter "/home/$USER/zelflux/config/userconfig.js" "zelid" "apiport: '$FLUX_PORT',"
   echo -e "${ARROW} ${CYAN}FluxOS port set successfully........................[${CHECK_MARK}${CYAN}]${NC}"

fi

if [[ -d /home/$USER/.fluxbenchmark ]]; then
  sudo mkdir -p /home/$USER/.fluxbenchmark 2>/dev/null
  echo "fluxport=$FLUX_PORT" | sudo tee "/home/$USER/.fluxbenchmark/fluxbench.conf" > /dev/null
else
  echo "fluxport=$FLUX_PORT" | sudo tee "/home/$USER/.fluxbenchmark/fluxbench.conf" > /dev/null
fi

if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
  echo -e "${ARROW} ${CYAN}Fluxbench port set successfully.....................[${CHECK_MARK}${CYAN}]${NC}"
  echo -e "${ARROW} ${YELLOW}Restarting FluxOS and Benchmark.....${NC}"
  #API PORT
  sudo ufw allow $FLUX_PORT > /dev/null 2>&1
  #HOME UI PORT
  sudo ufw allow $(($FLUX_PORT-1)) > /dev/null 2>&1
  
  
  #if ! route -h > /dev/null 2>&1 ; then
  # sudo apt install net-tools > /dev/null 2>&1
  #fi  
  
  #router_ip=$(route -n | sed -nr 's/(0\.0\.0\.0) +([^ ]+) +\1.*/\2/p' 2>/dev/null)
  router_ip=$(ip rout | head -n1 | awk '{print $3}' 2>/dev/null)
  
  if [[ "$router_ip" != "" ]]; then
  
  
    if (whiptail --yesno "Is your router's IP $router_ip ?" 8 70); then
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
    
     sudo ufw allow out from any to 239.255.255.250 port 1900 proto udp > /dev/null 2>&1
     sudo ufw allow from $router_ip port 1900 to any proto udp > /dev/null 2>&1
     sudo ufw allow out from any to $router_ip proto tcp > /dev/null 2>&1
     sudo ufw allow from $router_ip to any proto udp > /dev/null 2>&1
     
  fi
  
fi

  sudo systemctl restart zelcash  > /dev/null 2>&1
  pm2 restart flux  > /dev/null 2>&1
  sleep 200
  echo -e "${ARROW}${YELLOW} Checking FluxOS logs... ${NC}"
  error_check=$(tail -n10 /home/$USER/.pm2/logs/flux-out.log | grep "UPnP failed")
  
  if [[ "$error_check" == "" ]]; then
    echo -e ""
    LOCAL_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
    echo -e "${PIN} ${CYAN}To access your FluxOS use this url: ${SEA}http://${LOCAL_IP}:$(($FLUX_PORT-1))${NC}"
    echo -e ""
  else
    echo -e "${WORNING} ${RED}Problem with UPnP detected, FluxOS Shutting down...${NC}"
    echo -e ""
  fi

}

function upnp_disable() {

 if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
       echo -e "${WORNING} ${CYAN}Missing FluxOS configuration file - install/re-install Flux Node...${NC}" 
       echo -e ""
       exit
 fi
 
 if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
 echo -e "${ARROW} ${CYAN}Removing FluxOS UPnP configuration.....${NC}"
 sudo rm -rf /home/$USER/.fluxbenchmark/fluxbench.conf
 else
   echo -e "${ARROW} ${YELLOW}UPnP Mode is already disabled...${NC}"
   echo -e ""
   exit
 fi

 if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep 'apiport' | wc -l) == "1" ]]; then
  cat /home/$USER/zelflux/config/userconfig.js | sed '/apiport/d' | sudo tee "/home/$USER/zelflux/config/userconfig.js" > /dev/null
 fi

 echo -e "${ARROW} ${YELLOW}Restarting FluxOS and Benchmark.....${NC}"
 echo -e ""
 sudo systemctl restart zelcash  > /dev/null 2>&1
 pm2 restart flux  > /dev/null 2>&1
 sleep 200

}


 CHOICE=$(
whiptail --title "UPnP Configuration" --menu "Make your choice" 16 30 9 \
"1)" "Enable UPnP Mode"   \
"2)" "Disable UPnP Mode"  3>&2 2>&1 1>&3
)


case $CHOICE in
	"1)")   
         upnp_enable
	;;
	"2)")   
	 upnp_disable
	;;
esac
