#!/bin/bash
#Date Feb, 12 2014 06:00 EST
################################################################################
# The MIT License (MIT)
#
# Copyright (c) <2013> <r.neese@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
################################################################################
#checks to see if installing on openvz server
if [[ -f /proc/vz ]]; then 
echo "Note: "
echo "Those of you running this script on openvz. You must run it as root and "
echo "bash  Fusionpbx-Debian-Pkg-Install-New.sh or it fails the networking check."
exit
fi
#
################################################################################
#<------Start Edit HERE--------->
#stable=1.2/beta=1.4/master=1.5 aka git head
# Default is stable
freeswitch_repo="stable"
#
install_freeswitch="y"
#
# Freeswitch Optional /Customized installs
#
# "freeswitch_install=all" (freeswitch-meta-all) installs all the differant configs
# in the "/usr/share/freeswith/conf" dir so you do not need to select any below.
#
# Freeswitch Install Options (all/meta-all/meta-bare/meta-codecs/meta-defaut/fusionpbx/meta-lang/meta-say/meta-sorbet/meta-vanilla)
freeswitch_install="fusionpbx" 
#
#Due to build issues on squeeze mod_vls is not included in the meta installs and there for must be installes seprately
freeswitch_vlc="y"
#
# Installs the freeswitch sounds en-us-callie
freeswitch_sounds="n"
#
# Installs freeswitch music files.
freeswitch_music="y"
#
#FreeSwitch Configs Options installed in /usr/share/freeswitch/conf/(configname)
#This also copies the default configs into the default active config dir /etc/freeswitch
#
#Freeswitch Config Options (curl/insideout/rayo/sbc/softphone/vanills
freeswitch_conf="vanilla" # FreeSWITCH vanilla configuration
#
#Remove the default extensions for security .
freeswitch_exten="y"
#
# TO Disable freeswitch nat auto detection
#
# To start FreeSWITCH with -nonat option set freeswitch_NAT to y
# Set to y if on public static IP
freeswitch_nat=n
#
#install fail2ban/monit for port security and monit service
install_fail2ban="y"
#
#Set how long to keep freeswitch/fusionpbx log files 1 to 30 dasy (Default:5)
keep_logs=5
#
#Install and use FusionPBX GUI
#
#Option to install the fusionpbx gui / nginx / php5.
#If this option is not selected it will only install freeswitch/fail2ban/monit 
#setup for freeswitch only.
install_gui="y"
#
# Use fusionpbx debian pkgs.
#
#Fusionpbx repo (stable/devel)
fusionpbx_repo="devel"
#
#FusionPBX install options (Full/basepbx/core/switch)
fusionpbx_install="full" 
#
# Database options
#
# Uses Postgress 9.3 by default now.
# 
# Please Select Server or Client not both. 
#
# Used for connecting to remote postgresql database servers
# Install postgresql Client 9.x for connection to remote postgresql servers (y/n)
postgresql_client="n"
#
# Install postgresql server 9.x (y/n) (client included)(Local Machine)
# Notice:
# You should not use postgresql server on a nand/emmc/sd. It cuts the performance 
# life in half due to all the needed reads and writes. This cuts the life of 
# your pbx emmc/sd in half. 
postgresql_server="n"
#
# Set Postgresql Server Admin username
# Lower case only
postgresqluser=
#
# Set Postgresql Server Admin password
postgresqlpass=
#
# Set Database Name used for fusionpbx in the postgresql server 
# (Default: fusionpbx)
database_name=
#
# Set FusionPBX database admin name.(used by fusionpbx to access 
# the database table in the postgresql server.
# (Default: fusionpbx)
database_user_name=
#
#Install & Enable pbx admin shell menu
enable_admin_menu="n"
#
#Install openvpn scripts
install_openvpn="n"
#
#Install Ajenti Admin Portal
install_ajenti="n"

#<------Stop Edit Here-------->
################################################################################
# Hard Set Varitables (Do Not EDIT)
#Freeswitch module dir
freeswitch_mod="/usr/lib/freeswitch/mod"
# Freeswitch logs dir
freeswitch_log="/var/log/freeswitch"
#Freeswitch default configs location
freeswitch_dflt_conf="/usr/share/freeswitch/conf"
#Freeswitch active config directory
freeswitch_act_conf="/etc/freeswitch"
#Nginx default www dir
WWW_PATH="/usr/share/nginx/www" #debian nginx default dir
#set Web User Interface Dir Name
wui_name="fusionpbx"
#Php ini config file
php_ini="/etc/php5/fpm/php.ini"
#################################################################################
#Start installation

