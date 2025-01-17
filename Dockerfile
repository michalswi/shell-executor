ARG GOLANG_VERSION
ARG ALPINE_VERSION

## build
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG VERSION
ARG APPNAME

RUN apk --no-cache add make; \
    adduser -D -h /dupa dupa

USER dupa
WORKDIR /dupa

COPY --chown=dupa Makefile Makefile
COPY --chown=dupa main.go main.go
COPY --chown=dupa static static
COPY --chown=dupa go.sum go.sum
COPY --chown=dupa go.mod go.mod

RUN go mod download
RUN make go-build


## execute
FROM alpine:${ALPINE_VERSION}

ARG VERSION
ARG APPNAME

ENV SERVER_PORT ""

# root to install packages
USER root
RUN apk --no-cache add bind-tools curl

RUN adduser -D -h /dupa dupa
USER dupa

WORKDIR /app
COPY --from=builder /dupa/${APPNAME}-${VERSION} ./${APPNAME}
COPY --from=builder /dupa/static ./static
CMD ["./shell-executor"]
