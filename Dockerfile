
############################
# STEP 1 build the JAR   
############################
FROM alpine as builder

RUN apk update \
    && apk add --no-cache \
    libcap \
    ca-certificates \
    make \
    openjdk11 \
    maven \
    npm \
    postgresql-client \
    python3 \
    yarn \
    && update-ca-certificates

COPY . /usr/src/builder
WORKDIR /usr/src/builder

RUN make jar


############################
# STEP 2 build the image
############################
FROM debian:buster-slim as app

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && curl \
        -L \
        -o openjdk.tar.gz \
        https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz \
    && mkdir jdk \
    && tar zxf openjdk.tar.gz -C jdk --strip-components=1 \
    && rm -rf openjdk.tar.gz \
    && apt-get -y --purge autoremove curl \
    && ln -sf /opt/jdk/bin/* /usr/local/bin/ \
    && rm -rf /var/lib/apt/lists/* \
    && java  --version \
    && javac --version \
    && jlink --version
# basic smoke test

WORKDIR "/"
RUN java --version

RUN apt-get update
RUN apt-get install bash
RUN apt-get install -y curl

RUN mkdir shell
RUN mkdir www
RUN mkdir web
RUN mkdir js
RUN mkdir target
RUN mkdir -p sql/create
RUN mkdir logs
RUN mkdir SampleBids
RUN mkdir Campaigns
RUN mkdir query

COPY --from=builder /usr/src/builder/target/RTB5-0.0.1-SNAPSHOT-jar-with-dependencies.jar target/

COPY --from=builder /usr/src/builder/wait-for-it.sh /
RUN chmod +x /wait-for-it.sh

COPY --from=builder /usr/src/builder/tools/* /
COPY --from=builder /usr/src/builder/sql/create/* sql/create/
COPY --from=builder /usr/src/builder/shell/ /shell

COPY --from=builder /usr/src/builder/query/ query/

COPY --from=builder /usr/src/builder/www/index.html /www
COPY --from=builder /usr/src/builder/www/css/ css/
COPY --from=builder /usr/src/builder/www/fonts/ fonts/
COPY --from=builder /usr/src/builder/www/assets/ assets/
COPY --from=builder /usr/src/builder/www/campaigns campaigns/

COPY --from=builder /usr/src/builder/log4j.properties /
COPY --from=builder /usr/src/builder/SampleBids /SampleBids

EXPOSE 8080 5701

CMD ./rtb4free
