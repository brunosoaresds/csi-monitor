#!/usr/bin/env python
import getopt
import sys
import glob
import os

from Server import Server


def usage():
    print("/*************************************/")
    print("/*  CSI Device Manager Client usage: */")
    print("/*************************************/")
    print("$ Main.py --port=<server_port> --sender=<sender CsiDM> --receiver=<receiver CsiDM>")
    print("/*************************************/")
    print("/*******      Parameters:     ********/")
    print("/*************************************/")
    print("- <port>: The server socket port which the device manager client will uses.")
    print("- <sender>: The sender CSI Device Manager address, ip_address:port pattern (Ex: 192.168.0.1:3000)")
    print("- <receiver>: The receiver CSI Device Manager address, ip_address:port pattern (Ex: 192.168.0.2:3000)")
    print("/*************************************/")


def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], [], ["port=", "sender=", "receiver="])
    except getopt.GetoptError as err:
        # print help information and exit:
        usage()
        print str(err)
        sys.exit(2)

    port = None
    sender = None
    receiver = None

    for o, a in opts:
        if o == "--port":
            port = int(a)
        elif o == "--sender":
            sender = a
        elif o == "--receiver":
            receiver = a
        else:
            assert False, "unhandled option"

    if port is None or sender is None or receiver is None:
        usage()
        sys.exit(2)

    # Clear output_data folder
    filesDir = os.path.dirname(os.path.abspath(__file__)) + '/output_data'
    files = glob.glob(filesDir + '/*')
    for file in files:
        os.remove(file)

    server = Server(port, sender, receiver)
    server.runServer()


if __name__ == "__main__":
    main()
