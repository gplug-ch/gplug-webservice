var clientsocket = module()

import strict
import math
import logger
import middleware
import handlers

class ClientSocket
    var id
    var socket
    var done

    def init(socket)
        assert(socket != nil, "Error: socket property cannot be nil")

        # Create an unique id
        self.id= f"client_socket_{math.rand()}"
        self.socket = socket

        # Register with tasmota to get periodic calls to every_50ms()
        tasmota.add_driver(self)

        logger.logMsg(logger.lDebug, f"ClientSocket '{self.id}' created")
        self.done = false
    end

    #
    # Handle_request() shall be called from an external event poller
    # with a frequency between 1/10 and 200 Hz
    #
    def handle_request()
        # Check for new data that might have arrived on this socket
        if (self.socket.connected() == false) || (self.socket.available() == 0)
            return false
        end

        # Read the message as bytes
        var bytes_request = self.socket.readbytes()
        var http_request_message = bytes_request.asstring()
        
        # Initialize DTO
        var dto = {"request":{"http_message": http_request_message}, "response": {}}

        # Decode the message
        middleware.decode(dto)
  
        # Process the message
        handlers.http_handler(dto)

        # Encode the message
        var http_response_message = middleware.encode(dto)

        # Convert message to bytes
        var bytes_response = bytes().fromstring(http_response_message)

        # Send the response
        assert(bytes_response != nil, "Error: bytes_response cannot be nil")
        var bytesSent = self.socket.write(bytes_response)
        logger.logMsg(logger.lDebug, f"ClientSocket '{self.id}' sent {bytesSent} bytes in response")
        
        return true
    end

    def every_50ms()  # 20 Hz
        if ! self.socket.connected() && self.socket != nil
            self.shutdown()
        elif self.done
            self.shutdown()
        else
            self.done = self.handle_request()
        end
    end

    def shutdown()
        if self.socket!= nil
            logger.logMsg(logger.lDebug, f"ClientSocket '{self.id}' closed")
            self.socket.close()
            self.socket = nil
            tasmota.remove_driver(self)
            self.id = nil
        end
    end

    def deinit()
        self.shutdown()
    end
end

clientsocket.start = def(socket)
    ClientSocket(socket)
end

return clientsocket