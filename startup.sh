#!/bin/sh -e

###################################################################################
# Shell script for starting Subsonic.  See http://subsonic.org.
#
# Author: Sindre Mehus
#
# Adapted for docker use by Michael Schuerig <michael@schuerig.de>
# Adapted for alpine/docker use by Marco Paganini <paganini@paganini.net>
#
###################################################################################

SUBSONIC_HOME=/var/subsonic
SUBSONIC_HOST=0.0.0.0
SUBSONIC_PORT=4040
SUBSONIC_HTTPS_PORT=0
SUBSONIC_CONTEXT_PATH=/
SUBSONIC_MAX_MEMORY=200
SUBSONIC_PIDFILE=
SUBSONIC_DEFAULT_MUSIC_FOLDER=/var/music
SUBSONIC_DEFAULT_PODCAST_FOLDER=${SUBSONIC_HOME}/podcasts
SUBSONIC_DEFAULT_PLAYLIST_FOLDER=${SUBSONIC_HOME}/playlists

SUBSONIC_USER=subsonic

# MySQL variables
SUBSONIC_MYSQL_PORT=3306
SUBSONIC_MYSQL_USER=subsonic
SUBSONIC_MYSQL_PASSWORD=subsonic
SUBSONIC_MYSQL_DATABASE=subsonic
SUBSONIC_MYSQL_ENCODING=UTF-8

export LANG=POSIX
export LC_ALL=en_US.UTF-8

quiet=0

usage() {
    echo "Usage: subsonic.sh [options]"
    echo "  --help               This small usage guide."
    echo "  --home=DIR           The directory where Subsonic will create files."
    echo "                       Make sure it is writable. Default: /var/subsonic"
    echo "  --host=HOST          The host name or IP address on which to bind Subsonic."
    echo "                       Only relevant if you have multiple network interfaces and want"
    echo "                       to make Subsonic available on only one of them. The default value"
    echo "                       will bind Subsonic to all available network interfaces. Default: 0.0.0.0"
    echo "  --port=PORT          The port on which Subsonic will listen for"
    echo "                       incoming HTTP traffic. Default: 4040"
    echo "  --https-port=PORT    The port on which Subsonic will listen for"
    echo "                       incoming HTTPS traffic. Default: 0 (disabled)"
    echo "  --context-path=PATH  The context path, i.e., the last part of the Subsonic"
    echo "                       URL. Typically '/' or '/subsonic'. Default '/'"
    echo "  --max-memory=MB      The memory limit (max Java heap size) in megabytes."
    echo "                       Default: 100"
    echo "  --pidfile=PIDFILE    Write PID to this file. Default not created."
    echo "  --quiet              Don't print anything to standard out. Default false."
    echo "  --default-music-folder=DIR    Configure Subsonic to use this folder for music.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/music'"
    echo "  --default-podcast-folder=DIR  Configure Subsonic to use this folder for Podcasts.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/music/Podcast'"
    echo "  --default-playlist-folder=DIR Configure Subsonic to use this folder for playlists.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/playlists'"
    echo "  --mysql-host=HOST             Set external mysql server host. If set the -Dsubsonic.db will be added."
    echo "  --mysql-port=PORT             Set external mysql server port. Default: 3306."
    echo "  --mysql-user=USER             The user for mysql. Default: subsonic."
    echo "  --mysql-password=PASSWORD     The password for mysql. Default: subsonic."
    echo "  --mysql-database=DATABASE     The database for mysql. Default: subsonic."
    echo "  --mysql-encoding=ENCODING     The character encroding for mysql. Default: UTF-8."
    exit 1
}


# Parse arguments.
while [ $# -ge 1 ]; do
    case $1 in
        debug)
            exec /bin/sh
            ;;
        --help)
            usage
            ;;
        --home=?*)
            SUBSONIC_HOME=${1#--home=}
            ;;
        --host=?*)
            SUBSONIC_HOST=${1#--host=}
            ;;
        --port=?*)
            SUBSONIC_PORT=${1#--port=}
            ;;
        --https-port=?*)
            SUBSONIC_HTTPS_PORT=${1#--https-port=}
            ;;
        --context-path=?*)
            SUBSONIC_CONTEXT_PATH=${1#--context-path=}
            ;;
        --max-memory=?*)
            SUBSONIC_MAX_MEMORY=${1#--max-memory=}
            ;;
        --pidfile=?*)
            SUBSONIC_PIDFILE=${1#--pidfile=}
            ;;
        --quiet)
            quiet=1
            ;;
        --mysql-host=?*)
            SUBSONIC_MYSQL_HOST=${1#--mysql-host=}
            ;;
        --mysql-port=?*)
            SUBSONIC_MYSQL_PORT=${1#--mysql-port=}
            ;;
        --mysql-user=?*)
            SUBSONIC_MYSQL_USER=${1#--mysql-user=}
            ;;
        --mysql-password=?*)
            SUBSONIC_MYSQL_PASSWORD=${1#--mysql-password=}
            ;;
        --mysql-database=?*)
            SUBSONIC_MYSQL_DATABASE=${1#--mysql-database=}
            ;;
        --mysql-charset=?*)
            SUBSONIC_MYSQL_ENCODING=${1#--mysql-charset=}
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Check external mysql arg
if [[ -z "${SUBSONIC_MYSQL_HOST}" ]]; then
    SUBSONIC_MYSQL_ARG=""
else
    SUBSONIC_MYSQL_ARG="jdbc:mysql://${SUBSONIC_MYSQL_HOST}:${SUBSONIC_MYSQL_PORT}/${SUBSONIC_MYSQL_DATABASE}?user=${SUBSONIC_MYSQL_USER}&password=${SUBSONIC_MYSQL_PASSWORD}&characterEncoding=${SUBSONIC_MYSQL_ENCODING}"
fi

# Create Subsonic home directory.
mkdir -p \
    ${SUBSONIC_HOME} \
    ${SUBSONIC_DEFAULT_PODCAST_FOLDER} \
    ${SUBSONIC_DEFAULT_PLAYLIST_FOLDER} \
    /tmp/subsonic

LOG=${SUBSONIC_HOME}/subsonic_sh.log
truncate -s0 ${LOG}

    
cd /usr/share/subsonic

exec /usr/bin/java -Xmx${SUBSONIC_MAX_MEMORY}m \
    -Dsubsonic.home=${SUBSONIC_HOME} \
    -Dsubsonic.host=${SUBSONIC_HOST} \
    -Dsubsonic.port=${SUBSONIC_PORT} \
    -Dsubsonic.httpsPort=${SUBSONIC_HTTPS_PORT} \
    -Dsubsonic.contextPath=${SUBSONIC_CONTEXT_PATH} \
    -Dsubsonic.defaultMusicFolder=${SUBSONIC_DEFAULT_MUSIC_FOLDER} \
    -Dsubsonic.defaultPodcastFolder=${SUBSONIC_DEFAULT_PODCAST_FOLDER} \
    -Dsubsonic.defaultPlaylistFolder=${SUBSONIC_DEFAULT_PLAYLIST_FOLDER} \
    -Dsubsonic.db=${SUBSONIC_MYSQL_ARG} \
    -Djava.awt.headless=true \
    -verbose:gc \
    -jar subsonic-booter-jar-with-dependencies.jar >> ${LOG} 2>&1
