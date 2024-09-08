# firefox-linux-installer
firefox-install.sh is a helper script to download the Firefox web
browser directly from Mozilla's home page.
It is installed using the 'Installing Firefox from Mozilla builds'
installation instructions, see
https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-from-mozilla-builds.

## How to install
Open a Terminal and run following:
```
wget https://raw.githubusercontent.com/CS-Alchemist/firefox-linux-installer/main/firefox-install.sh
```
```
chmod u+x ./firefox-install.sh
```
```
sudo ./firefox-install.sh
```

## firefox Group
The firefox group is created so that only authorised users can edit data
in the /opt/firefox installation path.

Any user who is a member of the firefox group can perform automatic
updates.

To add a user:
```
$ usermod -aG firefox <USERNAME>
```