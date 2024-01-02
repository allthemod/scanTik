library smartscan.main;


import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartscan/resultPanel.dart';
import 'package:smartscan/strings.dart';
import 'ads/mainBanner.dart';
import 'settings/selectDevice.dart';
import 'strings.dart' as strings;
import 'scanSelectMode.dart' as select;
import 'package:smartscan/settings/settingsFragment.dart' as settings;
import 'package:flutter_screenutil/flutter_screenutil.dart';



class FlutterReactive{
  static final flutterReactiveBle = FlutterReactiveBle();


}


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final adFuture = MobileAds.instance.initialize();
  AdBanner banner = initInstance(adFuture);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);


  runApp(const MyApp());
}
bool isAndroid() {
  return Platform.isAndroid;
}
AppBar MyAppBar(BuildContext context){
  return AppBar(
    backgroundColor: strings.secondaryColors,
    title: const Text(strings.appName),
    actions: [
      getIconButton(context)
    ],
  );
}
AppBar MyAppBarNon(){
  return AppBar(
    backgroundColor: strings.secondaryColors,
    title: const Text(strings.appName),
  );
}
AppBar popMyAppBar(BuildContext context){
  return AppBar(
    backgroundColor: strings.secondaryColors,
    title: const Text(strings.appName),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      getIconButton(context)
    ],
  );
}

IconButton getIconButton(BuildContext context){
  return IconButton(onPressed: () {
    navToSettings(context);
  }, icon: const Icon(Icons.settings));
}

void navToScan(BuildContext context){
  Navigator.push(context, MaterialPageRoute(builder: (_) => const select.Scanmode()));
}
void navToSettings(BuildContext context){
  Navigator.push(context, MaterialPageRoute(builder: (_) => const settings.MainSettings()));
}
void navToExtraFeatures(){

}
String readFile(String fileName) {
  try{
    final Directory? appDir = strings.mainDir;
    String? path = appDir?.path;
    File file = File('$path/$fileName');
    String stringFile = file.readAsStringSync(encoding: const SystemEncoding()).toString();
    return stringFile;
  } catch(e){
    return "NULL";
  }
}
Future<String> readFileAsync(String fileName) async{
  try{
    Directory appDir = await getApplicationDocumentsDirectory();
    String path = appDir.path;
    File file = File('$path/$fileName');
    String stringFile = file.readAsStringSync(encoding: const SystemEncoding()).toString();
    return stringFile;
  } catch(e){
    return "NULL";
  }
}
writeToFile(String fileName, String content) async {
  strings.mainDir ??= await getApplicationDocumentsDirectory();
  final Directory? appDir = strings.mainDir;
  String? path = appDir?.path;
  File file = File('$path/$fileName');
  if(!file.existsSync()){
    file.create();
  }
  file.writeAsStringSync(content);
}


writedir() async {
  strings.mainDir = await getApplicationDocumentsDirectory();
}
connectToDeviceViaAddressAsync(){
  readFileAsync("bluetoothDevice.txt").then((file) {
    if(file != "" &&file != "NULL"){
      FlutterBluePlus.instance.connectedDevices.then((value) {
        if(value.isEmpty){
          connectToDeviceViaAddress(file.split("\n")[1]);
        }
      });
    }
  });
}

Future<void> writeLinedFile(String fileName, String content, int line) async {
  strings.mainDir ??= await getApplicationDocumentsDirectory();
  final Directory? appDir = strings.mainDir;
  String? path = appDir?.path;
  File file = File('$path/$fileName');
  String writing = "";
  if(!file.existsSync()){
    file.create();
    String? write;
    for(int i = 0; i < line; i++){
      write = write!=null?"$write\n": "";
    }
    write = "$write$content";
    writing = write;
  }else{
    List<String> file = readFile(fileName).split("\n");
    if(file.length < line){
      for(int i = file.length-1;i < line; i++){
        file.add("");
      }
    }
    file[line-1] = content;
    String write = file.join("\n");
    writing = write;
  }
  file.writeAsStringSync(writing);
}

String readLinedFile(String fileName, int line){
  List<String> file =readFile(fileName).split("\n");
  try{
    return file[line-1];
  }catch(e){
    return "NULL";
  }

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    writedir();

    return const MaterialApp(

      home: Home()
    );
  }
}
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
  void checkForNull() async {
    String names = readFile("bagNames.json");
    if (names == "NULL" || names == "") {
      await writeToFile("bagNames.json", buildDefaultNames());
    }
  }
  void updateTypes(){
    strings.types = getNames();
    if(strings.types.contains("NULL")){
      checkForNull();
      strings.types = strings.typesC;
    }

  }

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    BluetoothManager().startScan();
    strings.ratio = MediaQuery.of(context).devicePixelRatio;
    strings.width = MediaQuery.of(context).size.width * strings.ratio;
    strings.height = MediaQuery.of(context).size.height * strings.ratio;
    strings.dpWidth = strings.width/410;
    strings.dpHigh = strings.height/840;
    connectToDeviceViaAddressAsync();
    String adsLine = readLinedFile("mainSettings.txt", 2);
    updateTypes();
    bool setAds = false;
    if(adsLine == "true"){
      setAds = true;
    }
    strings.Ad = setAds;
    return Scaffold(
      floatingActionButton: false?FloatingActionButton(onPressed: () {  }, backgroundColor: secondaryColors):null,
      appBar: MyAppBar(context),
      body: Column(
        children: [Column(

          children: [
            Flexible(flex: 0,child: AutoSizeText("welcome to our bag scanner,\n prepare to boost your efficiency", style: TextStyle(fontSize: ScreenUtil().setSp(40)), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2,)),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(icon: Image.asset("lib/drawable/scanner.png"), onPressed: () => navToScan(context), iconSize: ScreenUtil().setWidth(140)),
                    Expanded(flex: 2,child: AutoSizeText(" Scan your\n bag", style: TextStyle(fontSize: ScreenUtil().setSp(40)),minFontSize: 18,overflow: TextOverflow.ellipsis,maxLines: 2,))
                  ],
                ),
                Row(children: [
                  IconButton(icon: Image.asset("lib/drawable/extra_features.png"), onPressed: () => navToExtraFeatures(), iconSize: ScreenUtil().setWidth(140)),
                  Expanded(
                    flex: 2,
                    child: AutoSizeText(
                      " purchase\n extra\n features", style: TextStyle(fontSize: ScreenUtil().setSp(40)),minFontSize: 18,overflow: TextOverflow.ellipsis,maxLines: 3,
                    ),
                  )
                ],)
              ],
            ),

          ],
        ),
          if(banner != null && strings.Ad)
            Expanded(child: Container()),
          if(banner != null && strings.Ad)
            Container(height: 50,alignment: Alignment.bottomCenter,
              child: AdWidget(ad: banner!,),)
          else
            Container()
        ]
      ),
    );
  }
}


