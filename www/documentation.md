## Web Events Agent
This agent adds a web server to the control4 system in order to integrate with other software.
You can use the properties links to enumerate commands that you can send to this agent.
You can get or set the driver's variables through a HTTP/HTTPS GET message.
You can fire off events that you create (actions tab) and do whatever you want through composer programming.

You can set SSL cetificate & private key, you should change from the default for security reasons, but is fine for testing
(agent is open source, private key is not private and a man in the middle attact will reveal your password)
Especially if your forwarding from WAN, which you also shouldn't do, use a VPN

## Usage Ideas / Enhancements
### Fire Other Drivers Events / Actions
- I would like to add the ability to fire other drivers events, but have not figured out how to do so yet
- I can enumerate the other drivers events and paramaters but have no way of calling them, if you know how, let me know
- It is easy enough to add an event and call the other drivers even through programming, so not a big deal if it isnt supported.

### Stream Deck
- I currently use API Ninja with the stream deck to have quick access to music / lighting devices controlled through Control 4
- I am thinking of writing a Stream Deck driver that would integrate with this agent
- It would then be possible to return status / change icons (ex Show Open Garage Door when it is actually open, closed when closed)
- It should be possible to get the Experience Icons and use those directly in stream deck by accessing the ex. http://contoller_ip/driver/DRIVER_NAME/icons/experience_300.png

### Quick Actions / Watch
- I use "HTTP Shortcuts" app on android to have quick access to Unlock Door, Open Garage Doors, etc without having to open Control 4 app.
- I dont have a smart watch, but there seem to be similar apps that could provide quick access from the watch.

### DuckDNS / LetsEncrypt Support
I personally use a reverse proxy and access all my local services through there and the reverse proxy handles the DNS Updates / LetsEncrypt renewals.
It a lot to setup for one off device but it should be possible to have the agent handle updating IP, adding the TXT and getting the new certificate.
Let me know if there is a lot of interest in this, you can manually set the certificate in the properties and it defaults to a self signed one.