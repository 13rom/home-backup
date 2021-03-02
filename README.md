# Home backup with bells and whistles
Automating backup of user's home folder to a NAS share using systemd service and timer.
Runs in three steps: `home-backup.timer` -> `home-backup.service` -> `home-backup.sh`.

### `home-backup.sh` script features:
* script could be used as a standalone application;
* backup is done only when connected to given WiFi network;
* Gnome notifications and Telegram message notification during backup.

## Standalone script usage:
```shell
home-backup.sh [--notify] PATH/SOURCE-DIR
```
### Options:
   `--notify`  ...  send desktop and Telegram notifications during backup

### Where: 
   `PATH` ... absolute or relative path to a SOURCE-DIR

### Examples:
```shell
home-backup.sh /home/user/Documents/
home-backup.sh Documents/programming/
home-backup.sh --notify Downloads/fonts/
```
## Installation
1. Copy files to /home/your-user/bin
```shell
cp $(pwd)/home-backup.* ~/bin
```
2. Install service and timer

In order to get access to user's DBUS and thus be able to show Gnome notifications, systemd service and timer must be installed within user environment.
```shell
cd ~/bin
ln -s $(pwd)/home-backup.service ~/.config/systemd/user/home-backup.service
ln -s $(pwd)/home-backup.timer ~/.config/systemd/user/home-backup.timer
```
3. Reload systemd services:
```shell
sudo systemctl daemon-reload
```
4. Start timer:
```shell
systemctl --user start home-backup.timer
```
5. Examine the log:
```shell
systemctl --user status home-backup.timer
journalctl --user -u home-backup.timer
```
6. Allow timer to be triggered after reboot:
```shell
systemctl --user enable home-backup.timer
```
