#!/usr/bin/env julia

using Sockets
using OpenSSL
using TOML
using URIParser

# Load configuration from file
config = TOML.parsefile("/etc/mvrps-proxy/config")

LISTEN_ADDRESS = config["listen_address"]
LISTEN_PORT = config["listen_port"]
MVRP_URI = URI(config["mvrp_uri"])
MVRPS_URI = URI(config["mvrps_uri"])
CERT_FILE = config["cert_file"]
KEY_FILE = config["key_file"]

# Function to handle DNS requests
function handle_request(data, use_tls)
    server_uri = use_tls ? MVRPS_URI : MVRP_URI
    server_host = server_uri.host
    server_port = Int(server_uri.port)

    try
        if use_tls
            # Use TLS for secure connection
            ctx = SSLContext()
            server_sock = connect(server_host, server_port)
            ssl_sock = SSLContext.wrap_client(ctx, server_sock)
            println("Connected securely to $server_host:$server_port")
            write(ssl_sock, data)
            response = read(ssl_sock, 512)
            close(ssl_sock)
        else
            # Use non-secure connection
            server_sock = connect(server_host, server_port)
            println("Connected to $server_host:$server_port")
            write(server_sock, data)
            response = read(server_sock, 512)
            close(server_sock)
        end
        return response
    catch e
        println("Failed to connect to server at $server_host:$server_port: $e")
        return nothing
    end
end

# Function to start the proxy daemon
function start_proxy()
    server = listen(IPv4(LISTEN_ADDRESS), LISTEN_PORT)
    println("Listening on $LISTEN_ADDRESS:$LISTEN_PORT")

    while true
        client, client_addr = accept(server)
        @async begin
            println("Connection from $client_addr")
            data = read(client, 512)
            
            # Attempt to handle the request using TLS first
            response = handle_request(data, true)
            
            # If TLS fails, fall back to nonsecure connection
            if response === nothing
                response = handle_request(data, false)
            end
            
            if response !== nothing
                write(client, response)
            else
                println("Failed to handle request from $client_addr")
            end

            close(client)
        end
    end
end

# Main function to start the server
function main()
    start_proxy()
end

# Run the main function
main()