echo "This is a one time install script."
echo "It is not intended to be run multi times"
echo "If it fails for any reason please report to r.neese@gmail.com. "
echo "Please include any screen output you can to show where it fails."
echo ""

#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
#test internet connection..
echo "This Script Currently Requires a internet connection "
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "Found the Internet ... continuing!"
	/bin/rm /tmp/index.google
fi

# OS ENVIRONMENT CHECKS
#check to confirm running as root
#
# First, we need to be root...
#

if [ "$(id -u)" -ne "0" ]; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi

echo "You're root.... continuing!"

#removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list
#sed -i '2,4d' /etc/apt/sources.list

#if lsb_release is not installed it installs it
if [ ! -s /usr/bin/lsb_release ]; then
	apt-get update && apt-get -y install lsb-release
fi

# Os/Distro Check
lsb_release -c |grep -i wheezy &> /dev/null 2>&1
if [ $? -eq 0 ]; then
		/bin/echo "Good, you are running Debian 7 codename: wheezy"
		/bin/echo
else
		lsb_release -c |grep -i jessie > /dev/null
		if [ $? -eq 0 ]; then
                /bin/echo 'OK you are running Debian 8 CodeName (Jessie). This script is known to work'
		/bin/echo
                CONTINUE=YES
        fi
        lsb_release -c |grep -i saucy > /dev/null
        if [ $? -eq 0 ]; then
                /bin/echo "OK you're running Ubuntu 13.10 [saucy].  This script is a work in progress."
                /bin/echo "   It is not recommended that you try it at this time."
                /bin/echo 
                CONTINUE=YES
        else
                /bin/echo "This script was written for Debian 7 codename wheezy"
                /bin/echo
                /bin/echo "Your OS appears to be:"
                lsb_release -a
                read -p "Do you wish to continue y/n? " CONTINUE

                case "$CONTINUE" in
                [yY]*)
                        /bin/echo 'Ok, this does not always work..,'
                        /bin/echo '  but well give it a go.'
                ;;

                *)
                        /bin/echo 'Exiting the install.'
                        exit 1
                ;;
                esac
        fi
fi

#adding FusionPBX repo ( contains freeswitch armhf debs, fusionpbx debs ,and a few custom scripts debs)
case $(uname -m) in armv7l)
if [[ $freeswitch_repo == "stable" ]]; then
echo 'installing armhf stable repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-stable/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "beta" ]]; then
echo 'installing armhf beta repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-beta/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "head" ]]; then
echo 'installing armhf head repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-head/debian/ wheezy main
DELIM
fi

#running update and upgrade on existing pkgs
for i in update upgrade ;do apt-get -y "${i}" ; done
esac

#freeswitch repo for x86 x86-64 bit pkgs
case $(uname -m) in x86_64|i[4-6]86)
# install curl to fetch repo key
echo 'installing curl'
apt-get update && apt-get -y install curl

#adding in freeswitch reop to /etc/apt/sources.list.d/freeswitch.lists

if [[ $freeswitch_repo == "stable" ]]; then
echo 'installing stable repo'
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "beta" ]]; then
echo 'installing beta repo'
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb-beta/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "master" ]]; then
echo 'install master repo'
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb-master/debian/ wheezy main
DELIM
fi

#adding key for freeswitch repo
echo 'fetcing repo key'
curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -

for i in update upgrade ;do apt-get -y "${i}" ; done
esac

#freeswitch repo for x86 x86-64 bit pkgs
case $(uname -m) in x86_64|i[4-6]86)
#add in pgsql 9.3
cat > "/etc/apt/sources.list.d/pgsql-pgdg.list" << DELIM
deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
DELIM
#add pgsql repo key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
esac

if [[ $install_freeswitch == "y" ]]; then

# Freeswitch Install Options.
if [[ $freeswitch_install == "all" ]]; then
	echo " Installing freeswitch all and freeswitch deps"
	#install Freeswitch Deps
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#pkgs required for freeswitch-mod-ladspa
	for i in autotalent ladspa-sdk tap-plugins swh-plugins libfftw3-3  ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-all
	apt-get -y install --force-yes freeswitch-meta-all
fi

# Freeswitch Install Options.
if [[ $freeswitch_install == "meta-all" ]]; then
	echo " Installing freeswitch all and freeswitch deps"
	#install Freeswitch Deps
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#pkgs required for freeswitch-mod-ladspa
	for i in autotalent ladspa-sdk tap-plugins swh-plugins libfftw3-3  ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-all
	apt-get -y install --force-yes freeswitch-meta-all
