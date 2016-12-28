#!/bin/bash
#

. /root/.imap_creds.conf

ID_CMD="curl -s -k --url \"${URI}\" --user ${USERNAME}:${PASSWORD} --request \"${REQUEST}\" \
        | awk '{print \$NF}' \
        | sed 's/\r//g'"

ID=$(eval "${ID_CMD}")

BODY_CMD="curl -vs -k --url \"${URI}\" --user ${USERNAME}:${PASSWORD} --request \"FETCH ${ID} BODY[TEXT]\" 2>&1 \
          | grep '[a-zA-Z0-9]\{5\}-[a-zA-Z0-9]\{5\}-[a-zA-Z0-9]\{5\}-[a-zA-Z0-9]\{5\}' \
          | awk '{print \$2}'"

BODY=$(eval "${BODY_CMD}")
echo "${BODY}"
