#!/bin/sh

# Prepare the mounted volume for the Splunk user.
mkdir -p /opt/splunk/var/log || exit 1
chown -R splunk:splunk /opt/splunk/var || exit 1

# Create the initial admin account before the first start.
if [ ! -f /opt/splunk/etc/passwd ]; then
    : "${SPLUNK_PASSWORD:?Set SPLUNK_PASSWORD}"

    mkdir -p /opt/splunk/etc/system/local || exit 1

    (
        umask 077
        printf '[user_info]\nUSERNAME = admin\nPASSWORD = %s\n' \
            "$SPLUNK_PASSWORD" \
            > /opt/splunk/etc/system/local/user-seed.conf
    ) || exit 1

    chown splunk:splunk \
        /opt/splunk/etc/system/local/user-seed.conf || exit 1
fi

# Start Splunk as the splunk user.
runuser -u splunk -- /opt/splunk/bin/splunk start \
    --accept-license \
    --answer-yes \
    --no-prompt
