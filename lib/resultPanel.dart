import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smartscan/settings/customizeDataset.dart';
import 'package:smartscan/strings.dart';
import 'package:hex/hex.dart';

import 'ads/mainBanner.dart';
import 'dataModels/presetModel.dart';
import 'main.dart';
import 'misc/rfidHelpers/DisDataParseManage.dart';
import 'strings.dart' as strings;


String getDayOfTheWeek(){
  String mode = readFile("mode.txt");
  int dayInt = DateTime.now().weekday;
  int hour = DateTime.now().hour;
  if(dayInt == 7){
    dayInt = 0;
  }
  if(hour > 10){
    dayInt += 1;
    if(dayInt == 7){
      dayInt = 0;
    }
  }
  List<String> days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
  getDataset(mode, days[dayInt]).isEmpty? dayInt = dayInt+1: 0;
  if(dayInt == 7){
    dayInt = 0;
  }
  return days[dayInt];
}
class result extends StatefulWidget {
  const result({Key? key}) : super(key: key);

  @override
  State<result> createState() => _resultState();
}
List<bool> scan(List<String> need, List<String> scanned) {
  List<bool> whatGot = List.filled(need.length, false);
  for (int i = 0; i < need.length; i++) {
    for (int j = 0; j < scanned.length; j++) {
      if (need[i] == scanned[j]) {
        whatGot[i] = true;
        break;
      }
    }
  }
  return whatGot;
}


