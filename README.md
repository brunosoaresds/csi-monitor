# csi-monitor

The CSI Monitor is a tool to configure, collect, monitor and dump in real-time the CSI measurements from Atheros 802.11n devices wich uses the [Xie, et al](http://pdcc.ntu.edu.sg/wands/Atheros/) CSI Extraction tool.

<img src="https://github.com/brunosoaresds/csi-monitor/raw/master/docs/images/csi-monitor.png" width="70%">

## Installation guide

### 1. Supported Operational Systems

This tool was tested on **Ubuntu 14.04 LTS**, any other operational system support will be on your own. If you can succesfully used thi tool in another distribution, please tell us, that maybe helps another person in our community. 

### 2. Installing dependencies

- Installs [Atheros 802.11n CSI Extraction tool [Xie, et al]](http://pdcc.ntu.edu.sg/wands/Atheros/) on both sender and receiver devices. 
- Installs distribution dependencies:
```
$ apt-get update
$ apt-get install gcc cmake linux-headers python2.7 ntp
```
ntp -> the devices muste be sinchronized, otherwhise the data files will be a past or future files, and the plot of the graph will fails

### 3. Installing the tool

<img src="https://github.com/brunosoaresds/csi-monitor/raw/master/docs/images/csi-monitor-architecture.png" width="70%">

/bin/sleep 10
/root/createHostapd.sh
/bin/sleep 120
/usr/bin/screen -dmS csi_monitor /root/csi-monitor/ap-manager/recv_csi 3000 wlan0

- This