fi

if [[ $freeswitch_install == "meta-bare" ]]; then
	echo " Installing freeswitch bare "
	apt-get -y install --force-yes freeswitch-meta-bare
fi

if [[ $freeswitch_install == "meta-codecs" ]]; then
	echo " Installing freeswitch all codecs "
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-codecs
	apt-get -y install --force-yes freeswitch-meta-codecs
fi

if [[ $freeswitch_install == "meta-conf" ]]; then
	echo " Installing all freeswitch config files "
	apt-get -y install --force-yes freeswitch-meta-conf
fi

if [[ $freeswitch_install == "meta-default" ]]; then
	echo " Installing freeswitch default "
	#install Freeswitch Deps
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-default
	apt-get -y install --force-yes freeswitch-meta-default
fi

if [[ $freeswitch_install == "fusionpbx" ]]; then
	echo " Installing freeswitch fusipnpbx "
	#install Freeswitch Deps
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	# install freeswitch fusionpbx install
	for i in freeswitch freeswitch-init freeswitch-meta-codecs freeswitch-mod-avmd freeswitch-mod-callcenter freeswitch-mod-cidlookup \
		freeswitch-mod-commands freeswitch-mod-conference freeswitch-mod-curl freeswitch-mod-db freeswitch-mod-dingaling freeswitch-mod-distributor \
		freeswitch-mod-dptools freeswitch-mod-enum freeswitch-mod-esf freeswitch-mod-esl freeswitch-mod-expr freeswitch-mod-fifo freeswitch-mod-fsv \
		freeswitch-mod-hash freeswitch-mod-memcache freeswitch-mod-portaudio freeswitch-mod-portaudio-stream freeswitch-mod-random freeswitch-mod-redis \
		freeswitch-mod-sms freeswitch-mod-spandsp freeswitch-mod-spy freeswitch-mod-translate freeswitch-mod-valet-parking freeswitch-mod-vmd freeswitch-mod-flite \
		freeswitch-mod-pocketsphinx freeswitch-mod-tts-commandline freeswitch-mod-dialplan-xml freeswitch-mod-loopback freeswitch-mod-rtmp freeswitch-mod-sofia \
		freeswitch-mod-event-multicast freeswitch-mod-event-socket freeswitch-mod-event-test freeswitch-mod-local-stream freeswitch-mod-native-file \
		freeswitch-mod-sndfile freeswitch-mod-tone-stream freeswitch-mod-lua freeswitch-mod-console freeswitch-mod-logfile freeswitch-mod-syslog \
		freeswitch-mod-say-en freeswitch-mod-posix-timer freeswitch-mod-timerfd freeswitch-mod-xml-cdr freeswitch-mod-xml-curl \
		freeswitch-mod-xml-rpc freeswitch-lang-en ;do apt-get -y install --force-yes "${i}" ;done
fi

if [[ $freeswitch_install == "meta-lang" ]]; then
	echo " Installing freeswitch languages "
	apt-get -y install --force-yes freeswitch-meta-lang
fi

if [[ $freeswitch_install == "meta-say" ]]; then
	echo " Installing freeswitch say language files "
	apt-get -y install --force-yes freeswitch-meta-say
fi

if [[ $freeswitch_install == "meta-sorbet" ]]; then
	echo " Installing freeswitch sorbet "
	#install Freeswitch Deps
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-sorbet
	apt-get -y install --force-yes freeswitch-meta-sorbet
fi

if [[ $freeswitch_install == "meta-vanilla" ]]; then
	echo " Installing freeswitch vanilla "
	for i in curl screen unixodbc uuid memcached ;do apt-get -y install "${i}" ; done
	#Pkgs needed for faxing (freeswitch-mod-spandsp)
	for i in libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done
	#install freeswitch-meta-vanilla	
	apt-get -y install --force-yes freeswitch-meta-vanilla
fi

if [[ $freeswitch_sounds == "y" ]]; then
	echo " Installing freeswitch sounds_en_us_calie 8/16/32/48k sounds"
	apt-get -y install --force-yes freeswitch-sounds
fi

if [[ $freeswitch_music == "y" ]]; then
	echo " Installing freeswitch music 8/16/32/48k music"
	apt-get -y install --force-yes freeswitch-music
fi

if [[ $freeswitch_vlc == "y" ]]; then
	echo " Installing freeswitch mod_vlc "
	apt-get -y install --force-yes freeswitch-mod-vlc
fi

#Genertaing /etc/freeswitch config dir.
mkdir $freeswitch_act_conf

