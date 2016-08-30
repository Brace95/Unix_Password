#!/bin/bash

# Author: 	Brandon Stenhouse (s3486620)
# Date:		30/08/2016
# Version:	1.2.0

####################################################################
####					Functions								####
####################################################################

function fileAttack
{

	if [[ ! -n $1 ]]
	then
		echo -e "\tIncorrect Usage of fileAttack!" > /dev/stderr
		echo -e "\tfileAttack <file>" > /dev/stderr
		exit
	fi

	while IFS='\r' read -r line || [[ -n "$line" ]]
	do

		plain=$(echo "$line" | awk '{print tolower($0)}')
		
		comparePassword "$plain"

	done < "$(eval readlink -f "$1")"

} 

function bruteAttack
{
	# Timer to stop after 5 minutes
	timer_start=$(date +%s)
	timer_end=300
	cmd=""

	for i in $(seq 1 5)
	do

		range="{a..z}"
		cmd="$cmd$range"

		echo -e "\tLength: $i" > /dev/stderr

		for plain in $(eval echo -n $cmd)
		do

			comparePassword "$plain"

			# Check if times up
			dif=$(awk "BEGIN {printf $(date +%s) - $timer_start}")
			if [[ "$dif" -gt "$timer_end" ]]
			then
				echo -e "\tTime-Up" > /dev/stderr
				echo -e "\tStopped at $plain"
				return
			fi

		done

	done
	
}

function comparePassword
{

	if [[ ! -n $1 ]]
	then
		return
	fi

	guess=$(echo -n "$1" | sha256sum | awk '{print $1}')

	# Compare the password to the passwords in file
	for k in "${!user[@]}"
	do
		
		if [[ "$guess" == "${user[$k]}" ]]
		then
			echo -e "\t\t$k password is $1" > /dev/stderr
			unset user[$k]

			if [[ ${#user[@]} -eq 0 ]]
			then
				echo "All Paswords Found!!"
				exit
			fi
		fi

	done

}

####################################################################
####							Main							####
####################################################################

echo "Loading Users..."

declare -Ag user

while IFS='\r' read -r -t 1 line || [[ -n "$line" ]]
do

	IFS=':' read -r -a broken <<< "$line"
	user[${broken[0]}]=${broken[1]}

done < "${1:-/dev/stdin}"

if [ ${#user[@]} -eq 0 ]
then
    echo "Error with user input"
    exit
fi

echo "Attempting to Crack Passwords."

start=$(date +%s)

echo
echo -e "\tAttempting Common"
fileAttack "~s3486620/common.txt"

echo
echo -e "\tAttempting Dictionary"
fileAttack "~e20925/linux.words"

echo
echo -e "\tAttempting Brute Force Limit 5 minutes"
bruteAttack

end=$(date +%s)
total=$(awk "BEGIN {printf $end - $start}")

echo "Finished!"

if [[ $total -lt 180 ]]
then
	echo "It took $total sec(s)"
else

	echo "It took $(awk "BEGIN {printf $total / 60}") min(s)"

fi
