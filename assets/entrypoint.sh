#!/bin/bash
set -e

# change data and logs directory
sed -i '/^log.dirs=/{h;s|=.*|='$KAFKA_DATA_DIR'|};${x;/^$/{s||log.dirs='$KAFKA_DATA_DIR'|;H};x}' config/server.properties
sed -i 's#\${kafka.logs.dir}#'"$KAFKA_LOGS_DIR"'#g' config/log4j.properties

# convert KAFKA_SERVER_* environment variables into server.properties config
while read LINE; do
	IFS='=' read -ra CONF_LINE <<< "$LINE"
	CONF_KEY=$(echo -n "${CONF_LINE[0]#KAFKA_SERVER_}" | tr '[:upper:]' '[:lower:]' | tr '_' '.')
	CONF_VALUE=$(IFS='='; echo "${CONF_LINE[*]:1}")
    CONF_VALUE="${CONF_VALUE/\|/\\|}"
    sed -i '/^'"$CONF_KEY"'=/{h;s|=.*|='"$CONF_VALUE"'|};${x;/^$/{s||'"$CONF_KEY"'='"$CONF_VALUE"'|;H};x}' config/server.properties
done < <(env | grep 'KAFKA_SERVER_')

# executable
KAFKA_SERVER_EXECUTABLE="bin/kafka-server-start.sh"
ARGS=("config/server.properties")
ARGS+=("$@")

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    echo "1"
    set -- $KAFKA_SERVER_EXECUTABLE "${ARGS[@]}"
fi

# check for the expected command
if [ "$1" = "$KAFKA_SERVER_EXECUTABLE" ]; then
    echo "2"
    # init db stuff....
    # use gosu (or su-exec) to drop to a non-root user
    exec $KAFKA_SERVER_EXECUTABLE  "${ARGS[@]}"
fi

# else default to run whatever the user wanted like "bash" or "sh"
exec "$@"