import socket               # Import socket module

s = socket.socket()         # Create a socket object
host = socket.gethostbyname(socket.gethostname()) # Get local machine name
port = 12345               # Reserve a port for your service.
print host
s.connect(('10.0.0.92', port))
s.send('exit\n')
# print s.recv(1024)
s.close                     # Close the socket when done