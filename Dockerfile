ARG GOLANG_VERSION
ARG ALPINE_VERSION

## build
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG VERSION
ARG APPNAME

RUN apk --no-cache add make; \
    adduser -D -h /x x

USER x
WORKDIR /x

COPY --chown=x Makefile Makefile
COPY --chown=x main.go main.go
COPY --chown=x static static
COPY --chown=x go.sum go.sum
COPY --chown=x go.mod go.mod

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

RUN adduser -D -h /x x
USER x

WORKDIR /x
COPY --from=builder /x/${APPNAME}-${VERSION} ./${APPNAME}
COPY --from=builder /x/static ./static
CMD ["./shell-executor"]