#FreeSwitch Configs
if [[ $freeswitch_conf == "curl" ]]; then
	echo " Installing Freeswitch curl configs"
	# Installing defailt configs into /usr/share/freeswitch/conf/(configname).
	apt-get -y install	freeswitch-conf-curl
	#Copy configs into Freeswitch active conf dir.
	cp -rp "$freeswitch_dflt_conf"/curl/* "$freeswitch_act_conf"
	#Chowning files for correct user/group in the active conf dir.
	chown -R freeswitch:freeswitch "$freeswitch_act_conf" 
fi

if [[ $freeswitch_conf == "insideout" ]]; then
	echo " Installing Freeswitch insideout configs"
	apt-get -y install	freeswitch-conf-insideout
	cp -rp "$freeswitch_dflt_conf"/insideoout/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "rayo" ]]; then
	echo " Installing Freeswitch rayo configs"
	apt-get -y install	freeswitch-conf-rayo
	cp -rp "$freeswitch_dflt_conf"/rayo/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "sbc" ]]; then
	echo " Installing Freeswitch session border control configs"
	apt-get -y install	freeswitch-conf-sbc
	cp -rp "$freeswitch_dflt_conf"/sbc/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "softphone" ]]; then
	echo " Installing Freeswitch softphone configs"
	apt-get -y install	freeswitch-conf-softphone
	cp -rp "$freeswitch_dflt_conf"/softphone/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "vanilla" ]]; then
	echo " Installing Vanilla configs"
	apt-get -y install	freeswitch-conf-vanilla
	cp -rp "$freeswitch_dflt_conf"/vanilla/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

chown -R freeswitch:freeswitch "$freeswitch_act_conf"

#fix music dir issue ( when using pkgs the music dir is /usr/share/freeswitch/sounds/music/default/8000 not /usr/share/freeswitch/sounds/music/8000)
if [ -f "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml ]
then
/bin/sed "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml -i -e s,'<directory name="default" path="$${sounds_dir}/music/8000">','<directory name="default" path="$${sounds_dir}/music/default/8000">',g
/bin/sed "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml -i -e s,'<directory name="moh/8000" path="$${sounds_dir}/music/8000">','<directory name="default" path="$${sounds_dir}/music/default/8000">',g
/bin/sed "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml -i -e s,'<directory name="moh/16000" path="$${sounds_dir}/music/16000">','<directory name="default" path="$${sounds_dir}/music/default/16000">',g
/bin/sed "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml -i -e s,'<directory name="moh/32000" path="$${sounds_dir}/music/32000">','<directory name="default" path="$${sounds_dir}/music/default/32000">',g
fi

# Proper file to change init strings in. (/etc/defalut/freeswitch)
# Configuring /etc/default/freeswitch DAEMON_Optional ARGS
if [ -f /etc/default/freeswitch ]
then
sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-rp"',
fi
fi

if [[ $freeswitch_exten == "y" ]]; then
#remove the default extensions
for i in /etc/freeswitch/directory/default/*.xml ;do rm "$i" ; done
fi

if [[ $install_fail2ban == "y" ]]; then
# SEE http://wiki.freeswitch.org/wiki/Fail2ban
#Fail2ban
for i in fail2ban monit ;do apt-get -y install "${i}" ; done

#Taken From http://wiki.fusionpbx.com/index.php?title=Monit and edited to work with debian pkgs.
#Adding Monitor to keep freeswitch running.
/bin/cat > "/etc/monit/conf.d/freeswitch"  <<DELIM
set daemon 60
set logfile syslog facility log_daemon

check process freeswitch with pidfile /var/run/freeswitch/freeswitch.pid
start program = "/etc/init.d/freeswitch start"
stop program = "/etc/init.d/freeswitch stop"
DELIM

#Adding changes to freeswitch profiles
#Enableing device login auth failures ing the sip profiles.
if [ -f "$freeswitch_act_conf"/sip_profiles/internal.xml ]
then
sed "$freeswitch_act_conf"/sip_profiles/internal.xml -i -e s,'<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>',g

sed "$freeswitch_act_conf"/sip_profiles/internal.xml -i -e s,'<!-- *<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/> *-->','<param name="log-auth-failures" value="true"/>', \
				-e s,'<!--<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/>-->','<param name="log-auth-failures" value="true"/>',g
fi

#Setting up Fail2ban freeswitch config files.
/bin/cat > "/etc/fail2ban/filter.d/freeswitch.conf" <<DELIM

# Fail2Ban configuration file

[Definition]

failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

ignoreregex =
DELIM

/bin/cat > /etc/fail2ban/filter.d/freeswitch-dos.conf  <<DELIM

# Fail2Ban DOS configuration file

[Definition]

failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

ignoreregex =
DELIM

/bin/cat >> "/etc/fail2ban/jail.local" <<DELIM
[freeswitch-tcp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = tcp
filter   = freeswitch
logpath  = /var/log/freeswitch/freeswitch.log
action   = iptables-allports[name=freeswitch-tcp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600

[freeswitch-udp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = udp
filter   = freeswitch
logpath  = /var/log/freeswitch/freeswitch.log
action   = iptables-allports[name=freeswitch-udp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600

[freeswitch-dos]
enabled = true
port = 5060,5061,5080,5081
protocol = udp
filter = freeswitch-dos
logpath = /var/log/freeswitch/freeswitch.log
action = iptables-allports[name=freeswitch-dos, protocol=all]
maxretry = 50
findtime = 30
bantime  = 6000
DELIM

#Turning off RepeatedMsgReduction in /etc/rsyslog.conf"
sed -i 's/RepeatedMsgReduction\ on/RepeatedMsgReduction\ off/' /etc/rsyslog.conf
/etc/init.d/rsyslog restart

sed -i /usr/bin/fail2ban-client -e s,^\.setInputCmd\(c\),'time.sleep\(0\.1\)\n\t\t\tbeautifier.setInputCmd\(c\)',

#Restarting Nginx and PHP FPM
for i in freeswitch fail2ban
do /etc/init.d/"${i}" restart  >/dev/null 2>&1
done
fi

# see http://wiki.fusionpbx.com/index.php?title=RotateFSLogs
/bin/cat > "/etc/cron.daily/freeswitch_log_rotation" <<DELIM
#!/bin/bash

#number of days of logs to keep
NUMBERDAYS="$keep_logs"
FSPATH="/var/log/freeswitch"

"$FSPATH"/bin/freeswitch_cli -x "fsctl send_sighup" |grep '+OK' >/tmp/rotateFSlogs

if [ $? -eq 0 ]; then
       #-cmin 2 could bite us (leave some files uncompressed, eg 11M auto-rotate). Maybe -1440 is better?
       find "$FSPATH" -name "freeswitch.log.*" -cmin -2 -exec gzip {} \;
       find "$FSPATH" -name "freeswitch.log.*.gz" "-mtime" "+$NUMBERDAYS" -exec /bin/rm {} \;
       chown freeswitch:freeswitch "$FSPATH"/freeswitch.log
       chmod 660 "$FSPATH"/freeswitch.log
       logger FreeSWITCH Logs rotated
       rm /tmp/<<DELIM
else
       logger FreeSWITCH Log Rotation Script FAILED
       mail -s '$HOST FS Log Rotate Error' root < /tmp/<<DELIM
       rm /tmp/<<DELIM
fi

DELIM

chmod 755 /etc/cron.daily/freeswitch_log_rotation

#Now dropping 10MB limit from FreeSWITCH"
if [ -f "$freeswitch_act_conf"/autoload_configs/logfile.conf.xml ]
then
/bin/sed /etc/freeswitch/autoload_configs/logfile.conf.xml -i -e s,\<param.*name\=\"rollover\".*value\=\"10485760\".*/\>,\<\!\-\-\<param\ name\=\"rollover\"\ value\=\"10485760\"/\>\ INSTALL_SCRIPT\-\-\>,g
fi

