import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hex/hex.dart';

import '../ads/mainBanner.dart';
import '../dataModels/presetModel.dart';
import '../main.dart';
import '../resultPanel.dart';
import '../strings.dart' as strings;
import '../strings.dart';

Map<String, dynamic> dayObject = json.decode('{"sunday": {}, "monday": {}, "tuesday": {}, "wednesday": {}, "thursday": {}, "friday": {}, "saturday": {}}');
Map<String, dynamic> buildJsonQuickAdd(String ids, String names) {
  List<String> idsArray = ids.split(",");
  List<String> namesArray = names.split(",");
  List<String> idsJson = [];
  List<String> namesJson = [];
  for (int i = 0; i < idsArray.length; i++) {
    idsJson.add(idsArray[i]);
    namesJson.add(namesArray[i]);
  }
  Map<String, dynamic> jsonWithoutTitle = {
    'ids': idsJson,
    'names': namesJson,
  };
  return jsonWithoutTitle;
}

void writePreset(String ids, String names, String title, String where) {
  String preset = readFile("quickAddPresets.json");
  if(preset == "NULL"){
    writeToFile("quickAddPresets.json", json.encode(buildJsonDefault()));
    preset = json.encode(buildJsonDefault());
  }
  Map<String, dynamic> jsonData = json.decode(preset);
  if(jsonData[where] == null){
    jsonData[where] = {};
  }
  jsonData[where][title] = buildJsonQuickAdd(ids, names);
  writeToFile("quickAddPresets.json", json.encode(jsonData));
}
void removePresetFunc(String where, String item) {
  String preset = readFile("quickAddPresets.json");
  if(preset == "NULL"){
    writeToFile("quickAddPresets.json", json.encode(buildJsonDefault()));
  }
  Map<String, dynamic> jsonData = json.decode(preset);
  jsonData[where].remove(item);
  writeToFile("quickAddPresets.json", json.encode(jsonData));
}
void writeDataSet(String where, DatasetModel presetToAdd, String day) {
  String dataset = readFile("dataSets.json");
  if(dataset == "NULL"){
    writeToFile("dataSets.json", json.encode(buildJsonDefaultDays()));
  }
  Map<String, dynamic> datasetJson = json.decode(readFile("dataSets.json"));
  datasetJson[where][day][presetToAdd.getNameOfPreset()] = presetToAdd.getJson();
  writeToFile("dataSets.json", json.encode(datasetJson));
}
void removeDataSet(String where, String presetName, String day) {
  String dataset = readFile("dataSets.json");
  if(dataset == "NULL"){
    writeToFile("dataSets.json", json.encode(buildJsonDefaultDays()));
  }
  Map<String, dynamic> datasetJson = json.decode(readFile("dataSets.json"));
  datasetJson[where][day].remove(presetName);
  writeToFile("dataSets.json", json.encode(datasetJson));
}
List<DatasetModel> getDataset(String where, String day) {
  String dataset = readFile("dataSets.json");
  if(dataset == "NULL"){
    writeToFile("dataSets.json", json.encode(buildJsonDefaultDays()));
    dataset = json.encode(buildJsonDefaultDays());
  }
  Map<String, dynamic> datasetJson = json.decode(dataset);
  if(datasetJson[where] == null){
    datasetJson[where] = dayObject;
    writeToFile("dataSets.json", json.encode(datasetJson));
  }
  return parseJsonToModel(datasetJson[where][day]);
}
List<DatasetModel> parseJsonToModel(Map<String, dynamic>? dataJSON) {
  if(dataJSON == null){
    return [];
  }
  List<DatasetModel> formattedData = [];
  dataJSON.forEach((key, value) {
    List<DatasetMiniModel> miniModels = [];
    Map<String, dynamic> data = value;
    List<String> ids = [];
    List<String> names = [];
    List<dynamic> idsArray = data["ids"];
    List<dynamic> namesArray = data["names"];
    int lengthHeader = idsArray.length;
    for (int j = 0; j < lengthHeader; j++) {
      ids.add(idsArray[j]);
      names.add(namesArray[j]);
    }
    for (int j = 0; j < ids.length; j++) {
      miniModels.add(DatasetMiniModel(names[j], ids[j]));
    }
    formattedData.add(DatasetModel(key, miniModels));
  });
  return formattedData;
}


