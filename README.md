# Home backup with bells and whistles
Automating backup of user's home folder to a NAS share using systemd service and timer. 
Features:
* Gnome notifications during backup;
* Telegram message notification;
* timer could be configured to trigger minutely, hourly, daily, etc.

In order to get access to user's DBUS and thus be able to show Gnome notifications, systemd service and timer must be installed within user environment.
How it works: `home-backup.timer` -> `home-backup.service` -> `home-backup.sh`.
1. Install service and timer:
```shell
ln -s $(pwd)/home-backup.service ~/.config/systemd/user/home-backup.service
ln -s $(pwd)/home-backup.timer ~/.config/systemd/user/home-backup.timer
```
2. Reload systemd services:
```shell
sudo systemctl daemon-reload
```
3. Start timer:
```shell
systemctl --user start home-backup.timer
```
4. Examine the log:
```shell
systemctl --user status home-backup.timer
journalctl --user -u home-backup.timer
```