#Settinf /etc/default freeswitch stratup options with proper scripts dir and to run without nat.
#DISABLE NAT
if [[ $freeswitch_nat == y ]]; then
	/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp -nonat"',
fi

#create xml_cdr dir and chown it properly if the module is installed
if [ -f "$freeswitch_mod"/mod_xml_cdr.so ]
then
mkdir "$freeswitch_log"/xml_cdr
#chown the xml_cdr dir
chown freeswitch:freeswitch "$freeswitch_log"/xml_cdr
fi

# restarting services
for i in fail2ban freeswitch ;do /etc/init.d/"${i}" restart  >/dev/null 2>&1 ; done

#Start of FusionPBX / nginx / php5 install
if [[ $install_gui == "y" ]]; then

#Install and configure  PHP + Nginx + sqlite3 for use with the fusionpbx gui.
for i in ssl-cert sqlite3 nginx php5-cli php5-sqlite php5-odbc php-db php5-fpm php5-common php5-gd php-pear php5-memcache php-apc ;do apt-get -y install "${i}" ; done

# Changing file upload size from 2M to 15M
/bin/sed -i $php_ini -e s,"upload_max_filesize = 2M","upload_max_filesize = 15M",

#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#Install NGINX config file
cat > "/etc/nginx/sites-available/fusionpbx"  << DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 10M;
        client_body_buffer_size 128k;

        location / {
                root $WWW_PATH/$wui_name;
                index index.php;
        }

        location ~ \.php$ {
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                #fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                        deny all;
        }
        location ~ .htpassword {
                        deny all;
        }
        location ~^.+.(db)$ {
                        deny all;
        }
}

