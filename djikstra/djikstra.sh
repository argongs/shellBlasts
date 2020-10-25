#!bin/bash
#-------------------------------------------------------#
#					djikstra.sh							#	
#	This shell program is meant for simulating			#
#	Djikstra's algorithm by using the adjacency matrix	# 
#	from a CSV file.									#
#-------------------------------------------------------#

#Global variables
declare -A name_to_no # to map a vertex name to a vertex no
declare -A no_to_name # to map a vertex no to a vertex name

#Function definition region
display_usage()
{
	echo "[info] Usage:" 
	echo "[....] $> bash dijkstra.sh [-m map_file] input_file_name start_vertex end_vertex #Operate mode"
	echo "[....] $> bash dijkstra.sh -u #Help mode"
	echo "[info] Note :"
	echo "[....] 1. 'm' is an optional argument. Usage of this argument will allow you to map a name/string to a vertex of the adjacency matrix. Thus a map_file is necessary if you wish to make use of this argument."
	echo "[....] 2. This map file should be formatted as a CSV file, with the first column being the vertex(or basically serial no.) and the second column being the name of that vertex. Hence, this program will effectively map the first column with the second column to understand names."
	echo "[....] 3. In the absence of usage of 'm' option, the program will treat the vertex no. as the name of the vertex."
	echo "[....] 4. 'u' is an optional argument. Usage of this argument will allow you to see the usage of this program."
	echo "[....] 5. 'input_file_name' is a mandatory argument. This file will be the one on which this program will operate upon. This file should be a CSV formatted file, whose file extension should be '.csv'. Also avoid supplying a CSV file with missing values as input, because this program will skip over the blank entries and lead to generation of an erroraneous output."
	echo "[....] 6. Ensure that the CSV file contains a square matrix form of data, otherwise this program will become incapable of determining the shortest path"
	echo "[....] 7. 'start_vertex' and 'end_vertex' are also necessary arguments. The value of these arguments will be used to calculate the shortest path."
	echo "[....] 8. If the map file option is not selected, then the 'start_vertex' and 'end_vertex' need to be of integer type. However, if the map file option is selected then, these arguments need to be of string type so that they can be mapped with the vertices. Doing anything otherwise might lead to unwanted errors/output."
}

create_mapper()
{
	local parsed_data_file="output"
	local map_file=$1
	#local vertex_name=$2
	
	bash read_csv.sh -i $map_file $parsed_data_file
	#Obtain exit status of the CSV file reading operation via read_csv.sh
	local exit_status=$?
	#If the exit status is >=1, then display the usage of this program and then exit
	if [ $exit_status -eq 1 ];then
		display_usage
		exit 1
	fi
	
	local table_data=( $(cat $parsed_data_file) )
	local row_count=$(( ${table_data[0]} ))
	local col_count=$(( ${table_data[1]} ))
	local element_count=$(( $row_count*$col_count ))

	#Following row count and col count the next 'col_count' no. of items will be the contents of the first row of the CSV file, i.e. the row header. Skip past them to obtain the data from the rows ahead.
	local offset=$(( 2+$col_count )) # First 2 items + Next col_count items (First row)
	local index=0
	local res_index=0
	local vertex_name
	local vertex_no
	local elements_to_scan=$(( $element_count-$col_count )) #No. of elements to scan will be total elements - no. of elements present in the first row
	
	#Initialise the associative arrays
	for((index; index<$elements_to_scan; index=index+$col_count))
	{
		res_index=$(( $offset+$index ))
		vertex_name="${table_data[$((res_index+1))]}"
		vertex_no=${table_data[res_index]}
		#echo "Index 0 : $vertex_no, Index 1 : $vertex_name"
		name_to_no["$vertex_name"]=$vertex_no #Vertex name to no
		no_to_name[$vertex_no]="$vertex_name" #Vertex no to name
	}
	
	#Remove the output file, since it's usage is finished
	rm $parsed_data_file
	
	#return $vertex_no
}

#############################################End of function definition region

if [ $1 == "-u" ];then
	display_usage
	exit 0