class _resultState extends State<result> {
  String notReadyText = "Not ready";
  String readyText = "Ready";
  Color notReadyColor = Colors.red;
  Color readyColor = Colors.green;
  bool ready = false;
  double readySize = 20;
  List<DatasetModel> datasetModels = [];
  List<DatasetMiniModel> miniModels = [];
  List<bool> activated = [];
  List<String> idsScanned = [];
  String today = getDayOfTheWeek();
  BluetoothManager? _bluetoothManager;

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return const Color.fromARGB(255, 255, 171, 64);
    }
    return const Color.fromARGB(255, 255, 171, 64);
  }
  Color getColorNot(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return const Color.fromARGB(255, 213, 0, 0);
    }
    return const Color.fromARGB(255, 213, 0, 0);
  }
  Color getColorNotReq(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.deepPurple;
    }
    return Colors.deepPurple;
  }
  Color Function(Set<MaterialState>) getColorAll(bool enabled, bool req){
    if(enabled){
      return getColor;
    }else if(req){
      return getColorNotReq;
    }else {
      return getColorNot;
    }
  }

  setDatasetModels(){
    setState(() {
      ready = false;
    });
    String mode = readFile("mode.txt");
    miniModels = [];
    idsScanned = [];
    setState(() {
      datasetModels = getDataset(mode, today);
      for(DatasetModel model in datasetModels){
        miniModels.addAll(model.getMiniModels());
      }
      activated = List.generate(miniModels.length, (index) => false);
    });

  }
  void setUpOverFlow(){
    String mode = readFile("mode.txt");
    List<DatasetModel> allPresets = getPresetsMap(mode);
    List<DatasetMiniModel> allPresetsMini = [];
    for(DatasetModel miniPreset in allPresets){
      allPresetsMini.addAll(miniPreset.getMiniModels());
    }
    miniModels;
    idsScanned;
    for (String id in idsScanned){
      DatasetMiniModel? idMiniModel;
      bool isInModelsDataset = false;
      for (DatasetMiniModel miniModelPresets in miniModels){
        if(id == miniModelPresets.getId().replaceAll(" ", "")){
          isInModelsDataset = true;

        }
      }
      bool isInModels = false;
      for (DatasetMiniModel miniModelPresets in allPresetsMini){
        if(id == miniModelPresets.getId().replaceAll(" ", "")){
          isInModels = true;
          idMiniModel = miniModelPresets;
        }
      }
      if(isInModels && !isInModelsDataset && idMiniModel != null){
        setState(() {
          idMiniModel?.notReq = true;
          miniModels.add(idMiniModel!);
        });
      }
    }
  }

  @override
  void initState() {
    _bluetoothManager = BluetoothManager();
    super.initState();
    setDatasetModels();
    setState(() {
      if(!activated.contains(false)){
        ready = true;
      }
    });
    _bluetoothManager?.setListener((String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) {
      if(data.isEmpty){
        return;
      }
      List<String> ids = [];
      if(!idsScanned.contains(data)){
        idsScanned.add(data);
        setUpOverFlow();
        for (var element in miniModels) {ids.add(element.id.replaceAll(" ", ""));}
        setState(() {
          activated = scan(ids, idsScanned);
          if(!activated.contains(false)){
            ready = true;
          }
        });
      }

      //print(HEX.encode(data));
    });
    _bluetoothManager?.registerOnCharacteristicChanged();
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
      body: Column(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: ElevatedButton(onPressed: () {
                  setDatasetModels();
                }, style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(secondaryColors),
                ), child: const Text("Reset Scan")
                ),
              ),
              Container(margin: const EdgeInsets.all(10),child: Text(ready?readyText:notReadyText, style: TextStyle(color: ready?readyColor:notReadyColor, fontSize: readySize),))
              ,
              if (!ready)
                Expanded(child: Image.asset("lib/drawable/readyStats/dislike.png", width: ScreenUtil().setWidth(70), height: ScreenUtil().setHeight(70),))
              else
                Expanded(child: Image.asset("lib/drawable/readyStats/smile.png", width: ScreenUtil().setWidth(100), height: ScreenUtil().setHeight(100),))
            ],
          ),
          Expanded(
            flex: 10  ,
              child:
          ListView.builder(itemCount: miniModels.length,
            itemBuilder: (context, index) {
            return Card(
              color: const Color.fromARGB(255 ,14,22,33),
              margin: const EdgeInsets.all(10),

              child: Row(
                children: [
                  Checkbox(value: activated[index], onChanged: (_) {}, fillColor: MaterialStateProperty.resolveWith(getColorAll(activated[index], miniModels[index].notReq)), ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      miniModels[index].getNameOfQuick(),
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.orangeAccent[200],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          )
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

class BluetoothManager extends DisDataParseManage{
  late DisDataParseManage manage;
  Function(DiscoveredDevice)? listenerDevice;
  BluetoothManager(){
    super.leProxy = this;
    manage = super.getMe();
  }
// Define the service and characteristic UUIDs
  static List<String> allIds = [];
  String latestRead = "";
  DateTime lastReadTime = DateTime(2000);
  final List<int> ENABLE_NOTIFICATION_VALUE = [0x01, 0x00];
  final List<int> DISABLE_NOTIFICATION_VALUE = [0x00, 0x00];
  final String serviceUuid = "00001000-0000-1000-8000-00805f9b34fb";
  final List<String> characteristicUuids = [
    "00001001-0000-1000-8000-00805f9b34fb",
    "00001002-0000-1000-8000-00805f9b34fb",
    "00001003-0000-1000-8000-00805f9b34fb",
    "00001004-0000-1000-8000-00805f9b34fb",
    "00001005-0000-1000-8000-00805f9b34fb",
  ];
  final String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";
  static int index = 0;
  Function callBack = (String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) {};
  final idsLimit = 20;

  void setListener(Function(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) callBack ){
    this.callBack = callBack;
  }

  void setDeviceListener(Function(DiscoveredDevice) listener){
    listenerDevice = listener;
  }

// Method to send data to a device
  Future<bool> send(List<int> data, bool withResponse) async {
    // Get the BluetoothDevice object for the device with the given ID
    if((await FlutterBluePlus.instance.connectedDevices).isEmpty){
      return false;
    }
    BluetoothDevice device = (await FlutterBluePlus.instance.connectedDevices)[0];


    // Discover the services and characteristics of the device
    List<BluetoothService> services = await device.discoverServices();
    BluetoothService service = services.firstWhere((element) => element.uuid.toString().contains(serviceUuid));
    BluetoothCharacteristic characteristic = service
        .characteristics.firstWhere(
            (c) => characteristicUuids.contains(characteristicUuids[0]));

    // if (characteristic == null) {
    //   // The characteristic was not found
    //   return false;
    // }

    // Write the data to the characteristic
    await characteristic.write(data, withoutResponse: !withResponse);

    return true;
  }
  Future<bool> setCharacteristicNotification(BluetoothDevice? device, BluetoothCharacteristic? characteristic, bool enabled) async {
    if (device != null && characteristic != null) {
      List<BluetoothService> service = await device.discoverServices();
      BluetoothDescriptor descriptor = characteristic.descriptors.firstWhere((d) => d.uuid.toString().contains(CLIENT_CHARACTERISTIC_CONFIG));
      List<int> value = enabled ? ENABLE_NOTIFICATION_VALUE : DISABLE_NOTIFICATION_VALUE;
      await descriptor.write(value);
      return await characteristic.setNotifyValue(enabled);
    } else {
      return false;
    }
  }

  Future<void> registerOnCharacteristicChanged()async {
    BluetoothDevice device = (await FlutterBluePlus.instance.connectedDevices)[0];
    List<BluetoothService> services = await device.discoverServices();
    BluetoothService service = services.firstWhere((element) => element.uuid.toString().contains(serviceUuid));
    BluetoothCharacteristic characteristic = service
        .characteristics.firstWhere(
            (c) => c.uuid.toString().contains(characteristicUuids[1]));
    await setCharacteristicNotification(device, characteristic, true);


    characteristic.value.listen((data) {
      List<int> bytes = data;
      List<int> includeMinus = List<int>.from(data.map((byte) {
        if (byte >= 128) {
          return byte - 256;
        } else {
          return byte;
        }
      }));
      data = includeMinus;
      manage.parseBuffer(data, (data, antennaNo, deviceNo, communicationMode, temperature)
      {
        latestRead = data;
        lastReadTime = DateTime.now();
        _handelTheCommonestId(data);
        onCharacteristicChanged(data, antennaNo, deviceNo, communicationMode, temperature);
      });

    });
  }
  Future<void> onCharacteristicChanged(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) async{
    callBack.call(data, antennaNo, deviceNo, communicationMode, temperature);
  }
  void _handelTheCommonestId(String readId){
    // lastReadTime
    // index
    if(!(allIds.length == idsLimit)){
      allIds.add(readId);
      index++;
      if(index == idsLimit-1){
        index = 0;
      }
      return;
    }
    if(index >= idsLimit-1){
      allIds[index] = readId;
      index++;
      if(index == idsLimit-1){
        index = 0;
      }
    }

  }

  String getTagId(){
    return latestRead;
    DateTime now = DateTime.now();
    if(lastReadTime.difference(now).inMilliseconds.abs() < 2000){
      List<String> unique = [];
      List<int> score = [];
      for (var id in allIds) {
        int idIndex = unique.indexOf(id);

        if(idIndex == -1){
          unique.add(id);
          score.add(1);
        }else{
          score[idIndex]++;
        }
      }
      score.sort();
      return unique[score.last];
    }else{
      return "";
    }
  }

  void unRegister() async{
    BluetoothDevice device = (await FlutterBluePlus.instance.connectedDevices)[0];
    List<BluetoothService> services = await device.discoverServices();
    BluetoothService service = services.firstWhere((element) => element.uuid.toString().contains(serviceUuid));
    BluetoothCharacteristic characteristic = service
        .characteristics.firstWhere(
            (c) => c.uuid.toString().contains(characteristicUuids[1]));
    await setCharacteristicNotification(device, characteristic, false);
  }

  void startScan(){
    FlutterReactive.flutterReactiveBle.scanForDevices(withServices: []).listen((event) {
      if(listenerDevice != null){
        listenerDevice!(event);
      }

    }, onError: (error){

    });
  }

}