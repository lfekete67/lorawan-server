FROM erlang:20-alpine

ENV TZ=Europe/Budapest 

RUN apk add --no-cache tzdata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk add --no-cache --virtual build-deps git make wget nodejs-npm && \
    git clone https://github.com/lfekete67/lorawan-server.git && \
	git config --global url.https://github.com/.insteadOf git://github.com/ \
    cd lorawan-server && \
    make release install && \
    cd .. && \
    rm -rf lorawan-server && \
    apk del build-deps

# volume for the mnesia database and logs
RUN mkdir /storage
VOLUME /storage

# data from port_forwarders
EXPOSE 1680/udp
# admin interface
EXPOSE 8080/tcp

ENV LORAWAN_HOME=/storage
WORKDIR /usr/lib/lorawan-server
CMD bin/lorawan-server
