ARG GOLANG_VERSION
ARG ALPINE_VERSION

## build
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG VERSION
ARG APPNAME

RUN apk --no-cache add make; \
    adduser -D -h /dummy dummy

USER dummy
WORKDIR /dummy

COPY --chown=dummy Makefile Makefile
COPY --chown=dummy main.go main.go
COPY --chown=dummy static static
COPY --chown=dummy go.sum go.sum
COPY --chown=dummy go.mod go.mod

RUN go mod download

RUN make go-build


## execute
FROM alpine:${ALPINE_VERSION}

ARG VERSION
ARG APPNAME

ENV SERVER_PORT ""

# > non-root (root to install packages)
USER root
RUN apk --no-cache add bind-tools curl

RUN adduser -D -h /dummy dummy
USER dummy

WORKDIR /dummy
COPY --from=builder /dummy/${APPNAME}-${VERSION} ./${APPNAME}
COPY --from=builder /dummy/static ./static
CMD ["./shell-executor"]