elif [ $1 == "-m" ];then
	map_mode=1
	#If the first argument is '-m', then 
	#the second argument should be the map file name
	map_file=$2
	#and the third argument should be the adjacent matrix file
	adj_mat_file=$3
	#and the third and fourth arguments should be the names of the starting and ending vertices respectively
	start_vertex_name=$4
	end_vertex_name=$5
	
	#If either starting vertex or ending vertex is not provided then it's an issue
	if [ -z $start_vertex_name ]; then
		echo "[error] Starting vertex is not provided!"
		display_usage
		exit 1
	fi
	if [ -z $end_vertex_name ];then
		echo "[error] Ending vertex is not provided!"
		display_usage
		exit 1
	fi
	
	echo "[info] Initiating shortest path calculation from $start_vertex_name to $end_vertex_name ..."
	
	#Create 2 associative arrays to map vertex name and no and do the same thing in reverse using the mapping file
	create_mapper "$map_file"
	
	start=0
	end=0
	for index_name in "${!name_to_no[@]}"; do
		#Search for a match of starting and ending vertex names in the keys of the name to no associate array. If the match is found then fetch the corressponding vertex nos.
		if [[ $index_name =~ .*"$start_vertex_name".* ]];then
			start=${name_to_no[$index_name]}
		fi
		if [[ $index_name =~ .*"$end_vertex_name".* ]];then
			end=${name_to_no[$index_name]}
		fi
	done
	
	if [ $start -eq 0 ]; then
		echo "[error] Could not locate $start_vertex_name in $map_file"
		echo "[info] Terminating the parsing procedure"
		display_usage
		exit 1
	fi
	if [ $end -eq 0 ]; then
		echo "[error] Could not locate $end_vertex_name in $map_file"
		echo "[info] Terminating the parsing procedure"
		display_usage
		exit 1
	fi
	
	#Convert the vertex no. into an index
	start=$(( $start-1 )) #Decrease one, to convert the vertex no. into the index
	end=$(( $end-1 )) #Decrease one, to convert the vertex no. into the index
else
	map_mode=0
	echo "[info] Initiating shortest path calculation from $2 to $3 ..."

	#If no option is selected then, the first argument should be the CSV file name where the adjacency matrix is stored
	adj_mat_file=$1
	
	start_vertex_name=$2
	end_vertex_name=$3
	
	#If either starting vertex or ending vertex is not provided then it's an issue
	if [ -z $start_vertex_name ]; then
		echo "[error] Starting vertex is not provided!"
		display_usage
		exit 1
	fi
	if [ -z $end_vertex_name ];then
		echo "[error] Ending vertex is not provided!"
		display_usage
		exit 1
	fi
	
	#If either starting vertex or ending vertex turns out to be a string instead of a no. then it's an issue
	if [[ $start_vertex_name == [[:alpha:]]* ]]; then
		echo "[error] Starting vertex is incorrect!"
		echo "[info] If you wish to use a name instead of a no. for a vertex then provide a mapping file"
		display_usage
		exit 1
	fi
	if [[ $end_vertex_name == [[:alpha:]]* ]];then
		echo "[error] Ending vertex is incorrect!"
		echo "[info] If you wish to use a name instead of a no. for a vertex then provide a mapping file"
		display_usage
		exit 1
	fi
	
	
	#Let the starting vertex be obtained from the second argument
	start=$(( $start_vertex_name-1 )) #Decrease one, to convert the input serial no. into the index
	#And let the destination vertex be obtained from the third argument
	end=$(( $end_vertex_name-1 )) #Decrease one, to convert the input serial no. into the index
fi

parsed_data_file="output"
bash read_csv.sh $adj_mat_file $parsed_data_file

#Obtain exit status of the CSV file reading operation via read_csv.sh
exit_status=$?
#If the exit status is >=1, then display the usage of this program and then exit
if [ $exit_status -eq 1 ];then
	display_usage
	exit 1
fi

#Obtain the parsed data as an array
parsed_data=( $(cat $parsed_data_file) )
#Remove the parsed_data file
rm $parsed_data_file

#An associated array for storing the parsed data as an apparent '2D' array
declare -A adj_mat

#Extract the dimensions of the CSV file data
row_count=${parsed_data[0]}
col_count=${parsed_data[1]}

#Check if the parsed data is capable of creating a square matrix
if [ $row_count -ne $col_count ]; then
	#If the data cannot form a square matrix then display error and exit
	echo "[error] Input data is not a square matrix! Cannot apply Djikstra's algo. on it"
	exit 1
fi

index=0
row_index=0
col_index=0

#Enter the parsed data into an apparent 2D array
for i in ${parsed_data[@]:2};do
	adj_mat[$row_index,$col_index]=$(( $i ))
	let "col_index++"
	if [ $col_index -eq $col_count ];then
		col_index=0
		let "row_index++"
	elif [ $row_index -eq $row_count ];then
		break
	fi
done

