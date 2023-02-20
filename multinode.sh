#!/bin/bash
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/flux_common.sh)"

function upnp_disable() {
 if [[ ! -f /home/$USER/zelflux/config/userconfig.js ]]; then
		echo -e "${WORNING} ${CYAN}Missing FluxOS configuration file - install/re-install Flux Node...${NC}" 
		echo -e ""
		exit
 fi
 
 if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
   if [[ $(grep -e "fluxport" /home/$USER/.fluxbenchmark/fluxbench.conf) != "" ]]; then
     echo -e ""
     echo -e "${ARROW} ${YELLOW}Removing FluxOS UPnP configuration.....${NC}"
     sed -i "/$(grep -e "fluxport" /home/$USER/.fluxbenchmark/fluxbench.conf)/d" /home/$USER/.fluxbenchmark/fluxbench.conf > /dev/null 2>&1
   else
	 echo -e "${ARROW} ${CYAN}UPnP Mode is already disabled...${NC}"
	 echo -e ""
	 exit
   fi
 else
   echo -e "${ARROW} ${CYAN}UPnP Mode is already disabled...${NC}"
   echo -e ""
   exit
 fi
 
 if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep 'apiport' | wc -l) == "1" ]]; then
	cat /home/$USER/zelflux/config/userconfig.js | sed '/apiport/d' | sudo tee "/home/$USER/zelflux/config/userconfig.js" > /dev/null
 fi
 echo -e "${ARROW} ${CYAN}Restarting FluxOS and Benchmark.....${NC}"
 echo -e ""
 sudo systemctl restart zelcash  > /dev/null 2>&1
 pm2 restart flux  > /dev/null 2>&1
 sleep 10
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

