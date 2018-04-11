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

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- $KAFKA_SERVER_EXECUTABLE "config/server.properties" "$@"
fi

# check for the expected command
if [ "$1" = "$KAFKA_SERVER_EXECUTABLE" ] && [ "$(id -u)" = '0' ]; then
    
    chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_DATA_DIR $KAFKA_LOGS_DIR
    
    # make sure we can write to stdout and stderr as "$KAFKA_USER"
    chown --dereference $KAFKA_USER:$KAFKA_GROUP "/proc/$$/fd/1" "/proc/$$/fd/2" || :

    exec su-exec $KAFKA_USER:$KAFKA_GROUP "$@"
fi

# else default to run whatever the user wanted like "bash" or "sh"
exec "$@"