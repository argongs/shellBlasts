#!/bin/bash

#***************************************#
# 	fire_requests.sh		#
#					#
# This shell script will fire		#
# large no. of hits to the		# 
# requested website by making use	# 
# of 'GNU wget' tool.	     		#
#					#
#***************************************#

#Check if the user has supplied an address as well as no. of requests
if [ $# -ne 2 ];then
		echo "Error! Incorrect no. of options supplied"
		echo "Usage : bash fire_requests.sh <url> <no. of requests>"
		exit
fi

#Connect to the requested address via for 'max_hits' no. of times
echo "Initiate firing procedure..."
max_hits=$2
address=$1
i=0
while [ $i -lt $max_hits ];do
	#Perform the request using wget
	#Since, wget will store the webpage into a file and since we're only concerned with firing requests therefore, it's better to tell wget to delete the file after it downloads it via the --delete-after option. Also tell wget to not create any directories while performing the request via the -nd option
	wget -nd --delete-after $address
	i=$(( $i + 1 ))
	echo "Hit no. $i to $address completed."
done

echo "Finished firing procedure."
