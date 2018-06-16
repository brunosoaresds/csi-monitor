SRC_DIR = ./src
BUILD_DIR = ./build
BIN_PATH = $(BUILD_DIR)/csi_device_manager
DAEMON_FILE_PATH = ./init/csi-device-manager.daemon

INSTALLATION_DIR = /opt/csi-device-manager
INSTALLATION_BIN_PATH = $(INSTALLATION_DIR)/csi_device_manager
INTERFACE_ID_FILE = $(INSTALLATION_DIR)/interface_id
PORT_ID_FILE = $(INSTALLATION_DIR)/port_id
INIT_FILE_PATH = /etc/init.d/csi-device-manager
INSTALLATION_OUTPUT_FILES_DIR = $(INSTALLATION_DIR)/outputs

OBJS = $(BUILD_DIR)/csi_fun.o $(BUILD_DIR)/socket.o $(BUILD_DIR)/sender.o $(BUILD_DIR)/csi_collector.o $(BUILD_DIR)/main.o
CC = gcc -pthread

csi_device_manager: $(OBJS)
    if [ ! -d "$(BUILD_DIR)" ]; then \
        mkdir $(BUILD_DIR); \
    fi
	$(CC) $(OBJS) -o $(BIN_PATH)
csi_fun.o: $(SRC_DIR)/csi_fun.c $(SRC_DIR)/csi_fun.h
	$(CC) -c $(SRC_DIR)/csi_fun.c -o $(BUILD_DIR)/csi_fun.o
socket.o: $(SRC_DIR)/socket.c $(SRC_DIR)/socket.h
	$(CC) -c $(SRC_DIR)/socket.c -o $(BUILD_DIR)/socket.o
sender.o: $(SRC_DIR)/sender.c $(SRC_DIR)/sender.h
	$(CC) -c $(SRC_DIR)/sender.c -o $(BUILD_DIR)/sender.o
csi_collector.o: $(SRC_DIR)/csi_collector.c $(SRC_DIR)/csi_collector.h
	$(CC) -c $(SRC_DIR)/csi_collector.c -o $(BUILD_DIR)/csi_collector.o
main.o: $(SRC_DIR)/main.c $(SRC_DIR)/csi_fun.h $(SRC_DIR)/socket.h $(SRC_DIR)/sender.h $(SRC_DIR)/csi_collector.h
	$(CC) -c $(SRC_DIR)/main.c -o $(BUILD_DIR)/main.o

clean:
	rm -f $(BUILD_DIR)/*.o $(OUTPUT_BIN)
	if [ -d "$(BUILD_DIR)" ]; then \
        rm -r $(BUILD_DIR); \
    fi

install:
    if [ ! -d "$(BUILD_DIR)" ] || [ ! -f "$(BIN_PATH)"] ; then \
        echo "Project not builded yet."; \
    else \
        if [ -d "$(INSTALLATION_DIR)" ]; then \
            rm -r $(INSTALLATION_DIR); \
        fi \

        mkdir $(INSTALLATION_DIR); \
        cp $(BIN_PATH) $(INSTALLATION_BIN_PATH); \
        cp $(DAEMON_FILE_PATH) $(INIT_FILE_PATH); \
        @read -p "Enter WLAN interface that the CSI Device manager will manage:" interface_in; \
        echo "$$interface_in" > $(INTERFACE_ID_FILE); \
        @read -p "Enter the socket port to be used (Default/Enter: 3000):" port_in; \
        echo "$$port_in" > $(PORT_ID_FILE); \
        mkdir $(INSTALLATION_OUTPUT_FILES_DIR); \
        chmod a+x $(INIT_FILE_PATH); \
        update-rc.d csi-device-manager defaults; \
        echo "Installation done :)! if you need to change socket port or WLAN interface, please change '$(PORT_ID_FILE)' and '$(INTERFACE_ID_FILE)' files."; \
        echo "You can start the service running $(INIT_FILE_PATH) start"; \

    fi