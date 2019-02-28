# Demo Server

This is a server demonstrating how `irmago/server/irmaserver` can be used inside a go server. This example is not a fully featured application server. In particular, this example simply returns the attribute value to the caller, whilst a real application would likely want to use these in the context of a larger session.

## Usage

First, fetch any dependencies using `go get`. Then the server can be build using `go build`. To run the server, simply invoke it with `./demoserver <ip-address-here>`. The server will listen on port 8080.
