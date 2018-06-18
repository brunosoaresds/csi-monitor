import os
import logging
import inspect

logFile = os.path.join(os.path.dirname(__file__)) + '/log.log'
levelOfLog = 'DEBUG'

##
# Log Class provides a unique way to record log messages of this program.
#
class Log():
    logger = None

    ##
    # Creates a new instance of Log class.
    # @param streamType - String containing the stream type name.
    # @param logLevel - String containing the name of the level to be used in the log.
    #
    @classmethod
    def instantiate(cls, streamType="FILE", logLevel="INFO"):
        try:
            logging.VERBOSE = 5
            logging.addLevelName(logging.VERBOSE, "VERBOSE")
            logging.Logger.verbose = lambda inst, msg, *args, **kwargs: inst.log(logging.VERBOSE, msg, *args, **kwargs)
            logging.verbose = lambda msg, *args, **kwargs: logging.log(logging.VERBOSE, msg, *args, **kwargs)

            cls.logger = logging.getLogger()

            if logLevel not in logging._levelNames:
                raise Exception('Invalid file level')

            cls.logger.setLevel(logging._levelNames[logLevel])

            if streamType == "SCREEN":
                stream = logging.StreamHandler()
            else:
                stream = logging.FileHandler(logFile)

            formatter = logging.Formatter('[%(levelname)-7s - %(asctime)s] %(message)s')
            stream.setFormatter(formatter)
            cls.logger.addHandler(stream)
        except Exception, e:
            print('Unable to get/set log configurations. Error: %s' % (e))
            cls.logger = None

    ##
    # Records a message in a file and/or displays it in the screen.
    # @param level - String containing the name of the log message.
    # @param message - String containing the message to be recorded.
    #
    @classmethod
    def log(cls, level, message, caller=None):
        if not cls.logger:
            cls.instantiate(logLevel=levelOfLog)

        try:
            if level not in logging._levelNames:
                cls.log("ERROR", 'Invalid file level \'%s\'' % (level))

            logLevel = logging._levelNames[level]
            if not caller:
                callers = Log.getCallers(inspect.stack())
            else:
                callers = caller
            message = '%s.%s - %s' % (callers[0], callers[1], message)

            cls.logger.log(logLevel, message)
        except Exception, e:
            print 'Unable to record the log. Error: %s' % (e)

    @classmethod
    def info(cls, message):
        cls.log("INFO", message, Log.getCallers(inspect.stack()))

    @classmethod
    def error(cls, message):
        cls.log("ERROR", message, Log.getCallers(inspect.stack()))

    @classmethod
    def warn(cls, message):
        cls.log("WARN", message, Log.getCallers(inspect.stack()))

    @classmethod
    def debug(cls, message):
        cls.log("DEBUG", message, Log.getCallers(inspect.stack()))

    @classmethod
    def verbose(cls, message):
        cls.log("VERBOSE", message, Log.getCallers(inspect.stack()))

    ##
    # Gets the data about the caller of the log method.
    # @param stack Array containing the system calling stack.
    # @return Array containing the caller class name and the caller method, respectively.
    #
    @staticmethod
    def getCallers(stack):
        caller_class = None
        caller_method = None
        if stack:
            if len(stack) > 1:
                if stack[1][3] == '<module>':
                    caller_method = stack[1][0].f_locals.get('__name__')
                    caller_class = ((str(stack[1][0].f_locals.get('__file__'))).split('/')[-1]).split('.')[0]
                else:
                    caller_method = stack[1][3]
                    if 'self' in stack[1][0].f_locals:
                        caller_class = stack[1][0].f_locals.get('self').__class__.__name__
                    elif 'cls' in stack[1][0].f_locals:
                        caller_class = stack[1][0].f_locals.get('cls').__name__
                    else:
                        caller_class = 'NoneType'
        return (caller_class, caller_method)
