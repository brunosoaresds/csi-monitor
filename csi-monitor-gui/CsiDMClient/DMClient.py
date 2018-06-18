import socket

from FilesManager import *
from Log import *


class DMClient(Thread):
    ##
    # Constructor method.
    #
    def __init__(self, host, port, type):
        Thread.__init__(self)
        self.daemon = False
        self.shutdown = False

        self.host = host
        self.port = int(port)
        self.type = type
        self.socket = None
        self.filesManager = FilesManager(10)

        self.connect()

    def run(self):
        if self.type == 'receiver':
            self.filesManager.start()
            self.collectCsiData()

    def stop(self):
        Log.info("Shuwdown received...")
        self.shutdown = True
        self.socket.close()

    def connect(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))

    def reconnect(self):
        while True:
            try:
                Log.info("Reconnecting to " + self.type)
                self.connect()
                break
            except Exception, e:
                Log.info("Could not reconnect to " + self.type + ". Waiting 5 seconds to try again...")
                time.sleep(5)

        Log.info("Connection with " + self.type + " reestablished")

    def requestFiles(self):
        return self.filesManager.requestFiles()

    def collectCsiData(self):
        if self.type != 'receiver':
            Log.error("Could not collect csi data from " + self.type)
            return

        Log.info("collection initialized")
        while not self.shutdown:
            startTime = time.time()
            try:
                self.socket.send('GET_FILES')
                filesBin = self.socket.recv(1024 * 60)
                files = filesBin.split('/outputs/')
                absolutePath = files[0]
                files = [s.split(absolutePath)[0] for s in files]
                files = files[1:]

                zeroAppended = False
                if len(files) == 1:
                    files.append('0')
                    zeroAppended = True

                absolutePath += '/outputs/'

                if len(files) > 1:
                    scpCommand = 'scp root@' + self.host + ':' + absolutePath + '\{' + ','.join(files) + \
                                 '\} ' + self.filesManager.filesDir + ' > /dev/null 2>&1'
                    os.system(scpCommand)

                    if zeroAppended:
                        files.remove('0')
                    self.filesManager.addFiles(files)
            except Exception, e:
                Log.error("An error occurred while reading CSI packet data: " + e.message)
                self.reconnect()

            elapsedTime = time.time() - startTime
            if elapsedTime < 1:
                time.sleep(1 - elapsedTime)
            else:
                time.sleep(0.2)

        Log.info('finished collection...')

    def sendPacket(self, secPackets):
        if self.type == 'sender':
            try:
                # Signalize to server that client want's to send some quantity of packets
                self.socket.send('SEND_PACKET')
                self.socket.send('7c:c3:a1:b4:03:df')
                self.socket.send(secPackets)
            except Exception, e:
                Log.error("Could not signalize to sender the packet transmission: " + e.message)
                self.reconnect()
                self.sendPacket(secPackets)

    def stopSending(self):
        if self.type == 'sender':
            try:
                # Signalize to server that client want's to stop sending
                self.socket.send('STOP_SENDING')
            except Exception, e:
                Log.error("Could not signalize to sender the packet send stop: " + e.message)
                self.reconnect()
                self.stopSending()
