#!/bin/bash
source /home/pi/cloudy/scripts/.env.mail
msg=$(mktemp)
trap 'rm -f "$msg"' EXIT
echo "Subject: $(hostname)" > "$msg"
printf "%s\n" "$*" >> "$msg"
echo >> "$msg"
unix2dos -q "$msg"

curl \
  --url "smtp://${MAIL_SERVER}" --ssl-reqd --tlsv1.3 -s --show-error \
  --mail-from ${MAIL_ACCOUNT} \
  --mail-rcpt ${MAIL_TARGET} \
  --user "${MAIL_ACCOUNT}:${MAIL_PASSWORD}" \
  -T "$msg"
