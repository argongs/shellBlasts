#!/bin/bash

#Check if the user has supplied a hostname
if [ -z $1 ]
	then
		echo "Usage : bash router_counter.sh [host_name]"
fi

#Define what an IPv4 and IPv6 address looks like
ipv4_regex="([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}"
#"([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}"
#([[:digit:]]{1,3}\.?){4}
ipv6_regex="([[:xdigit:]]{0,4}\:){2,7}[[:xdigit:]]{0,4}"
#([[:xdigit:]]{0,4}\:?){8}
full_regex="$ipv4_regex"
#"($ipv4_regex|$ipv6_regex)"

#Now extract the addresses
#[note that we are using PCRE form of grep, hence P option is necessary]
ip_addresses=( `host "$1" | grep -woP $full_regex` )
#Report the IP addresses
echo "List of public IP addresses of $1:"
echo "> ${ip_addresses[@]}"
#Declare an array for storing hop counts
declare -a hop_count
index_var=0

#Now for each of the ip addresses obtained, find the list of routers encountered to reach it
for ip_addr in ${ip_addresses[@]}; do
	echo ">> Tracing down the route to $ip_addr..."
	trace_data=`traceroute "$ip_addr"` #trace the route
	router_count=`echo "${trace_data[*]}" | grep -cP "^[[:space:]]{1,2}[[:digit:]]"` #extract router count
	#Update the hop count array
	hop_count[$(( $index_var ))]=$(( $router_count ))
	index_var=$(( $index_var+1 ))
	echo ">> Routers encountered = $router_count"
	routers=( `echo $trace_data | grep -woP $full_regex` ) #extract the ip addresses of the routers
	echo ">> List of encountered routers (whose ip address could be obtained):"
	for router in ${routers[@]}; do
		echo ">>> $router"
	done
done

#Obtain the minimum hop count possible
min_index=$(( 0 ))
temp_index=$(( 0 ))
for i in ${hop_count[@]}; do
	if [ $i -lt ${hop_count[ $(( min_index )) ]} ]
		then
			min_index=$(( $temp_index ))
	fi
	temp_index=$(( $temp_index+1 ))
done

#Display the minimum no. of hops
suffix=""
if [ ${hop_count[ $(( min_index )) ]} -gt $(( 1 )) ]
	then
		suffix="s"
fi		
echo "IP address ${ip_addresses[ $(( min_index )) ]} is the closest one with a distance of ${hop_count[ $(( min_index )) ]} hop$suffix from this machine."

#Connect to the IP address in the browser 
echo "Opening ${ip_addresses[ $(( min_index )) ]} in the browser..."
exit_status=`xdg-open "https://${ip_addresses[ $(( min_index )) ]}"` 
echo "Done."
