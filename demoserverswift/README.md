# Demo Server Swift

This is a server demonstrating how IrmaSwift can be used inside a go server. This example is not a fully featured application server. In particular, this example simply returns the attribute value to the caller, whilst a real application would likely want to use these in the context of a larger session.

## Usage

Running this server requires a prebuilt version of the irmac libraries for your OS. These can be downloaded from <https://github.com/privacybydesign/IrmaServerSwift/releases>. After getting these, the server can be started using `swift run -Xlinker -L/path/to/irmac/libraries/`. The server will listen on port 8080.
