#!bin/bash
#-------------------------------------------------------#
#					read_csv.sh							#	
#	This shell program is meant for reading CSV files	#
#	and displaying them.								#
#-------------------------------------------------------#

#Usage of this program:
#$> bash read_csv.sh [-i] input_file_name [-r] output_file_name
#Note :
#1. 'i' is an optional argument. Use it to make the program include first column and row as a part of data. In the absence of this option, the first column and row will be discarded.
#2. 'r' is also an optional argument. Use it to make the program retain the 2D row-column structure of the data, instead of converting into a flat 1D array. Note that while 1D array form of output provides no. of rows and columns as the first 2 elements of the output, 2D array form of output doesn't contain any such thing. Instead, it simply presents the contents of the CSV file by replacing the ',' with " "(space).
#3. 'input_file_name' is a mandatory argument. This file will be the one on which this program will operate upon. This file should be a CSV formatted file, whose file extension should be '.csv'. Also avoid supplying a CSV file with missing values as input, because this program will skip over the blank entries and lead to generation of an erroraneous output.
#4. 'output_file_name' is an optional argument. The value of this argument will act as the name of the file in which the output will be placed.
#Note that the output file will contain data in the following format:row_count column_count csv_data_seperated_by_space


#Extract file name from the arguments and set the offset for data extraction
if [ $1 == "-i" ];then
	#include_flag=1
	#If the first argument is an option then the second one should be a CSV filename
	file_name=$2
	#and the third one should be the either the output file name or the 'r' option
	if [ $3 == "-r" ]; then
		output_file_name=$4
		#Set retain_structure variable to 1 to tell the shell program to retain the 2D structure of the data in the output file
		retain_structure=$(( 1 ))
	else
		output_file_name=$3
		#Set retain_structure variable to 0 to tell the shell program to convert the 2D structure of the data into a flat 1D array and then store it into the output file
		retain_structure=$(( 0 ))
	fi
	#Set the offset to 0 to indicate the acceptance of first row and column
	offset=0
	#echo "[info] You've used 'i' option, hence first row and column will be retained."
else
	#include_flag=0
	#If the first argument is not '-i', then it should be a CSV filename
	file_name=$1
	#and the second one should be the either the output file name or the 'r' option
	if [ $2 == "-r" ]; then
		output_file_name=$3
		#Set retain_structure variable to 1 to tell the shell program to retain the 2D structure of the data in the output file
		retain_structure=$(( 1 ))
	else
		output_file_name=$2
		#Set retain_structure variable to 0 to tell the shell program to convert the 2D structure of the data into a flat 1D array and then store it into the output file
		retain_structure=$(( 0 ))
	fi
	#Set the offset to 1 to indicate the rejection of first row and column
	offset=1
	#echo "[info] You didn't use 'i' option, hence first row and column will be discarded."
fi

#Use the filename and the corresponding offset to fetch the contents of the file
if [[ ( -f $file_name ) && ( $file_name == *\.csv ) ]]; then
	#echo "[info] Input file successfully located and is found to possess .csv extension. Proceeding for data parsing..."
	#Extract the CSV data. Also replace "," with " ". Also, don't forget to remove the first row and first column if the offset is set.
	if [ $offset -eq 1 ];then
		#sed "s/,/ /g" #performs replacement of "," with ""(blank)
		#sed "1d" #performs removal of the first line from the input text
		#sed "s/^[[:digit:]]\+//g" #performs replacement of lines starting with a one or more digit. Note the usage of \+. It allows us to select >=1 occurences of the preceding regex. The usage of this symbol indicates that we're using basic regex over here (as compared to PCRE)
		file_contents=`sed "s/,/ /g" $file_name | sed "1d" | sed "s/^[[:digit:]]\+//g"`
	else
		file_contents=`sed "s/,/ /g" $file_name`
	fi
	#Obtain no. of rows present in the CSV data
	#NOTE : `echo $var` renders the contents of var by skipping over the line endings. However, echo "$var" preserves the line endings of content present inside 'var'. Therefore, use `echo "$var" | wc -l`, instead of `echo $var | wc -l`, in order to obtain the no. of lines present inside the content stored in 'var' via wc -l. 
	#Convert the contents obtained from the file into a single dimension array
	content_as_arr=( $file_contents )
	#Obtain properties of the CSV data (no. of elements, rows and columns)
	line_count=( `echo "$file_contents" | wc -l` )
	row_count=$(( $line_count ))
	element_count=$(( ${#content_as_arr[@]} ))
	col_count=$(( $element_count/$row_count ))
else
	echo "[error] Incorrect input file!"
	exit 1 #exit code 1 for incorrect inputs
fi

#Display the CSV file contents summary
#echo "[info] Parsing procedure complete."
#echo "[info] No. of elements : $element_count"
#echo "[info] Dimension : $row_count x $col_count"
	
#echo "[info] Extracted data : "
#echo "$file_contents"

#Write the parsed data into the output file

#Give a default name to the output file if not provided by the user
if [ -z $output_file_name ];then
	output_file_name="output"
fi

#Store the data in the file in either 2D form OR 1D form, depending upon the 'retain_structure' val
if [ $retain_structure -eq 1 ]; then
	echo "$file_contents" > $output_file_name
else
	echo "$row_count $col_count ${content_as_arr[@]}" > $output_file_name
fi
