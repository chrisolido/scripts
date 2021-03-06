#!/bin/sh

#
# This script assumes that you have either 0 or 1 pgbackups stored
# on Heroku, and that you already have the heroku gem installed
# and configured on your system.
#

PROJECT_DIRECTORY=/root
BACKUP_FILE=/BACKUP/prod/eudew
S3REMOTE_DIRECTORY=s3://ami.fastacash.com/eudewmetada_postgresql_production_backup/

cd $PROJECT_DIRECTORY
LIST=`heroku pgbackups -a eu-dew-location`
if [ $? != 0 ]
	then
  	echo "No backups found"
else
  
	LIST3=`heroku pgbackups -a eu-dew-location > eu-list.txt`
	OUTPUT=`tail -1 eu-list.txt | awk '{print $1}'`
	LIST2=`heroku pgbackups:url -a eu-dew-location "$OUTPUT"`
	echo "Found backup "$OUTPUT". Proceeding to download it to local."
	`curl -o "$OUTPUT" "$LIST2" --ignore-content-length`
fi

echo "Putting the eu-production postgre backup in s3"

TOS3=`ls | grep $OUTPUT`
if [ $? != 0 ]
	then
	echo "No backup uploaded"
else
	echo "Yes backup uploading"
		`/usr/bin/s3cmd put "$TOS3" "$S3REMOTE_DIRECTORY"`
	echo "Moving the backup file"
        	`mv "$TOS3" "$BACKUP_FILE"`
fi

