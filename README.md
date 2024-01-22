# AAPS Glucose Applications

## Develop (Unix only)

### Setup

- Download [ConnectIQ SDK](https://developer.garmin.com/connect-iq/overview/) and add bin directory to your PATH.
  For that you can put the following to your .bashrc or the like:
  ```
     CONNECT_IQ_BASE="<installation-dir>"
     CONNECT_IQ=`cat "$CONNECT_IQ_BASE/current-sdk.cfg"`
     PATH="$PATH:$CONNECT_IQ/bin"
  ```
  For example, on MacOS yo say: `CONNECT_IQ_BASE="$HOME/Library/Application Support/Garmin/ConnectIQ/"`

- Make sure you have [xmlstarlet](https://xmlstar.sourceforge.net/) installed.

- Generate a private developer key (4096 RSA), for example [here](https://cryptotools.net/rsagen) and put
  it to `$HOME/StudioProjects/developer_key`. Or run
  ```openssl genrsa -out $HOME/StudioProjects/developer_key```
  You can also put the file somewhere else and point DEVELOPER_KEY to the location.

### Build and run Simulator

- Start the Android virtual device on AndroidStudio and run AAPS in simulator or connect your phone via
  AndroidStudio debugging.
  In AAPS -> Config Builder enable "Garmin". If you're using the simulator, also enable "Random BG" as BG source. 

- Run `./adb-forward.sh`
  (if you have multiple devices, e.g. simulator and phone, you need to specify to which you want to connect.
  Run `adb devices` to get the device id and then `./adb-forward -s <deviceid>`)

- Run `make GlucoseWatchFace/run`

- To run on a different device, set the _device_ environment variable: `export device=fenix6` or do
  
  ```device=fenix6 make GlucoseWatchFace/run```

- If you don't get values, make sure Settings -> Use device HTTPS requirements is off. Then execute
  Simulation -> Background Events -> Temporal Event. You can always force the app the retrieve new values
  with this command.

### Run Unit Tests

- Run `make test` to run unit tests.


## Test on your Device

To test on your device, you need to build the .prg file. For example to build the watch face for fenix6:

```
    device=fenix6 make bin-fenix6/GlucoseWatchFace.prg
```

Then copy the file to the Garmin/GARMIN/APPS directory on the device. To access the file system on watches,
you probably need to install the [Android File Transfer](https://www.android.com/filetransfer/) tool. 
Also create an empty file Garmin/GARMIN/APPS/logs/GlucoseWatchFace.log to get log output.
