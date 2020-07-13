# fabric-peer-proxy

grpc-dump proxy in docker to intercept Fabric peer gRPC messages

```
docker build -t hyperledgendary/fabric-proxy .
```

## Usage (TBC)

Seemed to work with chaincode as a server... 

```
docker run -it --rm --name proxy.example.com --hostname proxy.example.com -p 9999:9999 --network=small_fabricdev hyperledgendary/fabric-proxy
docker run -it --rm --name fabcar.example.com --hostname fabcar.example.com --env-file chaincode.env --network=small_fabricdev hyperledger/fabcar-sample

docker run -it --rm --name proxy.example.com --hostname proxy.example.com --network=small_fabricdev --entrypoint=/bin/sh hyperledgendary/fabric-proxy

./grpc-dump -interface=0.0.0.0 -port=9999 -destination=fabcar.example.com:9999 -proto_roots=/home/proxy/protos -log_level=debug
```

Need to shut down the gRPC connection before grpc-dump will show any of the messages.

Currently attempting to see if it will work with "normal" chaincode.

## Misc

```
docker run --rm -it --entrypoint=/bin/sh hyperledgendary/fabric-proxy
```
