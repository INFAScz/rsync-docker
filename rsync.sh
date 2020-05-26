#!/bin/sh

# rsync.sh - a script to configure the rsync job in the container

### PREPARATION

echo "Preparation steps started."

# Create an account for rsync
## this is recommended when rsync is not asked to preserve file ownership
if [ "$RSYNC_UID" != "" ] && [ "$RSYNC_GID" != "" ]; then
    # UID and GID provided, create user
    echo "UID and GID provided: $RSYNC_UID and $RSYNC_GID. Creating the user"
    adduser -D -u $RSYNC_UID -g $RSYNC_GID rsyncuser
    RSYNC_USER=rsyncuser
else
    # UID and GID not provided
    echo "UID and GID are NOT provided. Proceeding as the root user."
    RSYNC_USER=root
fi

# run as a cron job?
if [ "$RSYNC_CRONTAB" != "" ]; then
    # using cron
    echo "Running rsync with cron and with a provided crontab selected."
    echo "The crontab file is expected to be at /rsync/$RSYNC_CRONTAB ."
    echo "Any provided rsync arguments will be ignored, specify them in the crontab file instead"
    # define the crontab file location
    crontab -u $RSYNC_USER /rsync/$RSYNC_CRONTAB
else
    # no cron job
    echo "Running rsync as a cron job NOT selected."
fi


# get cmd args
ARGS_A=($@)
DSDIR="/data/src"
DDDIR="/data/dst"

if [ $# > 1 ]; then    
    SRC_DIR=${ARGS_A[$[$#-2]]:="${DSDIR}"}
    DST_DIR=${ARGS_A[$[$#-1]]:="${DDDIR}"}
    echo "INF: Are the last two arguments to the directory?"

    if [ ! -d ${SRC_DIR} ] || [ ! -d ${DST_DIR} ]; then
            echo "ERR: SRC (${SRC_DIR}) or DSC (${DST_DIR}) path isn't dir !!!"
            echo "INF: Fix to default DIRs (${DSDIR}, ${DDDIR})"
            SRC_DIR="${DSDIR}"
            DST_DIR="${DDDIR}"
    else
            echo "OK: DIRs for rsync exist"
    fi

    ARGS_S="${@%$SRC_DIR}"
    OPTION="${ARGS_S%$DST_DIR} ${OPTION:-} ${SRC_DIR} ${DST_DIR}"
    echo "DBG: ${OPTION}"    
else
    echo "WARN: Few arguments. Default folders are set for rsync."
    OPTION="${1:-} ${DSDIR} ${DDDIR}"
fi

echo "Preparation steps completed."

### EXECUTION

if [ -z "$RSYNC_CRONTAB" ] || [ "$RUN_ON_START" == "true" ]; then
    # one time run
    echo "Executing rsync as an one time run..."
    eval rsync $OPTION
fi

if [ -n "$RSYNC_CRONTAB" ]; then
    # run as a cron job, start the cron daemon
    echo "Starting the cron daemon..."
    crond -f
fi
