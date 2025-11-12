# gPlug Webservice

Web Service for the gPlug Smart-Meter Adapter System

## About  

`gplug-webservice` is the backend web-service component for the **gPlug** ecosystem (see [gplug.ch](https://gplug.ch/) for context).  
The gPlug hardware is an IoT adapter for Swiss smart-meters, reading energy data via the customer interface (CII) and making it available via local web UI, MQTT, HTTP etc. :contentReference[oaicite:0]{index=0}  
This repository implements the service layer that supports retrieving, processing, and exposing the smart-meter data.

## Features  

- REST / OpenAPI interface for accessing smart‐meter data  
- Support for multiple meter types / interfaces  
- Local network focus: allows smart home / energy‐management integration  
- Designed to pair with the gPlug hardware firmware (e.g., using Tasmota & Berry scripting)

## Getting Started  

### Prerequisites  

- A supported smart‐meter with customer interface (CII) enabled by your grid operator (for Switzerland)
- The gPlug hardware device connected and configured (WiFi/Ethernet, etc.)  
- The gPlug hardware for running this web service  

## OpenAPI

[OpenAPI specification](https://gplug-ch.github.io/gplug-webservice/latest/docs.html)
