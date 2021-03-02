#!/usr/bin/env bash
############################################################################################
#
# Home-backup script
#
# Backup any folder inside user's home directory to a NAS rsync server.
#   * Checks for WiFi SSID availability
#   * Checks for server availability
#   * Rsync
#   * Sends notifications
#
# Usage:
#   home-backup [--notify] PATH/SOURCE-DIR
#
# Options:
#   --notify  ...  send desktop and Telegram notifications during backup
#
# Where: 
#   PATH ... absolute or relative path to a SOURCE-DIR
#
# Examples:
#   home-backup /home/user/Documents/
#   home-backup Documents/programming/
#   home-backup --notify Downloads/fonts/
#
##########################################################################
#
# Copyright 2021 Romanov Oleg
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
##########################################################################


# Variables initialization
# DATE=`date -Iminutes`
ECODE=0                                 # rsync exit code
NOTIFY=0                                # should we notify user?


# Get variables from config file
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPTPATH"/home-backup.conf

# Function for sending desktop notifications
notify() {
    [ $NOTIFY -eq 1 ] && /usr/bin/notify-send "Home Backup" -c "$1" --icon="network-server" -t 5000 "$2"
}


# Command line arguments check
display_usage() { 
    echo -e "Usage:\n$0 [--notify] PATH/SOURCE-DIR" 
    echo -e "Home-backup script. Backup any folder inside user's home directory to a NAS rsync server.\n"
    echo -e "Options:\n\t--notify\tsend desktop and Telegram notifications during backup"
} 

if [ $# -eq 0 ]; then
    # script started without arguments
    display_usage
    exit 1
fi

if [ "$1" == "--notify" ] 
then
    NOTIFY=1
    shift
fi

if [ $# -eq 0 ]; then
    # script started without SOURCE-DIR
    display_usage
    exit 1
fi

# Get relative path to source directory and build SRC and DST paths
DIR=$(echo "$1" | sed "s=${SRCBASE}==" | sed "s#^/\(.*\)#\1#" | sed "s#\(.*\)/\$#\1#")
SRC="${SRCBASE}/${DIR}"
DST="${DSTBASE}/${DIR}"
[ "$DIR" == "" ] || SRC="${SRC}/"

# Check for SSID, exit otherwise
essid=$(iwgetid -r)
[ "$essid" == "$MYSSID" ] || exit


# Is the server pingable?
# try three pings, wait maximum one sec for reply, be quiet
if ping -qc 3 -W 1 "$SERVER" > /dev/null; then
    # now we know we're connected to our WiFi network
    notify "presence.online" "${SERVER} is available. Starting backup."

    # execute rsync
    /usr/bin/rsync -avh "${SRC}" ${REMOTEUSER}@${SERVER}:"${DST}"

    # now check the exit code
    ECODE="$?"
    if [ $ECODE -eq 0 ]
    then
        MESSAGE="Home Backup - backup task \"${DIR}\" has been completed."
        notify "presence.online" "$MESSAGE"
    else
        MESSAGE="Home Backup - backup task \"${DIR}\" finished with exit code: $ECODE"
        notify "presence.online" "$MESSAGE" 
        
    fi
    # /usr/bin/notify-send "Home Backup" -c "presence.online" --icon="network-server" -t 5000 "Rsync finished with exit code: $ECODE"
    # MESSAGE="RSYNC: Backup done. Finished with exit code: $ECODE"
else
    MESSAGE="Home Backup - ${SERVER} is not accessible. Backup task \"${DIR}\" failed."
    notify "presence.offline" "$MESSAGE"
fi

# Send Telegram notification
[ $NOTIFY -eq 1 ] && curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" > /dev/null

exit $ECODE