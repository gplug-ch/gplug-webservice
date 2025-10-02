var constants = module()

constants.HTTP_STATUS_CODES = {
    "200": "OK",
    "202": "Accepted",
    "204": "No Content",
    "301": "Moved Permanently",
    "302": "Found (Temporary Redirect)",
    "304": "Not Modified",
    "401": "Unauthorized",
    "400": "Bad Request",
    "404": "Not Found",
    "405": "Method Not Allowed",
    "408": "Request Timeout",
    "429": "Too Many Requests",
    "500": "Internal Server Error",
    "501": "Not Implemented",
    "503": "Service Unavailable"
}

return constants