server{
        listen 80;
        listen [::]:80 default_server ipv6only=on;
        server_name $wui_name;
        if (\$uri !~* ^.*provision.*$) {
                rewrite ^(.*) https://\$host\$1 permanent;
                break;
        }
        
        #grandstream gx2200
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))$" /app/provision/?mac=$1;
        
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 15M;
        client_body_buffer_size 128k;

        location / {
          root $WWW_PATH/$wui_name;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}

server{
        listen 443;
        listen [::]:443 default_server ipv6only=on;
        server_name $wui_name;
        ssl                     on;
        ssl_certificate         /etc/ssl/certs/ssl-cert-snakeoil.pem;
        ssl_certificate_key     /etc/ssl/private/ssl-cert-snakeoil.key;
        ssl_protocols           SSLv3 TLSv1;
        ssl_ciphers     HIGH:!ADH:!MD5;

		#grandstream gx2200
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))$" /app/provision/?mac=$1;
       
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 15M;
        client_body_buffer_size 128k;

        location / {
          root $WWW_PATH/$wui_name;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}
DELIM

# linking fusionpbx nginx config from avaible to enabled sites
ln -s /etc/nginx/sites-available/"$wui_name" /etc/nginx/sites-enabled/"$wui_name"

#disable default site
rm -rf /etc/nginx/sites-enabled/default

#Restarting Nginx and PHP FPM
for i in nginx php5-fpm ;do /etc/init.d/"${i}" restart > /dev/null 2>&1 ; done

#Adding users to needed groups
adduser www-data freeswitch
adduser freeswitch www-data

#adding FusionPBX repo ( contains freeswitch armhf debs, fusionpbx bed,and a few custom scripts debs)
if [[ $fusionpbx_repo == "stable" ]]; then
echo 'installing fusionpbx stable repo'
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com/deb/debian/ wheezy main
DELIM

elif [[ $fusionpbx_repo == "devel" ]]; then
echo 'installing fusionpbx devel repo'
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com/deb-dev/debian/ wheezy main
DELIM
fi

apt-get update

# Install FusionPBX Web User Interface stable/devel
echo "Installing FusionPBX Web User Interface Debian pkg"

if [[ $fusionpbx_install == "basepbx" ]]; then
echo " Installing fusipnpbx basepbx"
for i in fusionpbx-core fusionpbx-theme-enhanced fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-destinations fusionpbx-app-devices \
		fusionpbx-app-dialplan fusionpbx-app-dialplan-inbound fusionpbx-app-dialplan-outbound fusionpbx-app-extensions fusionpbx-app-gateways \
		fusionpbx-app-ivr-menu fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-modules fusionpbx-app-music-on-hold fusionpbx-app-provision \
		fusionpbx-app-recordings fusionpbx-app-registrations fusionpbx-app-services fusionpbx-app-settings fusionpbx-app-sip-profiles fusionpbx-app-sip-status \
		fusionpbx-app-sql-query fusionpbx-app-system fusionpbx-app-vars fusionpbx-app-voicemails fusionpbx-app-xml-cdr 
do 	apt-get -y --force-yes install "${i}"
done
fi

if [[ $fusionpbx_install == "core" ]]; then
echo " Installing fusipnpbx core system"
for i in fusionpbx-core fusionpbx-app-dialplan fusionpbx-theme-enhanced 
do 	apt-get -y --force-yes install "${i}"
done
fi

