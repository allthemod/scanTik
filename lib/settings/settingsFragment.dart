library smartscan.settingsfragment;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smartscan/settings/selectDevice.dart';
import 'package:smartscan/strings.dart' as strings;
import 'package:smartscan/scanSelectMode.dart' as select;
import 'package:settings_ui/settings_ui.dart';
import 'package:smartscan/main.dart' as main;

import '../ads/mainBanner.dart' as milk;
import '../main.dart';
import '../strings.dart';
import 'customizeDataset.dart';


void navToSelect(BuildContext context){
  Navigator.push(context, MaterialPageRoute(builder: (_) => const selectDevice()));
}
void navToCustomize(BuildContext context){
  Navigator.push(context, MaterialPageRoute(builder: (_) => const customizeDataset()));
}
class MainSettings extends StatefulWidget {
  const MainSettings({Key? key}) : super(key: key);

  @override
  State<MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  bool rewriteValue = false;
  bool ads = true;
  void onChangeRewrite(bool? value){
    setState(() {
      rewriteValue = value!;
      String val = "false";
      if(value){
        val = "true";
      }
      writeLinedFile("mainSettings.txt", val, 1);
    });
  }
  void onChangeAds(bool? value){
    setState(() {
      ads = value!;
      strings.Ad = ads;
      String val = "false";
      if(value){
        val = "true";
      }
      writeLinedFile("mainSettings.txt", val, 2);
    });
  }


  @override
  void initState() {
    String rewriteLine = readLinedFile("mainSettings.txt", 1);
    String adsLine = readLinedFile("mainSettings.txt", 2);
    bool setRewrite = false;
    bool setAds = false;
    if(adsLine == "true"){
      setAds = true;
    }
    if(rewriteLine == "true"){
      setRewrite = true;
    }
    if(setRewrite){
      setState(() {
        rewriteValue = true;
      });
    }
    if(setAds){
      setState(() {
        ads = true;
      });

    }else{
      setState(() {
        ads = false;
      });
    }
    super.initState();
  }

  BannerAd? banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();


    final adstate = milk.AdBanner.instance;
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
      appBar: main.MyAppBarNon(),
      body: Column(
        children: [
          Flexible(
            flex: 13,
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Common'),
                  tiles: [
                    SettingsTile.navigation(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      value: const Text('English'),
                    ),
                  ],
                ),
                SettingsSection(title: const Text("Scan data"),
                  tiles: <SettingsTile> [
                    SettingsTile.navigation(
                      title: const Text('Connect device'),
                      leading: const Icon(Icons.bluetooth_searching),
                      value: const Text("Connect your device"),
                      onPressed: (context) => navToSelect(context),
                    ),
                    SettingsTile.navigation(
                      title: const Text('customize datasets'),
                      leading: const Icon(Icons.data_array),
                      onPressed: (context) => navToCustomize(context),
                    ),
                    SettingsTile.navigation(title: const Text("write Stickers")
                    ,leading: SizedBox(width: 25,height: 25,child: Checkbox(value: rewriteValue, onChanged: (value) => onChangeRewrite(value),)),),
                    SettingsTile.navigation(title: const Text("Ads?")
                      ,leading: SizedBox(width: 25,height: 25,child: Checkbox(value: ads, onChanged: (value) => onChangeAds(value),)),)
                  ],
                ),
              ],
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
