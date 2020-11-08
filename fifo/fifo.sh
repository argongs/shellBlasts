#!bin/bash

#***********************************************#
#		fifo.sh				#
#						#
# This program is meant to simulate the FIFO	#
# scheduling algorithm.				#
#						#
#***********************************************#

#Function definition region

# ---------------------------------------------	#
# mecho ()  					#
# Short for 'modified echo'			#
# Append '[.....]'/'[error]'/'[info.]' to I/P 	#
# message in order to reflect the type of the  	#
# displayed message (i.e. whether it's just a	# 
# simple info or an error message) to the user.	#
# Parameters : $1 $2				#
# 	$1	represents the message type	#
# 	   	"i" for info			#
#		"e" for error			#
#		"d" for dots			#
#	$2	represents the message		#
# Returns : Nothing				#
# --------------------------------------------- #
mecho ()
{
	if [ $1 == "d" ]; then
		echo "[.....] $2" #For displaying messages which are a continuation of some info or error
	elif [ $1 == "e" ]; then
		echo "[error] $2" #For error messages
	elif [ $1 == "i" ]; then
		echo "[info.] $2" #For simple info messages
	else
		mecho "e" "Incorrect option supplied"
	fi
}

# --------------------------------------------- #
# display_usage () 				#
# Display usage of this script.			#
# Parameter : None				#
# Returns : Nothing				#
# --------------------------------------------- #
display_usage ()
{
	mecho "i" "Usage:"
	mecho "d" "bash fifo.sh [list of commands seperated by space] #Operator mode"
	mecho "d" "bash fifo.sh -u #Help mode"
	mecho "i" "Note:"
	mecho "d" "1. Help mode will be activated iff the first input to this program is '-u'. If it's supplied after giving the list of commands to schedule, then it will be treated as erroraneous input."
        mecho "d" "2. Help mode is meant to display only the usage of this program. Hence if the option of '-u' is discovered, then regardless of any other input only the usage information will be displayed."
	mecho "d" "3. If there're >1 instances of the same command being executed simultaneously then only each one of them(which could be anyone out of all of those instances) will be considered by this program for scheduling."
	mecho "d" "4. If a command does not exist in the list of currently executing processes, then this program will silently ignore that command and it will move on to the remaining commands."
	mecho "d" "5. Use this program to schedule only those commands whose instances can be controlled by you (either via GUI or CLI). If there exists a command which provides GUI/CLI for only one of it's many instances then it's better to avoid them because it may so happen that this program would schedule those instances first which don't provide an interface to interact with, thus making the interactable instance unavailable. "
	mecho "i" "Examples: "
	mecho "d" "$> bash fifo.sh gedit vim chromium-browser #For scheduling the commands gedit, vim and chromium-browser"
	mecho "d" "$> bash fifo.sh -u #For displaying usage"
}


# ---------------------------------------------	#
# display_info()				#
# Append '[error]' or '[info.]' to the input	#
# message in order to reflect the type of the  	#
# displayed message (i.e. whether it's just a	# 
# simple info or an error message).		#
# Parameters : $1 $2				#
# 	$1	represents the message type	#
# 	   	"i" for info and "e" for error	#
#	$2	represents the message		#
# Returns : Nothing				#
# --------------------------------------------- #
display_info ()
{
	m_type=$1
	message=$2
	if [ $m_type == "e" ]; then
		echo "[error] $message"
	elif [ $m_type == "i" ]; then
		echo "[info] $message"
	else
		display_info "e" "Incorrect option supplied"
	fi
}

#End of function definition region

