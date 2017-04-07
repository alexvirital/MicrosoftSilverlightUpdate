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
#   Script to download and install Microsoft Silverlight Player.
#
####################################################################################################
#
# HISTORY
#
#   Version: 1.5
#
#   - v.1.0	Steve Miller, 16.12.2015	Used Joe Farage "AdobeReaderUpdate.sh as starting point
#   - v.1.1	Steve Miller, 16.12.2015	Updated to copy echo commands into JSS policy logs
#   - v.1.2	Steve Miller, 13.01.2016	Fixed minor errors
#   - v.1.3	Steve Miller, 07.03.2016	Fixed minor problem with curl commands
#   - v.1.4	Steve Miller, 07.03.2016	Fixed downloading dmg with curl
#   - v.1.5	Steve Miller, 01.04.2017	Changed script to use JAMF variable due to MS not updating Mac.dmg file while changing version number on History page
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
#####################################################################################################

# Variables used for logging
logfile="/Library/Logs/SilverlightUpdateScript.log"

# Variables used by this script
OSvers_URL=$( sw_vers -productVersion )
userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"
silLightCheckURL="http://www.microsoft.com/getsilverlight/locale/en-us/html/Microsoft%20Silverlight%20Release%20History.htm"
pluginpath="/Library/Internet Plug-Ins/Silverlight.plugin/Contents/Info.plist"
SLversion=""


# CHECK TO SEE IF A VALUE WERE PASSED IN FOR PARAMETERS AND ASSIGN THEM
if [ "$4" != "" ] && [ "$SLversion" == "" ]; then
    SLversion="$4"
fi

####################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
# Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion | sed 's/[.]/_/g' )

# Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

# Get the version number of the currently-installed Microsoft Silverlight, if any.
    if [ -f "${pluginpath}" ]; then
        currentinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Silverlight.plugin/Contents/Info.plist" CFBundleShortVersionString`
        echo "Current installed version is: $currentinstalledver"
        if [ "${SLversion}" = "${currentinstalledver}" ]; then
            echo "Microsoft Silverlight is current. Exiting"
            /bin/echo "`date`: Microsoft Silverlight is current. Exiting, version is ${currentinstalledver}." >> ${logfile}
            /bin/echo "--" >> ${logfile}
        fi
    else
        currentinstalledver="none"
        echo "Microsoft Silverlight is not installed"
    fi

sleep 3

# Building URL and download file
    dmgfile="Silverlight.dmg"
    fileURL="http://go.microsoft.com/fwlink/?LinkID=229322"

fi
# Compare the two versions, if they are different or Microsoft Silverlight is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${SLversion}" ]; then
        /bin/echo "`date`: Current Microsoft Silverlight version: ${currentinstalledver}" >> ${logfile}
        /bin/echo "`date`: Available Microsoft Silverlight version: ${SLversion}" >> ${logfile}
        /bin/echo "`date`: Downloading newer version." >> ${logfile}
        /bin/echo Downloading the DMG
        /usr/bin/curl -L -o /tmp/${dmgfile} ${fileURL}
        /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
        /bin/echo Mounting the DMG
        /usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
        
# Installing Microsoft Silverlight
        /bin/echo Installing Microsoft Silverlight
        /bin/echo "`date`: Installing..." >> ${logfile}
        /usr/sbin/installer -pkg /Volumes/Silverlight/silverlight.pkg -target / > /dev/null

# Unmount DMG and delete tmp files
        /bin/sleep 10
        /bin/echo "`date`: Cleaning up our mess." >> ${logfile}
        /bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
        
        mntpoint=`diskutil list | grep "Silverlight" | awk '{print $6}' `
        /bin/echo The mount point is "$mntpoint"
        /usr/bin/hdiutil unmount $mntpoint -force -quiet
        /usr/bin/hdiutil detach $mntpoint -force -quiet
        /bin/sleep 10
        /bin/echo "`date`: Deleting disk image." >> ${logfile}
        /bin/rm -rf /tmp/silverlight.*
        /bin/rm -rf /tmp/${dmgfile}

# Double check to see if the new version got updated
        newlyinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Silverlight.plugin/Contents/Info.plist" CFBundleShortVersionString`
        if [ "${SLversion}" = "${newlyinstalledver}" ]; then
            /bin/echo "SUCCESS: Microsoft Silverlight has been updated to version ${newlyinstalledver}"
            /bin/echo "`date`: SUCCESS: Microsoft Silverlight has been updated to version ${newlyinstalledver}" >> ${logfile}
            /bin/echo "--" >> ${logfile}
        else
            /bin/echo "ERROR: Microsoft Silverlight update unsuccessful, version remains at ${currentinstalledver}."
            /bin/echo "`date`: ERROR: Microsoft Silverlight update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
            /bin/echo "--" >> ${logfile}
        fi
    fi
