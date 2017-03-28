import select

from CsiManager import *
from Log import *


class Server:
    ##
    # Constructor method
    #
    def __init__(self, port, senderUri, receiverUri):
        self.port = port
        self.senderUri = senderUri
        self.receiverUri = receiverUri
        self.ready = True

        splitedSender = self.senderUri.split(':', 1)
        try:
            self.senderManager = CsiManager(splitedSender[0], splitedSender[1], 'sender')
        except Exception, e:
            Log.error('Could not create CsiManager of sender: ' + str(e))
            self.ready = False

        splitedReceiver = self.receiverUri.split(':', 1)
        try:
            self.receiverManager = CsiManager(splitedReceiver[0], splitedReceiver[1], 'receiver')
        except Exception, e:
            Log.error('Could not create CsiManager of receiver: ' + str(e))
            self.ready = False

    def recv(self, conn, len):
        try:
            ready_to_read, ready_to_write, in_error = select.select([conn,], [conn,], [], 1)
        except select.error, e:
            Log.error('Socket error: ' + e.message)
            raise Exception('Socket error')

        if ready_to_read > 0:
            return conn.recv(len)

        return ''

    def runServer(self):
        if not self.ready:
            Log.error('Could not start server because sender and/or receiver are not valid')
            return

        tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tcp.bind(('', self.port))
        tcp.listen(1)
        shutdown = False

        Log.info("CSIManager server started!")
        while True:
            conn, client = tcp.accept()
            Log.debug('Client connected: ' + str(client))

            try:
                while True:
                    command = self.recv(conn, 64)
                    Log.verbose('Command received: ' + command)

                    if command == 'START_SERVER':
                        # Start receiver manager collector
                        self.receiverManager.start()
                    elif command == 'REQUEST_FILES':
                        # Get files ready to be readed
                        files = self.receiverManager.requestFiles()
                        strFiles = ','.join(str(os.path.abspath(x)) for x in files)
                        conn.send(strFiles)
                    elif command == 'SEND_PACKET':
                        secPackets = self.recv(conn, 23)
                        self.senderManager.sendPacket(secPackets)
                    elif command == 'STOP_SENDING':
                        self.senderManager.stopSending()
                    elif command == 'SHUTDOWN':
                        # Shutdown server
                        shutdown = True
                        self.receiverManager.stop()
                        break
                    else:
                        break
            except Exception, e:
                Log.error(e)
                conn.shutdown(2)

            Log.info('Closing client connection...')
            conn.close()

            if shutdown:
                break

        Log.info('Stopping server...')
        tcp.close()
