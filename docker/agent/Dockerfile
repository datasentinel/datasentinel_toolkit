FROM ubuntu:latest

ARG DATASENTINEL_AGENT_PORT=8282

ENV DATASENTINEL_DIR=/agent
ENV DOCKER_ENV=yes

ADD datasentinel-agent-debian-buster-2.7.1.tar.gz $DATASENTINEL_DIR/


RUN apt-get update \ 
    && apt-get install -y libssl-dev --no-install-recommends \
    && mkdir -p $DATASENTINEL_DIR/config \
    && chgrp -R 0 $DATASENTINEL_DIR \
    && chmod -R g+rwX $DATASENTINEL_DIR \
    && apt-get clean -y autoclean  \
    && rm -rf /var/cache/apk/* \
    && rm -rf /var/lib/apt/lists/*

VOLUME [ "${DATASENTINEL_DIR}/config"]

USER 1001

WORKDIR $DATASENTINEL_DIR

EXPOSE $DATASENTINEL_AGENT_PORT

CMD $DATASENTINEL_DIR/datasentinel/datasentinel start agent
