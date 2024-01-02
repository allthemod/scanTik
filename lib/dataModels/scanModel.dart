class ScanModel{
  String address;
  String name;
  String rssi;

  ScanModel(this.address, this.name, this.rssi);

  String getAddress(){
    return address;
  }
  String getName(){
    return name;
  }
  String getRssi(){
    return rssi;
  }
}