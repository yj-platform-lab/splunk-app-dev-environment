#!/bin/sh

/usr/local/bin/mysql.sh &
mysql_pid=$!

# Check MySQL readiness up to 60 times, waiting 1 second between attempts.
attempt=0
until mysqladmin --protocol=socket --user=root ping --silent >/dev/null 2>&1; do
    if ! kill -0 "$mysql_pid" 2>/dev/null; then
        echo "MySQL process exited before becoming ready." >&2
        wait "$mysql_pid"
        exit 1
    fi

    attempt=$((attempt + 1))
    if [ "$attempt" -ge 60 ]; then
        echo "Timed out waiting for MySQL." >&2
        kill "$mysql_pid" 2>/dev/null
        wait "$mysql_pid"
        exit 1
    fi

    sleep 1
done

# Start Splunk after MySQL becomes ready.
if ! /usr/local/bin/splunk.sh; then
    echo "Failed to start Splunk." >&2
    kill "$mysql_pid" 2>/dev/null
    wait "$mysql_pid"
    exit 1
fi

# Keep the container running while MySQL is running.
wait "$mysql_pid"
