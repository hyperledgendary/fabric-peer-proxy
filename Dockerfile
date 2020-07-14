ARG ALPINE_VERSION=3.10

FROM alpine:${ALPINE_VERSION} as tools

ARG GRPC_TOOLS_VERSION=0.2.6

ADD https://github.com/bradleyjkemp/grpc-tools/releases/download/v${GRPC_TOOLS_VERSION}/grpc-tools_${GRPC_TOOLS_VERSION}_Linux_amd64.zip /tmp
RUN unzip -d /tmp /tmp/grpc-tools_${GRPC_TOOLS_VERSION}_Linux_amd64.zip

FROM alpine:${ALPINE_VERSION}

RUN apk --no-cache add libc6-compat

RUN addgroup -g 500 proxy && adduser -u 500 -D -h /home/proxy -G proxy proxy

USER proxy

WORKDIR /home/proxy

COPY --from=tools /tmp/grpc-dump ./grpc-dump
COPY fabric-protos/ ./protos

# Chaincode as a server
CMD ["/home/proxy/grpc-dump", "-interface=0.0.0.0", "-port=9999", "-destination=fabcar.example.com:9999", "-proto_roots=/home/proxy/protos", "-log_level=debug"]
