# fabric-peer-proxy

grpc-dump proxy in docker to intercept Fabric peer gRPC messages

## Build

```
docker build -t hyperledgendary/fabric-proxy .
```

## Usage

Seemed to work with the [fabcar chaincode as a server sample](https://github.com/hyperledger/fabric-samples/tree/master/chaincode/fabcar/external).

Use the address of proxy in the `connection.json` configuration file instead of the chaincode server.
Start the proxy as well when starting the chaincode server, e.g.

```
docker run -it --rm --name proxy.example.com --hostname proxy.example.com -p 9999:9999 --network=small_fabricdev hyperledgendary/fabric-proxy
docker run -it --rm --name fabcar.example.com --hostname fabcar.example.com --env-file chaincode.env --network=small_fabricdev hyperledger/fabcar-sample
```

**Note** Due to a [grpc-dump issue](https://github.com/bradleyjkemp/grpc-tools/issues/6) the gRPC connection must finish before any of the messages are displayed. Just stopping and restarting the chaincode server should work.

## Decoding messages

Unfortunately Fabric gRPC messages include various `payload` blobs which grpc-dump is not able to decode automatically, but there should be enough information to decode them using the [configtxlator](https://hyperledger-fabric.readthedocs.io/en/release-2.0/commands/configtxlator.html) command. For example:

```
    {
      "message_origin": "server",
      "raw_message": "CA4aAwoBASJAZjE2MzViNTJjNjg5NGZlODk1Nzg4ZjY4ZWRkNzQyNWE1NjI0N2ZhNGZlMDVmMTlmN2YwMDQ5NjE1OTk4MjhiYjoMc21hbGxjaGFubmVs",
      "message": {
        "type": "GET_STATE_BY_RANGE",
        "payload": "CgEB",
        "txid": "f1635b52c6894fe895788f68edd7425a56247fa4fe05f19f7f004961599828bb",
        "channelId": "smallchannel"
      },
      "timestamp": "2020-07-10T15:36:55.890475672Z"
    },
```

Use [jq](https://stedolan.github.io/jq/) and the `base64 --decode` command to extract the payload you're interested in. Then decode it using `configtxlator`, e.g. for the example above:

```
configtxlator proto_decode --type=protos.GetStateByRange --input=payload.bin
```

Use the [fabric-protos](https://github.com/hyperledger/fabric-protos) project to find the correct message for the `--type` argument. The decoded `GET_STATE_BY_RANGE` payload should look like this:

```
{
	"collection": "",
	"endKey": "",
	"metadata": null,
	"startKey": "\u0001"
}
```

## Future

Making this work with "normal" chaincode, or with a client app could be useful.

## Misc

```
docker run --rm -it --entrypoint=/bin/sh hyperledgendary/fabric-proxy
```

```
    {
      "message_origin": "client",
      "raw_message": "CAUaDgoMcXVlcnlBbGxDYXJzIkBmMTYzNWI1MmM2ODk0ZmU4OTU3ODhmNjhlZGQ3NDI1YTU2MjQ3ZmE0ZmUwNWYxOWY3ZjAwNDk2MTU5OTgyOGJiKswICoAICtsHCmwIAxoMCJeWovgFENeJ3aUDIgxzbWFsbGNoYW5uZWwqQGYxNjM1YjUyYzY4OTRmZTg5NTc4OGY2OGVkZDc0MjVhNTYyNDdmYTRmZTA1ZjE5ZjdmMDA0OTYxNTk5ODI4YmI6ChIIEgZmYWJjYXIS6gYKzQYKDkh1bWJvbGR0T3JnTVNQEroGLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNOVENDQWR1Z0F3SUJBZ0lRSVplTTlaZ1lka3NDVUlYZ3hkeDk3REFLQmdncWhrak9QUVFEQWpCN01Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RWRNQnNHQTFVRUNoTVVhSFZ0WW05c1pIUXVaWGhoYlhCc1pTNWpiMjB4SURBZUJnTlZCQU1UCkYyTmhMbWgxYldKdmJHUjBMbVY0WVcxd2JHVXVZMjl0TUI0WERUSXdNRGN4TURFME1qa3dNRm9YRFRNd01EY3cKT0RFME1qa3dNRm93YnpFTE1Ba0dBMVVFQmhNQ1ZWTXhFekFSQmdOVkJBZ1RDa05oYkdsbWIzSnVhV0V4RmpBVQpCZ05WQkFjVERWTmhiaUJHY21GdVkybHpZMjh4RGpBTUJnTlZCQXNUQldGa2JXbHVNU013SVFZRFZRUUREQnBCClpHMXBia0JvZFcxaWIyeGtkQzVsZUdGdGNHeGxMbU52YlRCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUgKQTBJQUJJeUJqM1FMYVJrM04yK29TdmFDZ0lGK1pSWlJFNS96ZlljNXY5UnNqWWxNZWMwVE5GbmQvTkwzcnRGTApxZUN2TjgzYjNRdDZTT0RsZjZDQkxRbUZuTmlqVFRCTE1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBTUJnTlZIUk1CCkFmOEVBakFBTUNzR0ExVWRJd1FrTUNLQUlPbHFzSXNoN0RzRTFWYkpUdkRobGF1K2lFcERYTkdPelhuYVR5SnoKVm8yaU1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRRHltdjFpUXEwR0ttQkxrekZYWlRJemdOZnNlTkRlU2kxMgpyT2kyQzVUczVnSWdTYlZEREFYV0dKQzJMQjRUWnVJNVRPRG9lbGQ3K0dlNnpwdmxaaGFSa3VrPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tChIY6GPIamn6YbiU9bDq6xK9BUey+HZNTOkMEiAKHgocCAESCBIGZmFiY2FyGg4KDHF1ZXJ5QWxsQ2FycxJHMEUCIQCNLA7Z31pWm03cD5NsY4FHUktPVfuqVmzD6YsSoaggZgIgPMT7VZUoFF0Y8tkB4gyC4za65mZ2UpMBc7g4T0tzycg6DHNtYWxsY2hhbm5lbA==",
      "message": {
        "type": "TRANSACTION",
        "payload": "CgxxdWVyeUFsbENhcnM=",
        "txid": "f1635b52c6894fe895788f68edd7425a56247fa4fe05f19f7f004961599828bb",
        "proposal": {
          "proposalBytes": "CtsHCmwIAxoMCJeWovgFENeJ3aUDIgxzbWFsbGNoYW5uZWwqQGYxNjM1YjUyYzY4OTRmZTg5NTc4OGY2OGVkZDc0MjVhNTYyNDdmYTRmZTA1ZjE5ZjdmMDA0OTYxNTk5ODI4YmI6ChIIEgZmYWJjYXIS6gYKzQYKDkh1bWJvbGR0T3JnTVNQEroGLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNOVENDQWR1Z0F3SUJBZ0lRSVplTTlaZ1lka3NDVUlYZ3hkeDk3REFLQmdncWhrak9QUVFEQWpCN01Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RWRNQnNHQTFVRUNoTVVhSFZ0WW05c1pIUXVaWGhoYlhCc1pTNWpiMjB4SURBZUJnTlZCQU1UCkYyTmhMbWgxYldKdmJHUjBMbVY0WVcxd2JHVXVZMjl0TUI0WERUSXdNRGN4TURFME1qa3dNRm9YRFRNd01EY3cKT0RFME1qa3dNRm93YnpFTE1Ba0dBMVVFQmhNQ1ZWTXhFekFSQmdOVkJBZ1RDa05oYkdsbWIzSnVhV0V4RmpBVQpCZ05WQkFjVERWTmhiaUJHY21GdVkybHpZMjh4RGpBTUJnTlZCQXNUQldGa2JXbHVNU013SVFZRFZRUUREQnBCClpHMXBia0JvZFcxaWIyeGtkQzVsZUdGdGNHeGxMbU52YlRCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUgKQTBJQUJJeUJqM1FMYVJrM04yK29TdmFDZ0lGK1pSWlJFNS96ZlljNXY5UnNqWWxNZWMwVE5GbmQvTkwzcnRGTApxZUN2TjgzYjNRdDZTT0RsZjZDQkxRbUZuTmlqVFRCTE1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBTUJnTlZIUk1CCkFmOEVBakFBTUNzR0ExVWRJd1FrTUNLQUlPbHFzSXNoN0RzRTFWYkpUdkRobGF1K2lFcERYTkdPelhuYVR5SnoKVm8yaU1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRRHltdjFpUXEwR0ttQkxrekZYWlRJemdOZnNlTkRlU2kxMgpyT2kyQzVUczVnSWdTYlZEREFYV0dKQzJMQjRUWnVJNVRPRG9lbGQ3K0dlNnpwdmxaaGFSa3VrPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tChIY6GPIamn6YbiU9bDq6xK9BUey+HZNTOkMEiAKHgocCAESCBIGZmFiY2FyGg4KDHF1ZXJ5QWxsQ2Fycw==",
          "signature": "MEUCIQCNLA7Z31pWm03cD5NsY4FHUktPVfuqVmzD6YsSoaggZgIgPMT7VZUoFF0Y8tkB4gyC4za65mZ2UpMBc7g4T0tzycg="
        },
        "channelId": "smallchannel"
      },
      "timestamp": "2020-07-10T15:36:55.890159807Z"
    }
```
