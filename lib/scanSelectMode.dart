library smartscan.scanselectmode;


import 'dart:core';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smartscan/resultPanel.dart';
import 'ads/mainBanner.dart';
import 'main.dart' as main_class;
import 'main.dart';
import 'strings.dart' as strings;
import 'scanModes/school.dart';


// void changeScanMode(BuildContext context, int index){
//   if(index == 0){
//     writeToFile("mode.txt", "school");
//     Navigator.push(context, MaterialPageRoute(builder: (_) {
//       return const result();
//     },));
//   }
// }
void changeScanMode(BuildContext context, int index, List<String> choose){
  writeToFile("mode.txt", choose[index]);
  Navigator.push(context, MaterialPageRoute(builder: (_) {
    return const result();
  },));
}

class Scanmode extends StatefulWidget {
  const Scanmode({Key? key}) : super(key: key);

  @override
  State<Scanmode> createState() => _ScanmodeState();
}

class _ScanmodeState extends State<Scanmode> {
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
  List<String> getNames(){
    return readFile("bagNames.json").split(",\n");
  }
  String buildDefaultNames(){
    return strings.typesC.join(",\n");
  }
  void addBagName(String bagName) async{
    String names = readFile("bagNames.json");
    if(names == "NULL" || names == ""){
      await writeToFile("bagNames.json", buildDefaultNames());
      names = buildDefaultNames();
    }
    names = "$names,\n$bagName";
    await writeToFile("bagNames.json", names);
    setState(() {

    });

  }
  void removeBagName(String bagName){
    List<String> namess = getNames();
    namess.remove(bagName);
    writeToFile("bagNames.json", namess.join(",\n"));
  }
  void updateTypes(){
    setState(() {
      strings.types = getNames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: popMyAppBar(context),
        body: Column(
          children: [
            Flexible(
              flex: 13,
              child: SizedBox(
                height: ScreenUtil().setHeight(1000),
                child: ListView.builder(
                  itemCount: strings.types.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      child: ElevatedButton(onPressed: () => changeScanMode(context, index, strings.types), style: ButtonStyle(
                        backgroundColor: const MaterialStatePropertyAll(strings.secondaryColors),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(const RoundedRectangleBorder( borderRadius: BorderRadius.all(Radius.circular(0)),
                          side: BorderSide(width: 1.1, color: Colors.teal))),

                        ),
                          onLongPress: () {
                            if(isAndroid()){
                              showDialog(context: context, builder: (context) => RemoveBagTypeAndroid(),).then((value) {
                                if(value){
                                  removeBagName(strings.types.elementAt(index));
                                  updateTypes();
                                }
                              });
                            }else{
                              showCupertinoDialog(context: context, builder: (context) => RemoveBagType()).then((value) {
                                if(value){
                                  removeBagName(strings.types.elementAt(index));
                                  updateTypes();
                                }
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: ScreenUtil().setWidth(60),
                            alignment: Alignment.center,
                            child: AutoSizeText(strings.types.elementAt(index), style: TextStyle(fontSize: ScreenUtil().setSp(50)), overflow: TextOverflow.ellipsis, maxLines: 1,
                            ),
                          ),
                      ),
                    );
                  },

                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ElevatedButton(onPressed: () {
                if(isAndroid()){
                  showDialog(context: context, builder: (context) => const AddBagDialogAndroid(),).then((value) {
                    if(value&&!getNames().contains(textF().text)){
                      addBagName(textF().text);
                      updateTypes();
                    }
                  },);
                }else{
                  showCupertinoDialog(context: context, builder: (context) => const AddBagDialog()).then((value) {
                    if(value&&!getNames().contains(textF().text)){

                      addBagName(textF().text);
                      updateTypes();
                    }
                    }
                  );
                }
              },
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(strings.secondaryColors),
                  ),
                  child: Container(padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(60)),child: const Text("Add another bag type"))),
            ),
            if(banner != null && strings.Ad)
              Flexible(flex: 1,child: AdWidget(ad: banner!,))
            else
              Container()
          ],
        ),
      ),
    );
  }
}
class textF{
  static final textF classInstance = textF._internal();

  factory textF() {
    return classInstance;
  }

  textF._internal();
  String text = "";

}

class AddBagDialog extends StatefulWidget {
  const AddBagDialog({Key? key}) : super(key: key);

  @override
  State<AddBagDialog> createState() => _AddBagDialogState();
}

class _AddBagDialogState extends State<AddBagDialog> {
  String bagName = "";
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Type your desired bag name"),
      content: TextField(
        onChanged: (value) {bagName = value; textF().text = value;},
        decoration: const InputDecoration(hintText: "Bag name"),
      ),
      actions: [
        CupertinoDialogAction(child: const Text("Add"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}
class AddBagDialogAndroid extends StatefulWidget {
  const AddBagDialogAndroid({Key? key}) : super(key: key);

  @override
  State<AddBagDialogAndroid> createState() => _AddBagDialogAndroid();
}

class _AddBagDialogAndroid extends State<AddBagDialogAndroid> {
  String bagName = "";
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Type your desired bag name"),
      content: TextField(
        onChanged: (value) {bagName = value; textF().text = value;},
        decoration: const InputDecoration(hintText: "Bag name"),
      ),
      actions: [
        CupertinoDialogAction(child: const Text("Add"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true when 'Yes' is pressed
          },),
        CupertinoDialogAction(child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop(false); // Return true when 'Yes' is pressed
          },)
      ],
    );
  }
}




class RemoveBagType extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Do you want to remove this bag?"),
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

class RemoveBagTypeAndroid extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Do you want to remove this bag?"),
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