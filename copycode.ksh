#! /bin/ksh
# command syntax: arg1 is source, arg2 is dest
# use like this: ksh copycode.ksh $cust_script $cust_script/backups
# written by Travis Cazes travis@sagehealth.tech sagehealth.tech
logfile="$1/../copycode.log"
linesallowed=5000
timestamp() {
        ts=$(date +"%Y-%m-%d %H:%M:%S ")
        echo -n $ts "- "
}
logErrorAndExit() {
    local message=$1
    timestamp >>$logfile 2>&1
    echo "ERROR: $message" >>$logfile 2>&1
    exit 1
}
timestamp >>$logfile 2>&1
echo "Running copycode.ksh"  >>$logfile 2>&1
echo "Supplied dir: $1, Destination dir: $2" >>$logfile 2>&1
cd $1 || logErrorAndExit "Failed to change to source directory $1"
date=$(date +"%m-%d-%Y") #get date in nice format
find . -maxdepth 1 -mtime -1 -type f -not -path '*/.*' | #find updated in last day, files only, no subdirectories, no hidden files
while read -r line; do #loop through list of files
        cd $1 || logErrorAndExit "Failed to change to source directory $1"
        file="${line##*/}"
        filenoext="${file%.*}"
        base=$(basename "$line")
        #echo "$file $filenoext $base" #debugging
        timestamp >>$logfile 2>&1
        echo "Making directory cmd: mkdir -p -m775 $2/$filenoext" >>$logfile 2>&1
        mkdir -p -m775 "$2/$filenoext" || logErrorAndExit "Failed to create directory $2/$filenoext"
        timestamp >>$logfile 2>&1
        echo "Copy Command: cp $1/$base $2/$filenoext/$date-$base" >>$logfile 2>&1
        cp "$1/$base" "$2/$filenoext/$date-$base" || logErrorAndExit "Failed to copy $1/$base to $2/$filenoext/$date-$base"
        timestamp >>$logfile 2>&1
        echo "Zip cmd for vcml: zip -q $sftp_xfer/source_code_backup/$base.zip $1/$base" >>$logfile 2>&1 || logErrorAndExit "Failed to zip $1/$base to $sftp_xfer/source_code_backup/$base.zip"
        zip -q "$sftp_xfer/source_code_backup/$base.zip" "$1/$base" #copies for vcml
        timestamp >>$logfile 2>&1
        echo "Changing Directory to: $2/$filenoext" >>$logfile 2>&1
        cd $2/$filenoext || logErrorAndExit "Failed to change to destination directory $2/$filenoext"
        timestamp >>$logfile 2>&1
        echo -n "Current directory:" >>$logfile 2>&1
        curdir=$(pwd)
        echo $curdir >>$logfile 2>&1
        if [ "$curdir" == "$2/$filenoext" ]; then
                timestamp >>$logfile 2>&1
                echo "Directory $curdir: listing oldest files greater than 40 versions to delete for cleanup:" >>$logfile 2>&1
                ls -1t | tail -n +41 >>$logfile 2>&1
                ls -1t | tail -n +41 | xargs rm -f || logErrorAndExit "Failed to delete old files in $curdir"    #cleans up anything older than 40 files
        fi
done
lines=$(wc -l < "$logfile")
if [ "$lines" -gt "$linesallowed" ]; then
        timestamp >>$logfile 2>&1
        echo "Reducing lines in log file to $linesallowed lines" >>$logfile 2>&1
        echo "$(tail -$linesallowed $logfile)" > $logfile || logErrorAndExit "Failed to reduce log file size"
fi