if [[ $fusionpbx_install == "full" ]]; then
echo " Installing fusipnpbx full install"
for i in fusionpbx-core fusionpbx-theme-accessible fusionpbx-theme-classic fusionpbx-theme-default fusionpbx-theme-enhanced fusionpbx-theme-nature \
		fusionpbx-app-adminer fusionpbx-app-call-block fusionpbx-app-call-broadcast fusionpbx-app-call-center fusionpbx-app-call-center-active \
		fusionpbx-app-call-flows fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-click-to-call fusionpbx-app-conference-centers fusionpbx-app-conferences \
		fusionpbx-app-conferences-active fusionpbx-app-contacts fusionpbx-app-content fusionpbx-app-destinations fusionpbx-app-devices fusionpbx-app-dialplan \
		fusionpbx-app-dialplan-inbound fusionpbx-app-dialplan-outbound fusionpbx-app-edit fusionpbx-app-exec fusionpbx-app-extensions fusionpbx-app-fax \
		fusionpbx-app-fifo fusionpbx-app-fifo-list fusionpbx-app-follow-me fusionpbx-app-gateways fusionpbx-app-hot-desking fusionpbx-app-ivr-menu \
		fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-meetings fusionpbx-app-modules fusionpbx-app-music-on-hold fusionpbx-app-park \
		fusionpbx-app-provision fusionpbx-app-recordings fusionpbx-app-registrations fusionpbx-app-ring-groups fusionpbx-app-schemas fusionpbx-app-services \
		fusionpbx-app-settings fusionpbx-app-sip-profiles fusionpbx-app-sip-status fusionpbx-app-sql-query fusionpbx-app-system fusionpbx-app-time-conditions \
		fusionpbx-app-traffic-graph fusionpbx-app-vars fusionpbx-app-voicemail-greetings fusionpbx-app-voicemails fusionpbx-app-xml-cdr fusionpbx-app-xmpp
do 	apt-get -y --force-yes install "${i}"
done
fi

if [[ $fusionpbx_install == "switch" ]]; then
echo " Installing fusipnpbx switch system"
for i in fusionpbx-core fusionpbx-theme-enhanced fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-destinations \
		fusionpbx-app-dialplan fusionpbx-app-dialplan-inbound fusionpbx-app-dialplan-outbound fusionpbx-app-extensions fusionpbx-app-gateways \
		fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-modules fusionpbx-app-registrations  fusionpbx-app-settings \
		fusionpbx-app-sip-profiles fusionpbx-app-sip-status fusionpbx-app-system fusionpbx-app-vars fusionpbx-app-xml-cdr
do 	apt-get -y --force-yes install "${i}"
done
fi

#"Re-Configuring /etc/default/freeswitch to use fusionpbx scripts dir"

#Clean out the freeswitch default configs from the active conf dir
rm -rf "$freeswitch_act_conf"/*

#Put Fusionpbx Freeswitch configs into place
cp -r "$WWW_PATH/$wui_name"/resources/templates/conf/* "$freeswitch_act_conf"

#Settinf /etc/default freeswitch stratup options with proper scripts dir and to run behind nat.
#DAEMON_Optional ARGS
if [ -f /etc/default/freeswitch ]
then
/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp"',
fi

#Reapply sed lines to fusionpbx config files

#Now dropping 10MB limit from FreeSWITCH"(less log files to sift thro)
if [ -f "$freeswitch_act_conf"/autoload_configs/logfile.conf.xml ]
then
/bin/sed /etc/freeswitch/autoload_configs/logfile.conf.xml -i -e s,\<param.*name\=\"rollover\".*value\=\"10485760\".*/\>,\<\!\-\-\<param\ name\=\"rollover\"\ value\=\"10485760\"/\>\ INSTALL_SCRIPT\-\-\>,g
fi

# Enable log-auth-failure logging( tracks device login failure)
if [ -f "$freeswitch_act_conf"/sip_profiles/internal.xml ]
then
sed -i "$freeswitch_act_conf"/sip_profiles/internal.xml -e s,'<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>',g
sed "$freeswitch_act_conf"/sip_profiles/internal.xml -i -e s,'<!-- *<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/> *-->','<param name="log-auth-failures" value="true"/>', \
				-e s,'<!--<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/>-->','<param name="log-auth-failures" value="true"/>',g
fi

