# !/bin/bash

# Author: 	Brandon Stenhouse (s3486620)
# Date:		30/08/2016
# Version:	1.1.1

AWK='/usr/bin/awk'
SEQ='/usr/bin/seq'
DATE='/bin/date'
READLINK='/bin/readlink'

####################################################################
####			         	Functions                			####
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

		plain=$(echo "$line" | $AWK "{print tolower($0)}")
		
		comparePassword "$plain"

	done < "$(eval $READLINK -f "$1")"

} 

function bruteAttack
{
	# Timer to stop after 4 minutes on 1 password
	timer_start=$($DATE +%s)
	timer_end=240
	cmd=""

	for i in $($SEQ 1 5)
	do
		range="{a..z}"
		cmd="$cmd$range"

		echo -e "\tLength: $i" > /dev/stderr

		for plain in $(eval echo -n $cmd)
		do

			comparePassword "$plain"

			# Check if times up
			dif=$($AWK "BEGIN {printf $($DATE +%s) - $timer_start}")
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
		echo -e "\tIncorrect Usage of ComparePassword!" > /dev/stderr
		echo -e "\tComparePassword <Plain Password>" > /dev/stderr
		exit
	fi

	guess=$(echo -n "$1" | sha256sum | $AWK "{print $1}")

	# Compare the password to the passwords in file
	for k in "${!user[@]}"
	do
		
		if [[ "$guess" == "${user[$k]}" ]]
		then
			echo -e "\t\t$k password is $1" > /dev/stderr
			unset user[$k]
		fi

	done
}

####################################################################
####        				Main			                	####
####################################################################

if [[ -z $1 ]]
then
	echo "Usage ./s3486620.sh <password.txt>"
	exit
fi

echo "Loading Users..."

# echo "Loading Passwords."

declare -Ag user

while IFS='\r' read -r line || [[ -n "$line" ]]
do

	IFS=':' read -r -a broken <<< "$line"
	user[${broken[0]}]=${broken[1]}

done < "$1"

echo "Attempting to Crack Passwords."

start=$($DATE +%s)

echo "$start"

echo
echo -e "\tAttempting Common"
# Common
# Local
# fileAttack "./common.txt"
# Titan
fileAttack "~s3486620/common.txt"
echo
echo -e "\tAttempting Dictionary"
# Dict
# Local
# fileAttack "/usr/share/dict/words"
# Titan
fileAttack "~e20925/linux.words"

echo
echo -e "\tAttempting Brute Force Limit 4 minutes"
# Brute
bruteAttack

echo "Finished!"

end=$($DATE +%s)

total=$($AWK "BEGIN {printf $end - $start}")

echo "$end"

if [[ $total -lt 180 ]]
then
	echo "It took $total sec(s)"
else

	echo "It took $($AWK "BEGIN {printf $total / 60}") min(s)"

fi