#Check if user has given any input
if [ $# -eq 0 ]; then
	display_info "e" "No commands provided for scheduling"
	exit 1
fi

#Handle user's options
if [ $1 == "-u" ]; then
	display_usage
	exit 0
fi

#Let the show begin!

#mecho "i" "Command list : $@"

#Create a simple search string by using the command names given by the user and seperating them with ',' so that it can be used to tell 'ps' to return data for only those processes
search_str=$( echo "$@" | sed "s/ /,/g" )

#mecho "i" "Search string : $search_str"

#Grab the output of the 'ps' using the search string created above and request 'ps' to return only process id and command name of the requested commands in a no header display format
search_result=( $(ps -C "$search_str" -o pid,cmd --no-headers --sort pid | awk '{ print $1" "$2}') ) #awk ensures that only a command and it's pid is extracted as the output. Otherwise w/o awk, the input to those commands will also become part of the output

#Check the no. of results 
item_count=${#search_result[@]}
if [ $item_count -eq 0 ]; then
	mecho "e" "None of the input commands are currently active"
	exit 1
fi

index=0
#Declare an associative array responsible for mapping a process id to the command name
declare -A pid_to_com
#Declare a regular array to store the list of PIDs in the sorted format (because the associative array stores data in it's own order, regardless of how you set data in it. Therefore we'll use a regular array to store the pids in a sorted format.)
declare -a pid_arr 

#Grab the process id and corresponding command stored inside the 'search_result' array and store it inside an associative array with the process id as index/key and command as the corresponding value. Also display these commands and the corresponding process ids. 
#Note that the 'search_result' array contains data in the following format:
#Index : 0    1    2    3    4    5    .... 2(n-1) 2(n-1)+1
#Value : pid1 cmd1 pid2 cmd2 pid3 cmd3 .... pidn   cmdn

mecho "i" "List of input commands (in the order they will be scheduled):"
while [ $index -lt $item_count ]; do
	pid=${search_result[$(( $index ))]}
	cmd=${search_result[$(( $index+1 ))]}
	mecho "d" "Process ID : $pid, Command : $cmd"
	pid_to_com[$pid]=$cmd
	pid_arr[$(( $index/2 ))]=$pid #Since 'search_result' array contains process id at every alternate index and the 'index' value inside this loop is incremented by 2 at every index, therefore at half of the current index value we'll find the process id in each iteration
	#Stop the execution of the command that you stored inside the array (so that later on you can make it continue according to the scheduling algorithm)
	kill -SIGSTOP $pid #Note that if SIGSTOP signal is applied to a 'command', then the task started by the 'command' will become unresponsive until 'SIGCONT' signal is applied onto it
	#mecho "d" "Stop status $pid : $?"
	index=$(( $index+2 ))
done

#Display the process id and corresponding command name for all the commands that the user has provided
#for pid in ${pid_arr[*]}; do
#	mecho "d" "Process ID : $pid, Command : ${pid_to_com[$pid]}"
#done

#Now for start each process in the array in the FIFO manner (i.e. the one with lower PID will be allowed first. This is the reason why we requested 'ps' command earlier to return the requested processes in such a way that they are sorted by their PIDs)
index=0
sleep_time=5
#Keep executing and scheduling as long as there's atleast one process id present in the 'pid_arr'
while [ ${#pid_arr[@]} -gt 0 ]; do

	#Now make the command whose process id is present at the front location of process id array continue it's execution
	mecho "i" "Command ${pid_to_com[${pid_arr[$index]}]} with process id ${pid_arr[$index]} has been scheduled for execution."
	kill -SIGCONT ${pid_arr[$index]}

	mecho "d" "${pid_to_com[${pid_arr[$index]}]}[${pid_arr[$index]}] is now being executed. Awaiting it's death..."
	#Check the status of the command which was allowed to execute and keep waiting as long as the scheduled command is being executed.
	while [ -n "$( ps -p ${pid_arr[$index]} -o state --no-heading )" ]; do
		mecho "d" "${pid_to_com[${pid_arr[$index]}]}[${pid_arr[$index]}] is still alive. Let's go back to sleep..zz.."
		#If 'ps' can find the status of the requested command then it implies that the command is still being executed. Hence, make this bash program go to sleep for $sleep_time seconds, so that it does not perform busy waiting
		sleep $sleep_time
		mecho "d" "Did ${pid_to_com[${pid_arr[$index]}]}[${pid_arr[$index]}] die?"
	done

	mecho "d" "${pid_to_com[${pid_arr[$index]}]}[${pid_arr[$index]}] has been executed. It is no more."
	#Once the requested command cannot be located by 'ps' then it implies that the command has finished it's execution. Hence we now remove it from the process id array
	unset pid_arr[$(( $index ))]

	index=$(( $index+1 ))
	#And now, the next process to be executed will be on the front/next index of the process id array
done

mecho "i" "The scheduler has finished it's job. Thanks for trusting it!"
#Remove the arrays from the memory
unset pid_to_com
unset pid_arr
