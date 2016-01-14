#!/bin/sh
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   MicrosoftSilverlightUpdate.sh -- Installs or updates Microsoft Silverlight Player
#
# SYNOPSIS
#   sudo MicrosoftSilverlightUpdate.sh
#
####################################################################################################
#
# HISTORY
#
#   Version: 1.2
#
#   - v.1.0	Steve Miller, 16.12.2015	Used Joe Farage "AdobeReaderUpdate.sh as starting point
#   - v.1.1	Steve Miller, 16.12.2015	Updated to copy echo commands into JSS policy logs
#   - v.1.2	Steve Miller, 13.01.2016	Fixed minor errors
#
####################################################################################################
# Script to download and install Microsoft Silverlight Player.
# Only works on Intel systems.

dmgfile="Silverlight.dmg"
dmgmount="silverlight"
logfile="/Library/Logs/SilverlightUpdateScript.log"
pluginpath="/Library/Internet Plug-Ins/Silverlight.plugin"
tmpmount=`/usr/bin/mktemp -d /tmp/silverlight.XXXX`
silLightCheckURL="http://www.microsoft.com/getsilverlight/locale/en-us/html/Microsoft%20Silverlight%20Release%20History.htm"

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    ## Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion )

    ## Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    # Get the latest version of Silverlight available from Microsoft's Get Silverlight page.
    latestver=``
    while [ -z "$latestver" ]
    do
       latestver=`curl -sf "${silLightCheckURL}" 2>/dev/null | grep -m1 "Silverlight 5 Build" | awk -F'[>|<]' '{print $2}' | tr ' ' '\n' | awk '/Build/{getline; print}'`
    done

    echo "Latest Version is: $latestver"
    latestvernorm=`echo ${latestver} `
    # Get the version number of the currently-installed Microsoft Silverlight, if any.
    if [ -e "${pluginpath}" ]; then
        currentinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Silverlight.plugin/Contents/Info.plist" CFBundleShortVersionString`
        echo "Current installed version is: $currentinstalledver"
        if [ "${latestver}" = "${currentinstalledver}" ]; then
            echo "Microsoft Silverlight is current. Exiting"
            exit 0
        fi
    else
        currentinstalledver="none"
        echo "Microsoft Silverlight is not installed"
    fi


    url1=`curl -sfA "$UGENT" "http://go.microsoft.com/fwlink/?LinkID=229322" | awk -F'"' '{print $2}'`

    #Build URL  
    url=`echo "${url1}"`
    echo "Latest version of the URL is: $url"


    # Compare the two versions, if they are different or Microsoft Silverlight is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${latestvernorm}" ]; then
        /bin/echo "`date`: Current Silverlight version: ${currentinstalledver}" >> ${logfile}
        /bin/echo "`date`: Available Silverlight version: ${latestver} => ${latestvernorm}" >> ${logfile}
        /bin/echo "`date`: Downloading newer version." >> ${logfile}
        /usr/bin/curl -s -o /tmp/${dmgfile} ${url}
        /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
        /usr/bin/hdiutil attach "/tmp/${dmgfile}" -nobrowse -quiet
        /bin/echo "`date`: Installing..." >> ${logfile}
        /usr/sbin/installer -pkg /Volumes/Silverlight/silverlight.pkg -target / > /dev/null

        #Unmount DMG and deleting tmp files
        /bin/sleep 10
        /bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
        mntpoint=`diskutil list | grep Silverlight | awk '{print $6}' `
        /bin/echo The mount point is "$mntpoint"
        hdiutil unmount $mntpoint -force -quiet
        hdiutil detach $mntpoint -force -quiet
        /bin/sleep 10
        /bin/echo "`date`: Deleting disk image." >> ${logfile}
        /bin/rm /tmp/${dmgfile}

        #Double check to see if the new version got updated
        newlyinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Silverlight.plugin/Contents/Info.plist" CFBundleShortVersionString`
        if [ "${latestvernorm}" = "${newlyinstalledver}" ]; then
            /bin/echo "SUCCESS: Microsoft Silverlight has been updated to version ${newlyinstalledver}"
            /bin/echo "`date`: SUCCESS: Microsoft Silverlight has been updated to version ${newlyinstalledver}" >> ${logfile}
        else
            /bin/echo "ERROR: Microsoft Silverlight update unsuccessful, version remains at ${currentinstalledver}."
            /bin/echo "`date`: ERROR: Microsoft Silverlight update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
            /bin/echo "--" >> ${logfile}
            exit 1
        fi

    # If Microsoft Silverlight is up to date already, just log it and exit.       
    else
        /bin/echo "Microsoft Silverlight is already up to date, running ${currentinstalledver}."
        /bin/echo "`date`: Microsoft Silverlight is already up to date, running ${currentinstalledver}." >> ${logfile}
        /bin/echo "--" >> ${logfile}
    fi  
else
    /bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
fi
