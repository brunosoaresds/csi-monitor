# CSI Monitor Tool

## What is it?

The CSI Monitor is a tool to configure, collect, monitor and dump, in real-time, the CSI measurements captured from Atheros 802.11n devices which uses the [Xie, et al](http://pdcc.ntu.edu.sg/wands/Atheros/) CSI Extraction tool.

## How it works?

<img src="../../raw/master/docs/images/csi-monitor-architecture.png" width="70%">

## Supported Operational Systems

The csi-device-manager was tested on **Ubuntu 14.04 LTS**. Any other operational system support will be on your own. If you can successfully uses this tool in another distribution, please tell us, that maybe helps another person in our community.

The monitor GUI was tested in **Ubuntu 16.04 LTS** and in **Debian 8**. Because of the linux commands that runs in the python service, its probably that the monitor GUI will only run on linux systems. Feel free to modify the **CsiDMClient** to make it supports other operational systems. Don't forgot to make a Pull Request :).  

## Installing dependencies

### 802.11n devices dependencies (csi-device-manager)

- Installs [Atheros 802.11n CSI Extraction tool [Xie, et al]](http://pdcc.ntu.edu.sg/wands/Atheros/) on both sender and receiver devices. 
- Installs distribution dependencies:

```
$ apt-get update
$ apt-get install gcc cmake linux-headers ntp
```

**NOTE:** You must ensure that ntp was installed and working in all devices, otherwise the data files will be unsynchronized, and the graph plot will fail.

### CSI Monitor GUI dependencies

- Installs MATLAB, version 2017a+
- Installs python 2.7
- Installs SSH client

**NOTE:** The GUI don't requires to be executed in the same device(s) of the 802.11n NIC.

## Installing the tool

### Installing csi-device-manager

You need to install the csi-device-manager in both sender and receiver devices, like you did with Xie Tool. The installation process is very simple:

```
$ cd csi-device-manager
$ make
$ make install
```

- In the installation process you will be asked for what wireless interface (like **wlan0**) is your Atheros 802.11n interface.
- After that you will be asked about the server port that you want to use (default: **3000**).
- The csi-device-manager will be installed in **/opt/csi-device-manager**. If you want to change the wireless interface or the server port, you can change the **interface_id** and **port_id** files inside installation directory.
- The installation will register the csi-device-manager in the upstart, so, when you reboot your device, the csi-device-manager will be started automatically.
- You can manipulate the csi-device-manager service using the command:
```
/etc/init.d/csi-device-manager (start|stop|force-stop|restart|force-restart|status)
```

### Installing/Configuring CSI Monitor GUI

#### Configuring SSH keys

As the GUI copies the CSI files from devices using ssh command, we need to configure the ssh without password access, to do that, we will create SSH keys in the computer that will run the monitor GUI and copy its public key to 802.11n devices **root authorized keys**:

```
$ ssh-keygen -t rsa
$ <Don't enter a passphrase>
$ cat ~/.ssh/id_rsa.pub | ssh root@<sender ip address> 'cat >> .ssh/authorized_keys'
$ cat ~/.ssh/id_rsa.pub | ssh root@<receiver ip address> 'cat >> .ssh/authorized_keys'
```

After this process, test if the ssh without password works, if it works, we are ready to use the monitor GUI :)

#### Configuring/Opening Monitor GUI

This process is very simple, just open the matlab, include csi-monitor-gui folder in the workspace and run **csi_monitor_gui** command.

Assuming that you already have the csi-device-manager running in both sender and receiver and you have an established network between this two devices, you are ready to use the monitor GUI, otherwise proceed to the next session. Enjoy!

### Installing Hostapd and WPA Supplicant

Before run the monitor GUI, we need to establish an infrastructured network between the sender and the receiver. We utilizes the **hostapd** and the **wpa_supplicant** applications.

We provide an examples of hostapd config files used in our experiments, you can up the network AP using the command bellow: 
```
$ hostapd -B scripts/hostapd<5|2.4>.conf
```

**NOTE:** Chooses between the 2.4 and 5 Ghz config files. You can change the network SSID and password by changing the **ssid** and **wpa_passphrase** configurations.

## Monitor GUI parameters

<img src="../../raw/master/docs/images/csi-monitor.png" width="70%">

| Parameter | Description |
| --- | --- |
| Rx Antenna | The receiver antenna CSI measure that will be shown in the graph |
| Tx Antenna | The sender antenna CSI measure that will be shown in the graph |
| Subcarriers | Subcarriers that will be ploted as lines in the graph (multi-selectable) |
| Pkts/sec | Quantity of packets that will be sent from transmitter per second |
| Test time(s) | Time in seconds that the experiment will run, after that sender will stops transmission and the monitor gui will stops ploting |
| Graph window | Window size of the graph (in seconds) |
| CSI sender address | Sender CSI device manager server address in format <ip:port> |
| CSI receiver address | Receiver CSI device manager server address in format <ip:port> |
| Filters | Applies or not some filters in the obtained csi measures before plot |
| Export data [Button] | Exports in the workspace 'csi_data' variable the csi measurements obtained in the test |
| Clear [Button] | Clear test/graph csi measurements |
| Start/Stop [Button] | Starts/Stops the test execution |

## Contribute

Contributions are welcome, the process is simple as cloning, making changes and submitting a pull request.


## Cite this tool

This tool was developed inside a master degree work named **Sensing Human Movement Activities using IEEE 802.11n Interfaces**. To cite us, please refer the CCECE 2018 paper named "WiDMove: Sensing Movement Direction using IEEE 802.11n Interfaces".

To understand better this work and get our dataset, please visit [https://brunosoaresds.github.io/widmove/](https://brunosoaresds.github.io/widmove/).

### BibTeX

```
@inproceedings{dasilva2018widmove,
  title={WiDMove: Sensing Movement Direction Using IEEE 802.11 n Interfaces},
  author={Silva, Bruno Soaresda and TeodoroLaureano, Gustavo and Abdallah, Abdallah S and VieiraCardoso, Kleber},
  booktitle={2018 IEEE Canadian Conference on Electrical \& Computer Engineering (CCECE)},
  pages={1--4},
  year={2018},
  organization={IEEE}
}
```
