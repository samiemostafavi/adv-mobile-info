# adv-mobile-info

Build the project for the Advantech routers (arm64)
```
./build.sh min linux-arm64
git add .
git commit -m "update"
git push
```

Move the binary to the device and run it.
```
curl -LJO -k https://github.com/samiemostafavi/advmobileinfo/raw/main/ami
chmod +x ami
mv ami /usr/bin/
```

Add the following to the scripts tab of the router
```
ami > /root/ami.log 2>&1 &
```

To change the modem configurations such as the default simcard, on a machine connected via network to the Adv router, run
```
curl -LJO -k https://github.com/samiemostafavi/advmobileinfo/raw/main/config_adv.sh
chmod +x config_adv.sh
vim config_adv.sh
./config_adv.sh
```
NOTE: edit the script with the IP of the adv router and its login password, and your desired configurations

To see a complete system status including the IPs and sim card selected use `get_conf_adv.sh` script
```
curl -LJO -k https://github.com/samiemostafavi/advmobileinfo/raw/main/get_conf_adv.sh
chmod +x get_conf_adv.sh
vim get_conf_adv.sh
./get_conf_adv.sh

```
This will give:
```
Login successful
Get config successful
{
  "Mobile Connection": {
    "SIM Card": "2nd",
    "IP Address": "Unassigned",
    "IPv6 Address": "Unassigned",
    "State": "Preparing"
  },
  "Primary LAN": {
    "IP Address": "10.10.5.8 / 255.255.0.0",
    "IPv6 Address": "Unassigned",
    "MAC Address": "00:0A:14:8E:9A:77",
    "Rx Data": "26.7 MB",
    "Tx Data": "6.1 MB"
  },
  "Secondary LAN": {
    "IP Address": "Unassigned",
    "IPv6 Address": "Unassigned",
    "MAC Address": "00:0A:14:8E:9A:78"
  },
  "Tertiary LAN": {
    "IP Address": "10.42.3.1 / 255.255.255.0",
    "IPv6 Address": "Unassigned",
    "MAC Address": "00:0A:14:8E:9A:79",
    "Rx Data": "196.9 MB",
    "Tx Data": "277.0 MB"
  },
  "Peripheral Ports": {
    "Expansion Port 1": "RS-232",
    "Expansion Port 2": "RS-485",
    "Binary Input 0": "Off",
    "Binary Input 1": "Off",
    "Binary Output 0": "Off",
    "Binary Output 1": "Off"
  },
  "System Information": {
    "Firmware Version": "6.2.9 (2021-04-07)",
    "Serial Number": "ACZ1100002516992",
    "Hardware UUID": "cdc8b8b4-ae58-11ec-88f7-000a148e9a77",
    "Profile": "Standard",
    "Supply Voltage": "12.1 V",
    "Temperature": "33 �C",
    "Time": "2024-07-15 13:15:48",
    "Uptime": "4 days, 2 hours, 30 minutes"
  }
}
```

# Commands

You can run the following commands on a machine connected via network to the Adv router.

Get connection information
```
curl "http://10.10.5.7:50500/?query=info"

{"Band":"n78","CSQ":"20","Cell":"7538000","Channel":"650688","Operator":"999 08","PLMN":"99908","RSRP":"-72 dBm","RSRQ":"-11 dB","Registration":"Home Network","Signal Quality":"-11 dB","Signal Strength":"-72 dBm","TAC":"0BC2","Technology":"NR5G"}
```

Turn off the modem
```
curl "http://10.10.5.7:50500/?gsmpwr=0"
```

Turn on the modem
```
curl "http://10.10.5.7:50500/?gsmpwr=1"
```

Check IMSI of the simcard
```
curl "http://10.10.5.7:50500/?query=imsi"

001010000000005
OK
```


Check the bands that the modem can connect to (is capable of connecting to)
```
curl "http://10.10.5.7:50500/?query=policybands"

+QNWPREFCFG: "gw_band",1:2:3:4:5:6:8:9:19
+QNWPREFCFG: "lte_band",1:2:3:4:5:7:8:12:13:14:17:18:19:20:25:26:28:29:30:32:34:38:39:40:41:42:43:46:48:66:71
+QNWPREFCFG: "nsa_nr5g_band",1:2:3:5:7:8:12:14:20:25:28:38:40:41:48:66:71:77:78:79
+QNWPREFCFG: "nr5g_band",1:2:3:5:7:8:12:14:20:25:28:38:40:41:48:66:71:77:78:79
OK
```

Check the bands that the modem is configured to search and connect on each network
The `net` parameter can only be "gw_band", "lte_band", "nsa_nr5g_band", or "nr5g_band".
```
curl "http://10.10.5.7:50500/?query=bands&net=nr5g_band"

+QNWPREFCFG: "nr5g_band",41:78
OK
```

Set the bands for the modem, where the `selectband` parameter can only be "gw_band", "lte_band", "nsa_nr5g_band", or "nr5g_band".
The bands parameters must be colon separated numbers.
```
curl "http://10.10.5.7:50500/?selectband=nr5g_band&bands=1:2:3:5:7:8:12:14:20:25:28:38:41:48:66:71:77:78:79"

OK
```

