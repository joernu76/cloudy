#!/bin/bash
MAIL_SERVER=smtp.strato.com:587
MAIL_ACCOUNT=joern@familie-ungermann.de
MAIL_PASSWORD=1MkidKusdK1E

source /home/pi/cloudy/scripts/.env.mail
echo "Subject: cloudy" > tst.txt
echo $* >> tst.txt
echo >> tst.txt
unix2dos tst.txt

curl \
  --url "smtp://${MAIL_SERVER}" --ssl-reqd -ssl --TLSv1.3 -v \
  --mail-from ${MAIL_ACCOUNT} \
  --mail-rcpt ${MAIL_ACCOUNT} \
  --user "${MAIL_ACCOUNT}:${MAIL_PASSWORD}" \
  -T tst.txt

rm tst.txt
