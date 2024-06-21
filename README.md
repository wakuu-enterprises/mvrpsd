# Muvor Protocol Secure (MVRPS)

## Description

A secure custom protocol implementation for Muvor Protocol Secure (MVRPS) using TLS in Julia.

## Installation

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Implementation

### Client

```bash
using MVRPS

client = MVRPSClient("127.0.0.1", 8443, "client-key.pem", "client-cert.pem", "ca-cert.pem")
response = request(client, "CREATE", "/", "Hello, secure server!")
println("Response: ", response)
```

### Server

```bash
using MVRPS

server = MVRPSServer("127.0.0.1", 8443, "server-key.pem", "server-cert.pem")
run(server) do req, res
    println("Received $(req.method) request for $(req.path)")
    if req.method == "OPTIONS"
        res.status = 204
        res.headers["Allow"] = "OPTIONS, CREATE, READ, EMIT, BURN"
    elseif req.method == "CREATE"
        res.status = 201
        res.body = "Resource created\n"
    elseif req.method == "READ"
        res.status = 200
        res.body = "Resource read\n"
    elseif req.method == "EMIT"
        res.status = 200
        res.body = "Event emitted\n"
    elseif req.method == "BURN"
        res.status = 200
        res.body = "Resource burned\n"
    else
        res.status = 405
        res.body = "Method not allowed\n"
    end
end
```
