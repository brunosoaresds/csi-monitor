import time
from threading import Thread

from Log import *


class FilesManager(Thread):
    ##
    # Constructor method.
    #
    def __init__(self, removalWindow):
        Thread.__init__(self)
        self.daemon = False

        self.filesDir = os.path.dirname(os.path.abspath(__file__)) + '/output_data/'
        self.removalWindow = removalWindow
        self.files = []

        # Creates output_data directory if not exists
        try:
            if not os.path.exists(self.filesDir):
                os.makedirs(self.filesDir)
        except Exception, e:
            Log.error('Could not create output_data directory: ' + e.message)

    def run(self):
        while True:
            lastWindowTime = int(time.time() - self.removalWindow)
            fileName = self.filesDir + str(lastWindowTime)

            try:
                try:
                    self.files.remove(fileName)
                except Exception, e1:
                    pass
                os.remove(fileName)
            except Exception, e:
                pass

            time.sleep(1)

    def addFiles(self, files):
        files = [self.filesDir + s for s in files]
        self.files = self.files + files

    def requestFiles(self):
        requestedFiles = self.files
        self.files = []
        return requestedFiles

