library smartscan.settings.selectDevice;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/mainBanner.dart';
import '../dataModels/scanModel.dart';
import '../main.dart';
import '../resultPanel.dart';
import '../strings.dart' as strings;

const String PRIMARY_SERVICE = "00001000-0000-1000-8000-00805f9b34fb";



class selectDevice extends StatefulWidget {
  const selectDevice({Key? key}) : super(key: key);

  @override
  State<selectDevice> createState() => _selectDeviceState();
}
void connectToDeviceViaAddress(String deviceAddress){
  FlutterBluePlus.instance.scan(timeout: const Duration(seconds: 5)).listen((scanResult) {
    // Check if the device found matches the address we want to connect to
    if (scanResult.device.id.id == deviceAddress) {
      // Stop scanning for devices
      FlutterBluePlus.instance.stopScan();

      // Connect to the device
      scanResult.device.connect().then((value) {
        return;
      });
    }
  });

}

class _selectDeviceState extends State<selectDevice> {
  List<ScanModel> scannedDevices = [];
  BluetoothManager manager = BluetoothManager();

  void sortScannedDevices(){
    List<ScanModel> newList = [];
    for (ScanModel model in scannedDevices){
      if(model.getName() != "unknown" && model.getName() != ""){
        newList.add(model);
      }
    }
    for (ScanModel model in scannedDevices){
      if(model.getName() == "unknown" || model.getName() == ""){
        newList.add(model);
      }
    }

    scannedDevices = newList;
  }

  void scanBluetooth(){
    setState(() {
      scannedDevices = [];
    });
    FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 4), allowDuplicates: false
          , withServices: [Guid(PRIMARY_SERVICE)]
    );
    manager.setDeviceListener((p0) {
      print(p0.name);
    });
    //manager.startScan();


// Listen to scan results
    var subscription = FlutterBluePlus.instance.scanResults.listen((results) {
      // do something with scan results
      for (ScanResult r in results) {


        setState(() {
          scannedDevices.add(ScanModel(r.device.id.id, r.device.name, r.rssi.toString()));
          sortScannedDevices();
        });
      }
    });



// Stop scanning
    FlutterBluePlus.instance.stopScan();
  }
  @override
  void initState(){
    super.initState();
    scanBluetooth();

  }

  BannerAd? banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();


    final adstate = AdBanner.instance;
    adstate?.initialization.then((value) {
      setState(() {
        banner = BannerAd(size: AdSize.banner,
            adUnitId: adstate.bannerAdUnitId,
            request: const AdRequest(),
            listener: adstate.adListener)..load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: popMyAppBar(context),
      backgroundColor: const Color.fromARGB(255,37,46,61),
      body: Column(
        children: [
          Flexible(
            flex: 11,
            child: RefreshIndicator(
              onRefresh: () {
                scanBluetooth();
                return Future.delayed(const Duration(seconds: 2));
              },
              child: ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  String name = scannedDevices[index].getName();
                  if(name == ""){
                    name = "unknown";
                  }
                  String address = scannedDevices[index].getAddress();
                  String rssi = scannedDevices[index].getRssi();
                  return ListTile(
                    tileColor: const Color.fromARGB(255,37,46,61),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    leading: Column(

                      children: [
                        SizedBox(
                          width: ScreenUtil().setWidth(125.0),
                          height: ScreenUtil().setHeight(3),
                        ),
                        SizedBox(
                          width: ScreenUtil().setWidth(125.0),
                          height: ScreenUtil().setHeight(40),

                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255 ,14,22,33),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () {
                              connectToDeviceViaAddress(scannedDevices[index].getAddress());
                              FlutterBluePlus.instance.connectedDevices.then((value) {
                                try{
                                  var test = value[0].id.id == scannedDevices[index].getAddress();
                                  if(test){
                                    writeToFile("bluetoothDevice.txt", "${scannedDevices[index].getName()}\n${scannedDevices[index].getAddress()}");
                                    Fluttertoast.showToast(msg: "Your device is connected");
                                    Navigator.pop(context);
                                  }
                                }catch(e){
                                  Fluttertoast.showToast(msg: "Can't connect to this device");
                                }
                              });
                            },
                            icon: const Icon(Icons.bluetooth),
                            label: Text('Connect', style: TextStyle(fontSize: ScreenUtil().setSp(15)), maxLines: 1, textScaleFactor: 1.25),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: ScreenUtil().setSp(25), color: Colors.white)
                        , textScaleFactor: 1.25
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Device Address: $address', style: TextStyle(fontSize: ScreenUtil().setSp(15.0), color: Colors.white), textScaleFactor: 1.25),
                        Text('RSSI: $rssi', style: TextStyle(fontSize: ScreenUtil().setSp(15.0), color: Colors.white), textScaleFactor: 1.25),
                      ],
                    ),
                  );

                },
                itemCount: scannedDevices.length,

              ),
            ),
          ),
          if(banner != null && strings.Ad)
            Flexible(flex: 1,child: AdWidget(ad: banner!,))
          else
            Container()
        ],
      ),
    );
  }
}


