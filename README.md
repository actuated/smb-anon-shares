# smb-anon-shares
Shell script for testing anonymous file share access with Smbclient. Input can be UNC paths, SMB URLs, or Metasploit smb_enumshares results.

# Usage
```
./smb-anon-shares.sh [inputfilename] [-o [outputfilename]]
```

* **[inputfilename]** represents the name of the input file. This must be the first parameter. The script will read each line of the input file, checking to see if it is a UNC path, SMB URL, or an SMB file share enumerated by the Metasploit smb_enumshares module.
* **-o [outputfilename]** allows you to optionally specify an output file.

# Parsing
**Input**
* The script looks for UNC paths by grepping for `'^//.*/.*'`.
* SMB URLs are identified by grepping for `'^smb://.*/.*'`, and then converting the host and share into a UNC path.
* Metasploit smb_enumshares output is identified by grepping for `'^\[+\].*:445'`, excluding IPC shares by grepping for `(I)`, and then converting the host and share into a UNC path.

**Testing**
* The script connects by using the command `smbclient [target] -E -N -c ls`, redirecting the output to a temp file.
* The temp file is grepped for `'tree connect failed'`, which is used to report the error given.
* If no failure message is found, the temp file will be checked for files and directories before it is deleted.
  * Directories are counted by grepping for `'   D *0'`.
  * Files are counted by grepping for `'   [[:upper:]]* *[[:digit:]]* '`, and then excluding directories.

# Example
## Input File
```
//192.168.1.1/documents
smb://192.168.1.1/music/
//192.168.1.1/adsfsdfsdf
//192.168.1.1/C$
[-] 192.168.1.1:139 - Login Failed: The SMB server did not reply to our request
[*] 192.168.1.1:445 - Windows 7 Service Pack 1 (Unknown)
[+] 192.168.1.1:445 - ADMIN$ - (DS) Remote Admin
[+] 192.168.1.1:445 - D$ - (DS) Default share
[+] 192.168.1.1:445 - IPC$ - (I) Remote IPC
[+] 192.168.1.1:445 - scans - (DS) 
[+] 192.168.1.1:445 - Videos - (DS) 
[*] Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```

## Example Run
```
# ./smb-anon-shares.sh test.txt -o out.txt

========[ smb-anon-shares.sh - Ted R (github: actuated) ]========

Reading test.txt for SMB UNC paths.
SMB URLs and smb_enumshares (DS) results will be converted.

Output file: out.txt

Press Enter to confirm...

===========================[ results ]===========================

[+] Connected [6 F / 77 D]             //192.168.1.1/documents 
[+] Connected [1 F / 8 D]              //192.168.1.1/music
[-] NT_STATUS_BAD_NETWORK_NAME         //192.168.1.1/adsfsdfsdf 
[-] NT_STATUS_ACCESS_DENIED            //192.168.1.1/C$ 
[-] NT_STATUS_ACCESS_DENIED            //192.168.1.1/ADMIN$ 
[-] NT_STATUS_ACCESS_DENIED            //192.168.1.1/D$ 
[+] Connected [4 F / 10 D]             //192.168.1.1/scans 
[+] Connected [0 F / 5 D]              //192.168.1.1/Videos 

=============================[ fin ]=============================
```
