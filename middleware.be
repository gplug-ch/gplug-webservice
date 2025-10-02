var middleware = module()

import strict
import constants
import handlers
import json

var utf8 = {
    '%C3%A4': 'ä',
    '%C3%B6': 'ö',
    '%C3%BC': 'ü',
    '%C3%84': 'Ä',
    '%C3%96': 'Ö',
    '%C3%9C': 'Ü'
}

handle_cors = def(dto)
    # get request
    var request = dto['request']
    var origin = request.find('origin', "*")

    # get response
    var response = dto['response']

    # add CORS to response
    var cors = {}
    cors.insert('Allow', "GET, POST, PUT, OPTIONS")
    cors.insert('Access-Control-Allow-Origin', "*")
    cors.insert('Access-Control-Allow-Methods', "GET, POST, PUT, OPTIONS")
    cors.insert('Access-Control-Allow-Headers', "Content-Type, X-Requested-With")

    response.insert('cors', cors)
end

#
# Decode shall return a map with either "request" or "error"
#
middleware.decode = def(dto)

    def utf8_decode(s)
        var out = s
        for key: utf8.keys()
            out = string.replace(out, key, utf8[key])
        end
        return out
    end

    def parse_and_add_url(request, url)
        var parts = string.split(url, "?")
        request.insert("url", parts[0])
        if size(parts) > 1
            var params = {}
            var request_params = string.split(parts[1], "&")
            for param : request_params
                var entries = string.split(param, "=")
                if size(entries) > 1
                    params.insert(entries[0], utf8_decode(entries[1]))
                else
                    params.insert(param)
                end
            end
            request.insert("req_params", params)
        end
    end

    def decode_http_message(dto)
        var request = dto["request"]
        var http_message = request["http_message"]

        # split http message into header and body
        var sections = string.split(http_message, "\r\n\r\n")

        # parse http message header
        var lines = string.split(sections[0], "\r\n")
        for line : lines
            if string.count(line, ":") == 0
                # parse the start line
                var parts = string.split(line, " ")
                var method = string.tr(parts[0],' ','')
                request.insert("method", string.toupper(method))
                var url = string.tr(parts[1],' ','')
                parse_and_add_url(request, url)
                request.insert("version", string.tr(parts[2],' ',''))
            else
                # parse header lines of the format: <key>:<value>
                var parts = string.split(line, ":", 1)
                # remove spaces
                var key = string.tr(parts[0],' ','')
                var value = string.tr(parts[1],' ','')
                request.insert(string.tolower(key), string.tolower(value))
            end
        end

        # handle http message body, if available
        if size(sections) > 1
            request.insert("body", sections[1])
        end

        # generate dto
        dto.insert("request", request)

        # handle cors
        handle_cors(dto)

        # check if OPTIONS method is used
        if request['method'] == 'OPTIONS'
            logger.logMsg(logger.lDebug, "OPTIONS request received, skipping further processing.")
            var response = map()
            response.insert("status_code", 204)
            dto.insert("response", response)
        end
    end

    # Check dto
    assert(dto != nil, "Error: dto cannot be nil")
        
    # Call decoders
    decode_http_message(dto)
end

#
# Encode shall return the encoded bytes
#
middleware.encode = def(msg)

    def cors_header(cors)
        var cors_header = ""
        for key : cors.keys()
            cors_header += f"{key}: {cors[key]}\r\n"
        end
        return cors_header
    end

    def encode_http_message(data)
        # get response
        var response = data['response']
        var status_code = response['status_code']
        var content_type = response.find('content_type', 'application/json; charset=UTF-8')

        # create header for the http message
        var header = f"HTTP/1.1 {status_code}\r\n"
        header += f"Content-Type: {content_type}\r\n"
        header += cors_header(response['cors'])
        header += "\r\n"

        # get body for the  http message  
        var payload = response.find('body', '')

        # create http message
        return header + json.dump(payload)
    end

    # Check msg
    assert(msg != nil, "Error: msg cannot be nil")

    # Call encoders
    var http_message = encode_http_message(msg)
    return http_message
end

return middleware