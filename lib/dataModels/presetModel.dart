class DatasetModel {
  String nameOfPreset;
  List<DatasetMiniModel> miniModels;

  DatasetModel(this.nameOfPreset, this.miniModels);

  String getNameOfPreset() {
    return nameOfPreset;
  }

  List<String> getIds() {
    List<String> ids = [];
    for (int i = 0; i < miniModels.length; i++) {
      ids.add(miniModels[i].getId());
    }
    return ids;
  }

  List<String> getNames() {
    List<String> names = [];
    for (int i = 0; i < miniModels.length; i++) {
      names.add(miniModels[i].getNameOfQuick());
    }
    return names;
  }

  List<DatasetMiniModel> getMiniModels() {
    return miniModels;
  }

  Map<String, dynamic> getJson() {
    Map<String, dynamic> thisJsonObject = {};
    List<String> ids = [];
    List<String> names = [];
    int loopGetDataLength = miniModels.length;
    for (int i = 0; i < loopGetDataLength; i++) {
      DatasetMiniModel currentMiniModel = miniModels[i];
      ids.add(currentMiniModel.getId());
      names.add(currentMiniModel.getNameOfQuick());
    }
    thisJsonObject["ids"] = ids;
    thisJsonObject["names"] = names;
    return thisJsonObject;
  }
  String getMiniModelsString(){
    List<String> names = getNames();
    List<String> ids = getIds();
    String building = "";
    for(int i = 0;i < miniModels.length; i++){
      String name = names[i];
      String id = ids[i];
      String add = i == miniModels.length-1?"":"\n";
      building = "$building $name $id $add";
    }
    return building;
  }
}

class DatasetMiniModel {
  String nameOfQuick;
  String id;
  bool notReq = false;

  DatasetMiniModel(this.nameOfQuick, this.id);

  String getNameOfQuick() {
    return nameOfQuick;
  }

  String getId() {
    return id;
  }
}
