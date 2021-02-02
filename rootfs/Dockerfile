ARG STACK

FROM docker.io/minio/mc:latest as mc


FROM docker.io/drycc/stack-images:${STACK}

# add default port to expose (can be overridden)
ENV PORT 5000
EXPOSE 5000

ADD ./runner /runner
ADD ./bin /bin
ADD ./installer /installer
COPY --from=mc /usr/bin/mc /bin/mc

RUN /installer/install

WORKDIR /app

USER slug
ENV HOME /app
ENTRYPOINT ["/runner/init"]

ONBUILD RUN mkdir -p /app
ONBUILD WORKDIR /app
ONBUILD ADD slug.tgz /app
