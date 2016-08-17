
cd /home/ec2-user/ReportScripts/MonthlyStats;

database='postgresql://oxigen:H6FQQAXDL6Ll@oxigen.c6r6wt95sak1.ap-southeast-1.rds.amazonaws.com:5432/oxigen'

#FROM_TIME='2016-05-31 18:30:00.000'
#TO_TIME='2016-06-30 18:29:59.000'

CURRENT_DATE=`date +"%m-%d-%Y"`

TO_TIME=`date -d "-1 day" '+%m-%d-%Y 18:30:00'`
FROM_TIME=`date -d "-1 month" '+%m-%d-%Y 18:30:00'`


mkdir -p "reports/$CURRENT_DATE"
to="selva@fastacash.com,sheetal@fastacash.com,anish@fastacash.com,nagasai@fastacash.com"
#to="sheetal@fastacash.com"
from="operations@fastacash.com"
subject="Oxigen Monthly Report- $CURRENT_DATE"


psql $database -c "select ch.external_user_id, cast(us.created_at + (double precision '5.5' * interval '1 hour') AS timestamp) as Created_on from users us, channels ch where us.created_at between '$FROM_TIME' and '$TO_TIME' and ch.user_id = us.id and ch.type='fc' order by us.created_at asc;" -F , --no-align --pset footer > "reports/$CURRENT_DATE/"Userid_Reg_Oxigen_$CURRENT_DATE.csv


psql $database -c "select ls.*,cast(ls.created_at + (double precision '5.5' * interval '1 hour') AS timestamp) as Created_on from links ls where ls.created_at between '$FROM_TIME' and '$TO_TIME' and ls.state not in ('CREATED', 'PENDING') order by ls.created_at asc;" -F , --no-align --pset footer > "reports/$CURRENT_DATE/"Links_Gen_Oxigen_$CURRENT_DATE.csv



psql $database -c "select distinct w.external_id from links l, wallets w where w.id=l.source and l.created_at > '$FROM_TIME' and l.created_at <= '$TO_TIME' and l.state not in ('CREATED','PENDING');" -F , --no-align --pset footer > "reports/$CURRENT_DATE/"distinct_wuid_Oxigen_$CURRENT_DATE.csv


boundary="ZZ_/afg6432dfgkl.94531q"
body="PFA."
declare -a attachments
attachments=( $(ls reports/$CURRENT_DATE/*.csv) )

get_mimetype(){
  # warning: assumes that the passed file exists
  file --mime-type "$1" | sed 's/.*: //'
}


# Build headers
{

printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"
--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"

# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(get_mimetype "$file")

  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"

  base64 "$file"
  echo
done

# print last boundary with closing --
printf '%s\n' "--${boundary}--"

} | sendmail -t -oi -f "$from" "$to"

