var handlers = module()

import strict
import string
import json
import constants
import obiscode
import smartmeter


def get_smartmeter_entry_by_obiscode(obis_code)
    var value = nil
    var entry = obiscode.get_smartmeter_code(obis_code)
    if size(entry) > 0
        var code = entry["code"]
        var scale_factor = entry["scale"]
        var data = smartmeter.get_data()
        if string.find(code, '/') > 0 
            var arr = string.split(code, '/')
            # get value of direction "in"
            var sign = string.endswith(arr[0],'i', true) == true ? 1 : -1
            value = sign * data.find(arr[0], 0)
            if value == 0
                # get value of direction "out"
                sign = string.endswith(arr[1],'o', true) == true ? -1 : 1
                value = sign * data.find(arr[1], 0)
            end
        else
            value = data.find(code, 0)
        end
        value = value * scale_factor
    else

    end
    return value
end

def handle_status_code(response, status_code)
    var msg = constants.HTTP_STATUS_CODES[status_code]
    var status_code_msg = f"{status_code} {msg}"
    response.insert("status_code", status_code_msg)
end

def handle_find_all(dto)
    var response = dto["response"]
    handle_status_code(response, "200")
    var data = []
    var codes = obiscode.get_all_codes()
    for code : codes
        var value = get_smartmeter_entry_by_obiscode(code)
        var entry = {code: value}
        data.push(entry)
    end
    response.insert("body", json.dump(data))
end

def handle_find_by_id(dto)
    var request = dto["request"]
    var response = dto["response"]

    var url = request["url"]
    var url_parts = string.split(url, '/')
    var id = url_parts[2]               # Note: URL starts with '/'
    var value = get_smartmeter_entry_by_obiscode(id)

    if value == nil
        handle_status_code(response, "404")
    else
        handle_status_code(response, "200")
        var data = {id: value}
        response.insert("body", json.dump(data))
    end
end

var http_handlers = {
    '/obiscodes': / dto -> handle_find_all(dto),
    '/obiscodes/{id}': / dto -> handle_find_by_id(dto)
}

def matches_route(url, route_pattern)
    # Split both URL and pattern into segments
    var url_parts = string.split(url, '/')
    var pattern_parts = string.split(route_pattern, '/')
    
    # Must have same number of segments
    if size(url_parts) != size(pattern_parts)
        return false
    end
    
    # Check each segment
    for i: 0..size(url_parts)-1
        var pattern_segment = pattern_parts[i]
        var url_segment = url_parts[i]
        
        # If pattern segment is a parameter (starts with {), it matches anything
        if size(pattern_segment) > 0 && pattern_segment[0] == '{'
            continue
        end
        
        # Otherwise, must match exactly
        if pattern_segment != url_segment
            return false
        end
    end
    
    return true
end

def find_handler(url)
    for route: http_handlers.keys()
        if matches_route(url, route)
            return http_handlers[route]
        end
    end
    return nil
end

handlers.http_handler = def(dto)
    var url = dto["request"].item("url")
    # Check if handler exists for the url
    var handler = find_handler(url)
    if handler == nil
        # Return status code "404 NOT FOUND"
        handle_status_code(dto["response"], "404")   
    else
        handler(dto)
    end 
end

return handlers