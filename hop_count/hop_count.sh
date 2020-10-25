#!bin/bash

#---------------------------------------#
#			hop_count.sh				#
#	Read from a CSV file a list of IP	# 
#	addresses and traceroute them to 	#
#	obtain the no. of hops required to 	#
#	reach there.						#
#---------------------------------------#

#Funxn. definition region
display_usage()
{
	echo "[info] Usage:"
	echo "[....] $> bash hop_count.sh csv_file"
	echo "[....] 1. csv_file should be a CSV formatted file with the third column containing the IPv4 addresses"
}

#############End of region

#Check if the input file is provided and it's of the correct format
file_name=$1
if [[ -z "$file_name" ]]; then
	echo "[error] File name not provided"
	display_usage
	exit 1
fi

if [[ -f "$file_name" ]]; then
	echo "[info] Located "$file_name"" 
	if [[ ${file_name[@]: -4} == \.csv ]]; then
		echo "[info] Found correct file. Proceeding to perform tracerouting..."
	else
		echo "[error] Input file needs to have .csv extension"
		display_usage
		exit 1
	fi
else
	echo "[error] Couldn't find "$file_name""
	exit 1
fi

#Initiate data fetching assuming that the third column of the data contains the IP address
ipv4_addrs=( $(cat "$file_name" | sed "s/,/ /g" | sed "1d" | awk '{print $3}') )

#Check if the 3rd column is blank
if [ -z $ipv4_addrs ]; then
	echo "[error] 3rd column is found to be blank"
	display_usage
	exit 1
fi

#Create an associative array
declare -A ip_to_hop

#Perform tracerouting for each ipv4 address obtained from above, obtain the no. of hops and store it in the associate array by mapping ipv4 address to the corresponding hop count
for ipv4_addr in ${ipv4_addrs[@]}; do
	echo "[info] Tracerouting $ipv4_addr..."
	hop_count=$(traceroute -I $ipv4_addr | wc -l)
	hop_count=$(( $hop_count-1 ))
	echo "[info] Done. Hop count from this machine to $ipv4_addr : $hop_count"
	ip_to_hop[$ipv4_addr]=$(( $hop_count ))
done

#Display the results
echo "[info] Consolidated results:"
for ipv4_addr in ${!ip_to_hop[@]}; do
	echo "[....] $ipv4_addr : ${ip_to_hop[$ipv4_addr]} hops away"
done
