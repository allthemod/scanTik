
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

AdBanner initInstance(Future<InitializationStatus> initialization){
  AdBanner instance = AdBanner(initialization);
  AdBanner.instance = instance;
  return instance;
}
class AdBanner{
  static AdBanner? instance;
  AdBanner? getInstance(){
    return instance;
  }


  Future<InitializationStatus> initialization;

  AdBanner(this.initialization);

  String get bannerAdUnitId => Platform.isAndroid?
      "ca-app-pub-3940256099942544/6300978111":
      "ca-app-pub-3940256099942544/2934735716";
// String get bannerAdUnitId => Platform.isAndroid?
  // "ca-app-pub-9451058829525871/6749763021":
  // "ca-app-pub-9451058829525871/7400461723";

  final BannerAdListener _adListener = BannerAdListener(
      onAdLoaded: (ad) => print('Ad loaded: ${ad.adUnitId}.'), onAdClosed: (ad) => print('Ad closed: ${ad.adUnitId}.'),
      onAdFailedToLoad: (ad, error) =>
          print('Ad failed to load! ${ad.adUnitId}, $error.'),
      onAdOpened: (ad) => print('Ad opened: ${ad.adUnitId}.'),

  );
  get adListener => _adListener;
}