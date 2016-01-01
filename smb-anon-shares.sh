#!/bin/bash
# smb-anon-shares.sh
# 12/30/2015 by Ted R (http://github.com/actuated)
# Script for checking anonymous share access
# Read from a list of UNC paths, SMB URLs, or smb_enumshares output
# 12/31/2015 Changed grep for SMB error from 'failed' to 'tree connect failed'.
# 1/1/2016 - Aesthetic change

varTempRandom=$(( ( RANDOM % 9999 ) + 1 ))
varTempFile="temp-smbanon-$varTempRandom.txt"
if [ -f "$varTempFile" ]; then rm $varTempFile; fi
varDateCreated="12/30/2015"
varDateLastMod="1/1/2015"
varInFile=""
varOutFile=""
varSetOutput="N"

# Help/usage function
function usage {
  echo
  echo "========[ smb-anon-shares.sh - Ted R (github: actuated) ]========"
  echo
  echo "Loop through a list of SMB shares to see if any allow anonymous"
  echo " access. Input file can contain UNC paths, SMB URLs, or output"
  echo " from the Metasploit smb_enumshares module."
  echo  
  echo "Created $varDateCreated, last modified $varDateLastMod."
  echo
  echo "============================[ usage ]============================"
  echo
  echo "./smb-anon-shares.sh [input file] [-o [output file]]"
  echo
  echo "[input file]       Specifies the required input file."
  echo
  echo "-o [output file]   Optionally specify an output file."
  echo "                   Must not exist."
  echo
  echo "============================[ notes ]============================"
  echo
  echo "File and directory counts are grepped from smbclient 'ls' output."
  echo " Directories: grep '   D *0'"
  echo " Files: grep '   [[:upper:]]* *[[:digit:]]* ', then exclude dirs"
  echo
}

# Check for input file
varInFile="$1"
if [ ! -f "$varInFile" ]; then echo; echo "Error: Input file doesn't exist."; usage; exit; fi

# Check for options
while [ "$1" != "" ]; do
  case $1 in
    -o ) shift 
         varSetOutput="Y"
         varOutFile=$1
         if [ "$varSetOutput" = "Y" ] && [ "$varOutFile" = "" ]; then echo; echo "Error: Output option set, but no filename given."; usage; exit; fi
         if [ "$varSetOutput" = "Y" ] && [ -f "$varOutFile" ]; then echo; echo "Error: Output file $varOutFile already exists."; usage; exit; fi
         ;;
    -h ) usage
         exit
         ;;
  esac
  shift
done

echo
echo "========[ smb-anon-shares.sh - Ted R (github: actuated) ]========"
echo
echo "Reading $varInFile for SMB UNC paths."
echo "SMB URLs and smb_enumshares (DS) results will be converted."
echo
if [ "$varSetOutput" = "Y" ]; then
  echo "Output file: $varOutFile"
  echo
fi
read -p "Press Enter to confirm..."
echo

varLine=""
while read varLine; do
  varTarget=""
  varResult=""
  varCheckUNC=$(echo "$varLine" | grep -i '^//.*/.*')
  varCheckURL=$(echo "$varLine" | grep -i '^smb://.*/.*')
  varCheckMSF=$(echo "$varLine" | grep -i '^\[+\].*:445' | grep -v '(I)')

  if [ "$varCheckUNC" != "" ]; then
    varTarget="$varLine"
  elif [ "$varCheckURL" != "" ]; then
    varURLHost=""
    varURLShare=""C
    varURLHost=$(echo "$varLine" | awk -F '/' '{print $3}')
    varURLShare=$(echo "$varLine" | awk -F '/' '{print $4}')
    varTarget="//$varURLHost/$varURLShare"
  elif [ "$varCheckMSF" != "" ]; then
# Process MSF Line into UNC path
    varMSFHost=""
    varMSFShare=""
    varMSFHost=$(echo "$varLine" | awk '{print $2}' | awk -F ':' '{print $1}')
    varMSFShare=$(echo "$varLine" | awk -F '-' '{print $2}' | tr -d '^ ' )
    varTarget="//$varMSFHost/$varMSFShare"
  fi

  if [ "$varTarget" != "" ]; then
    varResult=""
    varTempRandom=$(( ( RANDOM % 9999 ) + 1 ))
    varTempFile2="temp-smbout-$varTempRandom.txt"
    if [ -f "$varTempFile2" ]; then rm $varTempFile2; fi
    smbclient "$varTarget" -E -N -c ls 2> $varTempFile2
    varResult=$(cat $varTempFile2 | grep 'tree connect failed' | awk -F ':' '{print "[-]" $2}' )

    if [ "$varResult" = "" ]; then
      varFileCount=""
      varDirCount=""
      varFileCount=$(cat $varTempFile2 | grep '   [[:upper:]]* *[[:digit:]]* ' | grep -v '   D *0' | wc -l)
      varDirCount=$(cat $varTempFile2 | grep '   D *0' | wc -l)
      varResult="[+] Connected [$varFileCount F / $varDirCount D]"
    fi

    rm $varTempFile2
    printf "%-38.38s %s \n" "$varResult" "$varTarget" >> $varTempFile
  fi

done < $varInFile

echo "===========================[ results ]==========================="
echo
cat $varTempFile
echo
echo "=============================[ fin ]============================="
echo
if [ "$varSetOutput" = "Y" ]; then
  mv $varTempFile $varOutFile
else
  rm $varTempFile
fi
