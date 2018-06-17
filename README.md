# CSI Monitor Tool

## What is it?

The CSI Monitor is a tool to configure, collect, monitor and dump, in real-time, the CSI measurements captured from Atheros 802.11n devices which uses the [Xie, et al](http://pdcc.ntu.edu.sg/wands/Atheros/) CSI Extraction tool.

<img src="raw/master/docs/images/csi-monitor.png" width="70%">

## Installation guide

### 1. Supported Operational Systems

This tool was tested on **Ubuntu 14.04 LTS**, any other operational system support will be on your own. If you can succesfully used thi tool in another distribution, please tell us, that maybe helps another person in our community. 

### 2. Installing dependencies

#### 2.1. 802.11n devices dependencies (csi-device-manager)

- Installs [Atheros 802.11n CSI Extraction tool [Xie, et al]](http://pdcc.ntu.edu.sg/wands/Atheros/) on both sender and receiver devices. 
- Installs distribution dependencies:

```
$ apt-get update
$ apt-get install gcc cmake linux-headers ntp
```

You must ensure that ntp was installed and working in all devices, otherwise the data files will be unsynchronized, and the graph plot will fail.

#### 2.2. CSI Monitor GUI dependencies

- Installs MATLAB, version 2017a+
- Installs python 2.7

**NOTE:** The GUI don't requires to be executed in the same device(s) of the 802.11n NIC.

### 3. Installing the tool

#### 3.1 Installing csi-device-manager

You need to install the csi-device-manager in both sender and receiver devices, like you did with Xie Tool. The instalation proccess is very simple:

```
$ cd csi-device-manager
$ make
$ make install
```

- In the installation proccess you will be asked for what wireless interface (like **wlan0**) is your Atheros 802.11n interface.
- After that you will asked about the socket port that you want to use (default: **3000**).
- The csi-device-manager will be installed in **/opt/csi-device-manager**. If you want to change the wireless interface or the socket port, you can change the **interface_id** and and **port_id** files inside installation directory.
- The installation will register the csi-device-manager in the upstart, so, when you reboot your device, the csi-device-manager will be started automatically.
- You can start/stop the csi-device-manager using the command:
```
/etc/init.d/csi-device-manager (start|stop|force-stop|restart|force-restart|status)
```

#### 3.2 Installing CSI Monitor GUI

#### 3.3 Installing Hostapd and WPA Supplicant

### 4. How it works?

<img src="raw/master/docs/images/csi-monitor-architecture.png" width="70%">

## 5. Contribute

Contributions are welcome, the proccess is simple as cloning, making changes and submitting a pull request.


## 6. Cite this tool

This tool was developed inside a master degree work named **WiDMove: Sensing Movement Direction using IEEE 802.11n Interfaces**.

### BibTex

Under creation...
