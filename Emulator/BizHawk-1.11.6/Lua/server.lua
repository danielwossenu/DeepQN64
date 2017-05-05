-- load namespace
local socket = require("socket")
-- create a TCP socket and bind it to the local host, at any port
local server = socket.tcp()
server:bind("10.0.0.92", 12345)
--local server = socket.bind("10.0.0.92", 12345)
-- find out which port the OS chose for us
server:listen(5)
local ip, port = server:getsockname()
print(ip)
print(port)
-- print a message informing what's up
--print("Please telnet to localhost on port " .. port)


-- wait for a connection from any client
server:settimeout(60)
local client = server:accept()
print(client)
local line, err = client:receive()
print(line)
print('accepted')
--local line, err = client:receive()
--print(line)
-- if there was no error, send it back to the client
client:close()