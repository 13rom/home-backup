#!/usr/bin/env bash
# Make SOURCE-DIR backup to NAS rsync server
# Do the backup only if connected to home WiFi
# 1. Check for WiFi SSID availability
# 2. Check for server availability
# 3. Rsync
# 4. Send notifications
#

ECODE=0
#DATE=`date -Iminutes`
MYSSID="<YOUR-WIFI-SSID>"
SERVER="<SERVER-NAME-OR-IP>"
SRC="/<PATH-TO-SOURCE-DIR>/"
DST="/<PATH-TO-DESTINATION-DIR>"
REMOTEUSER="<NAS-RSYNC-USER>"
# Telegram bot
TOKEN="<YOUR-TELEGRAM-TOKEN>"
CHAT_ID="<YOUR-CHATID>"
MESSAGE="Hello World"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

# extract the essid
essid=$(iwgetid -r)

# check for SSID, exit otherwise
[ "$essid" == $MYSSID ] || exit

# Is the server pingable?
# try three pings, wait maximum one sec for reply, be quiet
if ping -qc 3 -W 1 $SERVER > /dev/null; then
    # now we know we're connected to our WiFi network
    /usr/bin/notify-send "Home Backup" -c "presence.online" --icon="network-server" -t 5000 "${SERVER} is available. Starting backup.";    
    # execute rsync and measure time taken
    start=`date +%s`;
    /usr/bin/rsync -avh ${SRC} ${REMOTEUSER}@${SERVER}:${DST};
    end=`date +%s`
    timetake=$((end-start))
    # now check the exit code
    ECODE="$?"
    if [ $ECODE -eq 0 ]
    then
        /usr/bin/notify-send "Home Backup" -c "presence.online" --icon="network-server" -t 5000 "Backup done successfully in $timetake seconds.";
        MESSAGE="RSYNC: Backup done successfully in $timetake seconds.";
    else
        /usr/bin/notify-send "Home Backup" -c "presence.online" --icon="network-server" -t 5000 "Rsync finished with exit code: $ECODE";
        MESSAGE="RSYNC: Backup done. Finished with exit code: $ECODE";
    fi
    # /usr/bin/notify-send "Home Backup" -c "presence.online" --icon="network-server" -t 5000 "Rsync finished with exit code: $ECODE";
    # MESSAGE="RSYNC: Backup done. Finished with exit code: $ECODE";
else
    /usr/bin/notify-send "Home Backup" -c "presence.offline" -t 10000 --icon="network-server" "${SERVER} is not accessible. Backup failed.";
    MESSAGE="RSYNC: NAS is not accessible. Backup failed.";
fi

curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" > /dev/null;
