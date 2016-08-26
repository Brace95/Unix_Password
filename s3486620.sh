# !/bin/bash

################################################################
####						Functions						####
################################################################

function fileAttack
{

	if [[ ! -e $1 ]]
	then
		echo -e "\tIncorrect Usage of fileAttack!" > /dev/stderr
		echo -e "\tfileAttack <file> <user_array> " > /dev/stderr
		exit
	fi

	while read -r line || [[ -n "$line" ]]
	do

		plain=$(echo "$line" | awk '{print tolower($0)}')
		guess=$(echo -n "$plain" | sha256sum | awk '{print $1}')

		for k in ${!user[@]}
		do
			
			if [[ "$guess" == "${user[$k]}" ]]
			then
				echo "$k password is $plain" > /dev/stderr
				unset user[$k]
			fi

		done

	done < $1

} 

function bruteAttack
{
	echo "brute" > /dev/stderr
}

################################################################
####						Main							####
################################################################

if [[ -z $1 ]]
then
	echo "Usage ./s3486620.sh <password.txt>"
	exit
fi

# echo "Loading Passwords."

declare -Ag user

while IFS='\r' read -r line || [[ -n "$line" ]]
do

	IFS=':' read -r -a broken <<< $line
	user[${broken[0]}]=${broken[1]}

done < $1

# echo "Attempting to Crack Passwords."

start=$(date +%s)

# Common
fileAttack "./common.txt"

# Dict
# Local
fileAttack "/usr/share/dict/words"
# Titan
# fileAttack "~e20925/linux.words"


end=$(date +%s)

total=$(awk "BEGIN {printf $end - $start }")

echo "Finished!"

if [[ $total < 180 ]]
then
	echo "It took $total sec(s)"
else

	echo "It took $(awk "BEGIN {printf $total / 60}") min(s)"

fi