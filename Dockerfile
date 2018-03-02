FROM openjdk:8-alpine

LABEL maintainer="I Putu Ariyasa"

ARG KAFKA_DOWNLOAD_URL
ENV KAFKA_DOWNLOAD_URL ${KAFKA_DOWNLOAD_URL:-http://www-us.apache.org/dist/kafka/1.0.0/kafka_2.11-1.0.0.tgz}

ENV KAFKA_PARENT_DIR /opt 
ENV KAFKA_HOME_DIR $KAFKA_PARENT_DIR/kafka
RUN apk add --no-cache curl bash &&\
    mkdir -p $KAFKA_HOME_DIR &&\
    curl -l $KAFKA_DOWNLOAD_URL -o $KAFKA_PARENT_DIR/kafka.tar.gz &&\
    tar -zxf $KAFKA_PARENT_DIR/kafka.tar.gz -C $KAFKA_HOME_DIR --strip-components 1 &&\
    apk del curl &&\
    rm -rf $KAFKA_PARENT_DIR/kafka.tar.gz


ENV KAFKA_DATA_DIR /var/lib/kafka
ENV KAFKA_LOGS_DIR /var/log/kafka
COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR $KAFKA_HOME_DIR
ENTRYPOINT [ "/entrypoint.sh" ]
VOLUME ["$KAFKA_DATA_DIR" , "$KAFKA_LOGS_DIR"]
EXPOSE 9092