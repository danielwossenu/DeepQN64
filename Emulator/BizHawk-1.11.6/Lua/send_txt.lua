local socket = require("socket")
host = "DESKTOP-EI4HS56"
host = '10.0.0.92'
port = 12345
print(host, port)
print("Attempting connection to host '" ..host.. "' and port " ..port.. "...")
c = socket.connect(host, port)

c:send('exit')
--c = assert(conn.connect(host, port))
--print('worked')