#fix music dir issue ( when using pkgs the music dir is /usr/share/freeswitch/sounds/music/default/8000 not /usr/share/freeswitch/sounds/music/8000)
if [ -f "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml ]
then
/bin/sed "$freeswitch_act_conf"/autoload_configs/local_stream.conf.xml -i -e s,'<directory name="default" path="$${sounds_dir}/music/8000">','<directory name="default" path="$${sounds_dir}/music/default/8000">',g
fi

#chown freeswitch  conf files
chown -R freeswitch:freeswitch "$freeswitch_act_conf"

#fix permissions for "$freeswitch_act_conf" so www-data can write to it
find "$freeswitch_act_conf" -type f -exec chmod 660 {} +
find "$freeswitch_act_conf" -type d -exec chmod 770 {} +

#fix permissions on the freeswitch xml_cdr dir so fusionpbx can read from it
find "$freeswitch_log"/xml_cdr -type d -exec chmod 770 {} +

for i in freeswitch nginx php5-fpm ;do /etc/init.d/"${i}" restart >/dev/null 2>&1 ; done

#Pulled From
#http://wiki.fusionpbx.com/index.php?title=Fail2Ban
# Adding fusionpbx to fail2ban
cat > "/etc/fail2ban/filter.d/fusionpbx.conf"  <<DELIM
# Fail2Ban configuration file
#
[Definition]

failregex = .* fusionpbx: \[<HOST>\] authentication failed for
          = .* fusionpbx: \[<HOST>\] provision attempt bad password for

ignoreregex =
DELIM

/bin/cat >> /etc/fail2ban/jail.local  <<DELIM
[fusionpbx]

enabled  = true
port     = 80,443
protocol = tcp
filter   = fusionpbx
logpath  = /var/log/auth.log
action   = iptables-allports[name=fusionpbx, protocol=all]

maxretry = 5
findtime = 600
bantime  = 600
DELIM

#restarting fail2ban
/etc/init.d/fail2ban restart
fi
#end of fusionpbx install

#Install postgresql-client
if [[ $postgresql_client == "y" ]]; then
	db_name="$wui_name"
	db_user_name="$wui_name"
	db_passwd="Admin Please Select A Secure Password for your Postgresql Fusionpbx Database"
	clear
	for i in postgresql-client-9.3 php5-pgsql ;do apt-get -y install "${i}"; done
	/etc/init.d/php5-fpm restart
	echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM
	Or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First configuration page of the web user interface.
	Please Select the PostgreSQL option in the pull-down menu as your Database
	Also Please fill in the SuperUser Name and Password fields.
	On the Second Configuration Page of the web user intercae please fill in the following fields:
	Server: Use the IP or Doamin name assigned to the remote postgresql database server machine
	Port: use the port for the remote postgresql server
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_passwd"
	Create Database Username: Database_Superuser_Name of the remote postgresql server
	Create Database Password: Database_Superuser_password of the remote postgresql server
DELIM
fi

#install & configure basic postgresql-server
if [[ $postgresql_server == "y" ]]; then
    db_name="$database_name"
    db_user_name="$database_user_name"
    db_passwd="$(openssl rand -base64 32;)"
	clear
	for i in postgresql-9.3 php5-pgsql ;do apt-get -y install "${i}"; done
	/etc/init.d/php5-fpm restart
	#Adding a SuperUser and Password for Postgresql database.
	su -l postgres -c "/usr/bin/psql -c \"create role $postgresqluser with superuser login password '$postgresqlpass'\""
	clear
echo ''
	printf '	Please open a web browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'   
cat << DELIM
	Or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First configuration page of the web user interface
	Please Select the PostgreSQL option in the pull-down menu as your Database
	Also Please fill in the SuperUser Name and Password fields.
	On the Second Configuration Page of the web user interface please fill in the following fields:
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_passwd"
	Create Database Username: "$postgresqluser"
	Create Database Password: "$postgresqlpass"
DELIM
else
clear
echo ''
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM
	or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First Configuration page of the web usre interface "$wui_name".
	Also Please fill in the SuperUser Name and Password fields.
	Freeswitch & FusionPBX Web User Interface Installation Completed
	Now you can configure FreeSWITCH using the FusionPBX web user interface
DELIM
fi

#install and enable custom shell admin menu
if [[ $enable_admin_menu == "y" ]]; then
apt-get -y install --force-yes pbx-admin-menu
/bin/cat > /root/.profile <<DELIM
/usr/bin/pbx-admin-menu.sh
DELIM
fi

#Install openvpn openvpn-scripts 
if [[ $install_openvpn == "y" ]]; then
for i in  openvpn openvpn-scripts ;do apt-get -y install --force-yes "${i}"; done
fi
#
#Ajenti admin portal. Makes maintaining the system easier.
#ADD Ajenti repo & ajenti
if [[ $install_ajenti == "y" ]]; then
/bin/cat > "/etc/apt/sources.list.d/ajenti.list" <<DELIM
deb http://repo.ajenti.org/debian main main debian
DELIM
wget http://repo.ajenti.org/debian/key -O- | apt-key add -
apt-get update &> /dev/null && apt-get -y install ajenti
fi

#apt-get cleanup (clean and remove unused pkgs)
apt-get clean && apt-get autoremove

echo " THe install has finished...  "