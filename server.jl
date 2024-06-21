module MVRPS

export run_server, send_request

using Sockets
using MbedTLS
using MVRP

function handle_request(client::MbedTLS.SSLContext, request::MVRP.MVRPRequest)
    response_headers = Dict("Content-Type" => "text/plain")
    status_line = ""
    response_body = ""

    if request.method == "OPTIONS"
        status_line = "MVRP/1.0 204 No Content"
        response_headers["Allow"] = "OPTIONS, CREATE, READ, EMIT, BURN"
    elseif request.method == "CREATE"
        status_line = "MVRP/1.0 201 Created"
        response_body = "Resource created\n"
    elseif request.method == "READ"
        status_line = "MVRP/1.0 200 OK"
        response_body = "Resource read\n"
    elseif request.method == "EMIT"
        status_line = "MVRP/1.0 200 OK"
        response_body = "Event emitted\n"
    elseif request.method == "BURN"
        status_line = "MVRP/1.0 200 OK"
        response_body = "Resource burned\n"
    else
        status_line = "MVRP/1.0 405 Method Not Allowed"
        response_body = "Method not allowed\n"
    end

    response = "$status_line\r\n"
    for (k, v) in response_headers
        response *= "$k: $v\r\n"
    end
    response *= "\r\n$response_body"
    write(client, response)
end

function run_server(address::String, port::Int, key_file::String, cert_file::String)
    server = listen(address, port)
    println("MVRPS server listening on $address:$port")

    while true
        client, _ = accept(server)
        ssl_config = MbedTLS.SSLConfig()
        cert = MbedTLS.parse_cert_file(cert_file)
        key = MbedTLS.parse_key_file(key_file)
        MbedTLS.config_defaults!(ssl_config, MbedTLS.SSL_IS_SERVER, MbedTLS.SSL_TRANSPORT_STREAM, MbedTLS.SSL_PRESET_DEFAULT)
        MbedTLS.config_ca_chain!(ssl_config, cert, MbedTLS.RSAKey(key))
        ssl_context = MbedTLS.SSLContext(ssl_config)
        MbedTLS.set_bio!(ssl_context, client)

        try
            MbedTLS.handshake!(ssl_context)
            data = String(read(ssl_context))
            request = MVRP.parse_request(data)
            handle_request(ssl_context, request)
        catch e
            println("Error handling request: $e")
        finally
            close(ssl_context)
        end
    end
end

function send_request(address::String, port::Int, method::String, url::String, body::String, key_file::String, cert_file::String, ca_file::String)::String
    client = connect(address, port)
    ssl_config = MbedTLS.SSLConfig()
    cert = MbedTLS.parse_cert_file(cert_file)
    key = MbedTLS.parse_key_file(key_file)
    ca_cert = MbedTLS.parse_cert_file(ca_file)
    MbedTLS.config_defaults!(ssl_config, MbedTLS.SSL_IS_CLIENT, MbedTLS.SSL_TRANSPORT_STREAM, MbedTLS.SSL_PRESET_DEFAULT)
    MbedTLS.config_ca_chain!(ssl_config, ca_cert, MbedTLS.RSAKey(key))
    ssl_context = MbedTLS.SSLContext(ssl_config)
    MbedTLS.set_bio!(ssl_context, client)

    try
        MbedTLS.handshake!(ssl_context)
        request = "$method $url MVRP/1.0\r\nContent-Length: $(length(body))\r\n\r\n$body"
        write(ssl_context, request)
        response = String(read(ssl_context))
    catch e
        println("Error sending request: $e")
        response = ""
    finally
        close(ssl_context)
    end

    return response
end

end # module