Map buildJsonDefault(){
  Map constructing = {};
  for(String argument in strings.types){
    constructing[argument] = {};
  }
  return constructing;
}
Map buildJsonDefaultDays(){
  Map jsonObject = {};
  List<String> arguments = strings.types;
  for (String argument in arguments) {
    jsonObject[argument] = dayObject;
}
  return jsonObject;
}
List<DatasetModel> getPresetsMap(String mode){
  String preset = readFile("quickAddPresets.json");
  if(preset == "NULL" || preset == ""){
    writeToFile("quickAddPresets.json", json.encode(buildJsonDefault()));
    preset = json.encode(buildJsonDefault());
  }
  Map<String, dynamic> jsonData = json.decode(preset);
  List<DatasetModel> presetModels = jsonData[mode] != null? parseJsonToModel(jsonData[mode]): [];
  return presetModels;
}

class customizeDataset extends StatefulWidget {
  const customizeDataset({Key? key}) : super(key: key);
  @override
  State<customizeDataset> createState() => _customizeDatasetState();

}

class _customizeDatasetState extends State<customizeDataset> {

  String dropDownValue = strings.types.first;
  List<bool> selectedDayToggle = [true, false, false, false, false, false, false];
  String selectedDayString = "sunday";
  List<DatasetModel> presetModels = [];
  String itemsName = "";
  String itemsIds = "";
  String presetName = "";
  bool removePreset = false;
  bool removeDatasetVar = false;
  int indexPreset = 0;
  List<bool> presetExpand = [];
  IconData plusIcon = Icons.add;
  IconData removeIcon = Icons.remove;
  List<DatasetModel> datasetModels = [];
  List<IconData> datasetIcon = List.generate(0, (index) => Icons.add);
  List<bool> visibilityDataset = List.generate(0, (index) => false);
  BorderRadius borderForDataset = const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(0));
  List<BorderRadius> borderDataset = List.generate(0, (index) =>const BorderRadius.all(Radius.circular(8)));
  BluetoothManager? _bluetoothManager;

  void updatePresetModels() async{
    String preset = readFile("quickAddPresets.json");
    if(preset == "NULL" || preset == ""){
      await writeToFile("quickAddPresets.json", json.encode(buildJsonDefault()));
      preset = json.encode(buildJsonDefault());
    }
    Map<String, dynamic> jsonData = json.decode(preset);
    setState(() {
      presetModels = jsonData[dropDownValue] != null? parseJsonToModel(jsonData[dropDownValue]): [];
    });
  }
  void updateDatasetModels() async{
    String preset = readFile("dataSets.json");
    if(preset == "NULL" || preset == ""){
      await writeToFile("dataSets.json", json.encode(buildJsonDefaultDays()));
      preset = json.encode(buildJsonDefaultDays());
    }
    setState(() {
      datasetModels = getDataset(dropDownValue, selectedDayString).isEmpty ? []: getDataset(dropDownValue, selectedDayString);
    });
  }
  @override
  void initState() {
    super.initState();
    updatePresetModels();
    updateDatasetModels();
    datasetIcon = List.generate(datasetModels.length, (index) => Icons.add);
    visibilityDataset = List.generate(datasetModels.length, (index) => false);
    borderForDataset = const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(0));
    borderDataset = List.generate(datasetModels.length, (index) =>const BorderRadius.all(Radius.circular(8)));
    _bluetoothManager = BluetoothManager();
    _bluetoothManager?.setListener((String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) {
      if(data.isEmpty){
        return;
      }
      print(data);

    });
    _bluetoothManager?.registerOnCharacteristicChanged();
  }

  @override
  void dispose() {
    super.dispose();
    _bluetoothManager?.unRegister();
    _bluetoothManager = null;

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
    if(datasetIcon.length < datasetModels.length){
      while(datasetIcon.length < datasetModels.length){
        visibilityDataset.add(false);
        borderForDataset.add(const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(0)));
        borderDataset.add(const BorderRadius.all(Radius.circular(8)));
        datasetIcon.add(Icons.add);
      }
    }
    return Scaffold(
      appBar: popMyAppBar(context),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 0,
                child: DropdownButton(
                    items: strings.types
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? value) => dropDownUpdate(value),
                    value: dropDownValue),
              ),
              Text(
                "You can put multiple id \n and names by putting commas",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ScreenUtil().setSp(15)),
                textScaleFactor: 1.1,

              )
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.only(right: 5, left: 5),
                  child: TextField(
                    onChanged: (value) {
                      itemsName = value;
                    },
                    decoration: InputDecoration(hintText: 'Item name', hintStyle: TextStyle(fontSize: ScreenUtil().setSp(16))),
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  child: ElevatedButton(
                    onPressed: () {
                      String? copy = _bluetoothManager?.getTagId();
                      if(copy == null || copy.isEmpty){
                        Fluttertoast.showToast(msg: "Go near a sticker");
                        return;
                      }
                      Clipboard.setData(ClipboardData(text: copy));
                      Fluttertoast.showToast(msg: "Copied the nearest ID");
                    },
                    style: ButtonStyle(
                        backgroundColor: const MaterialStatePropertyAll(
                            strings.secondaryColors),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))))),
                    child: Text("copy nearest\naddress", style: TextStyle(fontSize: ScreenUtil().setSp(12.5)), maxLines: 2,textScaleFactor: 1.15),
                  ),
                ),
              )
            ],
          ),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 5, left: 5),
                  child: TextField(
                      key: const Key("ItemsIds"),
                      onChanged: (value) {
                        itemsIds = value;
                      },
                      decoration: InputDecoration(hintText: "Id of the item",contentPadding: EdgeInsets.symmetric(vertical: 0.0), hintStyle: TextStyle(fontSize: ScreenUtil().setSp(16)))),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.only(right: 5, left: 5),
                    child: TextField(
                      key: const Key("PresetName"),
                      onChanged: (value) {
                        presetName = value;
                      },
                      decoration: InputDecoration(hintText: "title of preset",hintStyle: TextStyle(fontSize: ScreenUtil().setSp(16)) ),
                    ),
                  )),
              Flexible(
                flex: 0,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(5, 10, 5, 0),
                  child: ElevatedButton(
                      onPressed: () {
                        if(presetName == ""){
                          return;
                        }
                        writePreset(itemsIds, itemsName, presetName, dropDownValue);
                        updatePresetModels();
                      },
                      style: ButtonStyle(
                          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          backgroundColor: const MaterialStatePropertyAll(
                              strings.secondaryColors)),
                      child: Text("Add", style: TextStyle(fontSize: ScreenUtil().setSp(14)))),
                ),
              )
            ],
          ),

          Expanded(
            flex: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 5, top: 10, right: 0),
                child: ToggleButtons(
                  key: const Key("DayList"),
                  color: Colors.black,
                  highlightColor: lightSecondaryColors,
                  isSelected: selectedDayToggle,
                  focusColor: secondaryColors,
                  textStyle: const TextStyle(fontSize: 20),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  borderColor: lightSecondaryColors,
                  selectedBorderColor: secondaryColors,
                  children: [
                    Container(padding: const EdgeInsets.all(5),child: const Text('sunday'),),
                    Container(padding: const EdgeInsets.all(5), child: const Text('monday')),
                    Container(padding: const EdgeInsets.all(5), child: const Text('tuesday')),
                    Container(padding: const EdgeInsets.all(5), child: const Text('wednesday')),
                    Container(padding: const EdgeInsets.all(5), child: const Text('thursday')),
                    Container(padding: const EdgeInsets.all(5), child: const Text('friday')),
                    Container(padding: const EdgeInsets.all(5), child: const Text('saturday')),
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedDayToggle = [false, false, false, false, false, false, false];
                      selectedDayToggle[index] = !selectedDayToggle[index];
                      selectedDayString = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][index];
                    }); updateDatasetModels();
                  },
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                height: 50,
                width: strings.width/strings.ratio,
                child: ListView.builder(itemCount: presetModels.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(style: const ButtonStyle(
                      shape: MaterialStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      backgroundColor: MaterialStatePropertyAll(strings.secondaryColors),
                    ),
                    onLongPress: () {
                      indexPreset = index;
                      if(isAndroid()){
                        showDialog(context: context, builder: (context) => const RemovePresetDialogAndroid(),).then((value) {
                          removePreset = value;
                          if(removePreset){
                            removePresetFunc(dropDownValue, presetModels[index].getNameOfPreset());
                            updatePresetModels();
                            removePreset = false;
                          }
                        },);
                      }else{
                        showCupertinoDialog(context: context, builder: (context) => const RemovePresetDialog()).then((value) {
                          removePreset = value;
                          if(removePreset){
                            removePresetFunc(dropDownValue, presetModels[index].getNameOfPreset());
                            updatePresetModels();
                            removePreset = false;
                          }
                        });
                      }
                    },
                    onPressed: () {
                      writeDataSet(dropDownValue, presetModels[index], selectedDayString);
                      updateDatasetModels();
                    }, child: Text(presetModels[index].getNameOfPreset(), style: const TextStyle(fontSize: 17,),textAlign: TextAlign.center,)),
                  );
                },),
              )
            ],
          ),
          Expanded(
            flex: 7,
            child: Container(
              height: strings.height,
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
              child: ListView.builder(itemCount: datasetModels.length,
                itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        indexPreset = index;
                        if(isAndroid()){
                          showDialog(context: context, builder: (context) => const RemoveDatasetDialogAndroid(),).then((value) {
                            removeDatasetVar = value;
                            if(removeDatasetVar){
                              removeDataSet(dropDownValue, datasetModels[indexPreset].getNameOfPreset(), selectedDayString);
                              updateDatasetModels();
                              removeDatasetVar = false;
                            }
                          },);
                        }else{
                          showCupertinoDialog(context: context, builder: (context) => const RemoveDatasetDialog()).then((value) {
                            removeDatasetVar = value;
                            if(removeDatasetVar){
                              removeDataSet(dropDownValue, datasetModels[indexPreset].getNameOfPreset(), selectedDayString);
                              updateDatasetModels();
                              removeDatasetVar = false;
                            }
                          });
                        }
                      },
                      child: Card(
                        color : const Color.fromARGB(255,37,46,61),
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: borderDataset[index],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          datasetModels[index].getNameOfPreset(),
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.orangeAccent[200],
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        datasetIcon[index],
                                        size: 15.0,
                                        color: Colors.orangeAccent[200],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          datasetIcon[index] = datasetIcon[index] == plusIcon?removeIcon:plusIcon;
                                          visibilityDataset[index] = datasetIcon[index] == plusIcon?false:true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: visibilityDataset[index],
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8), top: Radius.zero)
                                  ),
                                  child: Card(
                                    color: const Color.fromARGB(255 ,14,22,33),
                                    margin: const EdgeInsets.symmetric(vertical: 0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        datasetModels[index].getMiniModelsString(),
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.orangeAccent[200],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },),
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



  void dropDownUpdate(String? value) {
    if (value is String) {
      setState(() {
        dropDownValue = value;

      });
      updateDatasetModels();
      updatePresetModels();


    }
  }



}
class RemovePresetDialog extends StatelessWidget {
  const RemovePresetDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Do you want to remove this preset?"),
      actions: [
        CupertinoDialogAction(child: const Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("No"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}
class RemovePresetDialogAndroid extends StatelessWidget {
  const RemovePresetDialogAndroid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Do you want to remove this preset?"),
      actions: [
        CupertinoDialogAction(child: const Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("No"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}
class RemoveDatasetDialog extends StatelessWidget {
  const RemoveDatasetDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Do you want to remove this preset from your dataset?"),
      actions: [
        CupertinoDialogAction(child: const Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("No"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}
class RemoveDatasetDialogAndroid extends StatelessWidget {
  const RemoveDatasetDialogAndroid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Do you want to remove this preset from your dataset?"),
      actions: [
        CupertinoDialogAction(child: const Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("No"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}