#Display contents of the apparent 2D array

#Declare a temporary array for output formatting
#declare -a temp
#for((row_index=0; row_index<$row_count; row_index++))
#{
#	for((col_index=0; col_index<$col_count; col_index++))
#	{
#		temp[col_index]=${adj_mat[$row_index,$col_index]}
#	}
#	echo ${temp[@]}
#}
#unset temp

#Declare 'visited', 'distance' and 'predecessor' arrays
declare -a visited
declare -a distance
declare -a predecessor

#Since, row_count == col_count, therefore we can say
vertex_count=$(( $row_count ))

#If either starting vertex or ending vertex is more than the total no. of vertices then it's an issue
if [ $start -gt $vertex_count ]; then
	echo "[error] Starting vertex is incorrect!"
	display_usage
	exit 1
fi
if [ $end -gt $vertex_count ];then
	echo "[error] Ending vertex is incorrect!"
	display_usage
	exit 1
fi

#Let inifinite distance in the current context be 128
INF=128

#Initialise the 'visited', 'distance' and 'predecessor' arrays
index=0
for((index=0; index<vertex_count; index++))
{
	visited[$index]=$(( 0 ))	
	distance[$index]=$(( $INF ))
	predecessor[$index]=$(( $index ))
}

#Set the properties of the starting vertex
visited[$start]=$(( 1 ))
distance[$start]=$(( 0 ))
predecessor[$start]=$(( $start ))

current_vertex=$(( $start ))
vertices_visited=$(( 1 ))

#Initiate the Djikstra's algorithm
while [ $vertices_visited -le $vertex_count ]; do
	
	#echo "Visited vertex : $current_vertex"
		
	#Scan all the adjacencies of the current vertex
	for((index=0; index<$vertex_count; index++))
	{
		#Check if the scanned vertex is visited
		if [ ${visited[$index]} -eq 0 ];then
			#If the scanned vertex is not visited then compare the distance attribute of the scanned vertex with the distance in between the current vertex and scanned vertex (obtained via the sum of the distance attribute of the current vertex and the adjacency value of current vertex and the scanned vertex)
			#echo "Distance vector value ${distance[$current_vertex]}"
			current_to_scan=$(( ${adj_mat[$current_vertex,$index]}+${distance[$current_vertex]} ))
			if [ $current_to_scan -lt ${distance[$index]} ];then		
				#If the current vertex provides a smaller path to the scanned vertex as compared to the path it already had, then update the 'distance' and 'predecessor' property of the scanned vertex
				distance[$index]=$(( $current_to_scan ))
				predecessor[$index]=$(( $current_vertex ))
			fi
		fi
	}
	
	#Find the next vertex to visit, by searching for the one which has not yet been visited.
	for((index=0; index<$vertex_count; index++))
	{
		if [ ${visited[$index]} -eq 0 ];then
			min_index=$(( $index ))
			break
		fi
	}
	
	#Now search for a vertex which has not been visited and at is the one with the minimum 'distance' attribute value at the same time
	for((index=0; index<$vertex_count; index++))
	{
		if [ ${visited[$index]} -eq 0 ];then
			if [ ${distance[$index]} -lt ${distance[$min_index]} ];then
					min_index=$index
			fi
		fi
	}
	
	current_vertex=$(( $min_index ))
	visited[$current_vertex]=$(( 1 ))
	let "vertices_visited++"
done


#Prepare the path
declare -a path
path_string=""
index=0
temp_vertex=$(( $end ))

#Obtain the shortest path from start to end
if [ $map_mode -eq 0 ];then
	while [ $temp_vertex -ne $start ]; do
		path[index]=$(( $temp_vertex+1 ))
		path_string+="${path[index]}<--"
		temp_vertex=${predecessor[$temp_vertex]}	
		let "index++"
	done
	#Append the last predecessor
	path[index]=$(( $temp_vertex+1 ))
	path_string+="${path[index]}"
else
	while [ $temp_vertex -ne $start ]; do
		path[index]=${no_to_name[$(( $temp_vertex+1 ))]}
		path_string+="${path[index]}<--"
		temp_vertex=${predecessor[$temp_vertex]}	
		let "index++"
	done
	#Append the last predecessor
	path[index]=${no_to_name[$(( $temp_vertex+1 ))]}
	path_string+="${path[index]}"
fi

echo "[info] Done."
echo "[info] Shortest path from $start_vertex_name to $end_vertex_name : $path_string"
echo "[info] Total cost involved = ${distance[$end]}"
unset path

