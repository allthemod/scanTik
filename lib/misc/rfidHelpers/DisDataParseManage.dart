library com.milk.bagScanner.reader.rfid.mode;

import 'dart:io';

import 'package:hex/hex.dart';

import '../../resultPanel.dart';
import 'BasePackage.dart';
import 'DisCommand.dart';

class DisDataParseManage
{
  static Map<int, ReceiveData> mapData = <int, ReceiveData>{};
  ParseData parseStdVar = ParseData();
  ParseData parseSingleVar = ParseData();
  ParseData parseMultipleVar = ParseData();
  ParseData parseTemperatureVar = ParseData();
  String communicationMode = "";
  bool isSingle = false;
  bool isMultiple = false;
  bool isTemperature = false;
  late BluetoothManager leProxy;
  //DisDataParseManage(this.leProxy);
  DisDataParseManage getMe(){
    return this;
  }

  int byteToInt(List<int> bytes) {
    int result = 0;
    for (int i = 0; i < bytes.length; i++) {
      result |= bytes[i] << (8 * i);
    }
    return result;
  }
  int sumWithOverflow(List<int> values) {
    int sum = 0;
    for (int value in values) {
      sum += value;
      if (sum > 127) {
        sum = sum - 256;
      } else if (sum < -128) {
        sum = sum + 256;
      }
    }
    return sum;
  }

  bool isDecimal(String str) {
    final regex = RegExp(r'^-?\d+(\.\d+)?$');
    return regex.hasMatch(str);
  }
  String bytesToHexString(List<int> bytes) {
    const hexDigits = '0123456789ABCDEF';
    final buffer = StringBuffer();
    for (final b in bytes) {
      final unsignedByte = b & 0xFF; // Convert signed byte to unsigned byte
      buffer.write(hexDigits[(unsignedByte >> 4) & 0x0F]); // Write high nibble
      buffer.write(hexDigits[unsignedByte & 0x0F]); // Write low nibble
    }
    return buffer.toString();
  }


  void arrayCopy(List src, int srcPos, List dest, int destPos, int length) {
    for (int i = 0; i < length; i++) {
      dest[destPos + i] = src[srcPos + i];
    }
  }




  int checkSum(List<int> startcode, int start, int length)
  {
    int sum = 0;
    for (int i = start; i < (length - start); (++i)) {
      sum += startcode[i];
    }
    sum = ((~sum) + 1);
    return sum;
  }

  int getCheckSum(List<int> startcode, int length)
  {
    List<int> toSum = [];
    for (int i = 0; i < length; (++i)) {
      toSum.add(startcode[i]);
    }
    int sum = sumWithOverflow(toSum);
    sum = ((~sum) + 1);
    return sum;
  }

  bool getCallBack(List<int> buffer, List<int> bufferLength, int cmd, int timeOut)
  {
    if(mapData[cmd] == null){
      return false;
    }
    int end;
    int temp = 0;
    bool flag = false;
    int start = DateTime.now().millisecondsSinceEpoch;
    try {
      do {
        if (mapData.containsKey(cmd)) {
          bufferLength.add(mapData[cmd]!.length);
          buffer.addAll(mapData[cmd]!.getData());
          flag = true;
          mapData.remove(cmd);
          break;
        }
        end = DateTime.now().millisecondsSinceEpoch;
        temp = (end - start);
        sleep(const Duration(seconds: 1));
      } while (temp < timeOut);
      end = DateTime.now().millisecondsSinceEpoch;
      return flag;
    } on Exception catch (e) {
      e.toString();
    }
    return flag;
  }

  int getCurrentCheckSum(ParseData parseData, List<int> buffer, int length)
  {
    List<int> sendData = List.generate(5+length, (index) => 0);
    int index = 0;
    sendData[index] = parseData.startcode;
    sendData[++index] = parseData.len;
    sendData[++index] = parseData.cmd;
    int count = 0;
    int i = (++index);
    if (length > 0) {
      for (; (i < sendData.length) && (count < length); i++) {
        sendData[i] = buffer[count];
        count++;
      }
    }
    parseData.bcc = checkSum(sendData, 0, sendData.length - 1);
    sendData[i] = parseData.bcc;
    return sendData[i];
  }

  List<int> getSendCMD(ParseData parseData, List<int> data, int length)
  {
    List<int> sendData = List.generate(5+length, (index) => 0);
    int index = 0;
    sendData[index] = parseData.startcode;
    sendData[++index] = parseData.len;
    sendData[++index] = parseData.cmd;
    sendData[++index] = parseData.deviceNo;
    int count = 0;
    int i = (++index);
    if (length > 0) {
      for (; (i < sendData.length) && (count < length); i++) {
        sendData[i] = data[count];
        count++;
      }
    }
    sendData[i] = checkSum(sendData, 0, sendData.length - 1);
    return sendData;
  }

  bool sendData(String mSelectedAddress, ParseData parseData, int cmd, List<int> sendBuf, int bufsize)
  {
    parseData.startcode = DisCommand.DIS_START_CODE;
    parseData.cmd = cmd;
    parseData.len = (3 + bufsize);
    parseData.deviceNo = 0;
    List<int> data;
    if (bufsize > 0) {
      data = List.generate((bufsize + 1), (index) => 0);
      data = sendBuf.sublist(0, bufsize+1);
    } else {
      data = List.generate(1, (index) => 0);
      data = data.sublist(0, 1);
    }
    List<int> datas = getSendCMD(parseData, data, bufsize);
    bool size = false;
    if (leProxy != null) {
      leProxy.send(datas, false);
      size = true;
    }
    return size;
  }

  bool parseStd(ParseData parse, int data)
  {
    if (parse.headCount < DisCommand.HEAD_LENGTH) {
      switch (parse.headCount) {
        case 0:
          if ((data == DisCommand.DIS_HEAD_CONDE) || (data == DisCommand.DIS_HEAD_CONDE1)) {
            parse.startcode = data;
            parse.headCount++;
            parse.bufferLen.clear();
            parse.buffer.clear();
          } else {
            parse.headCount = 0;
          }
          break;
        case 1:
          parse.len = data;
          parse.headCount++;
          parse.bufferLen.add(data);
          break;
        case 2:
          parse.cmd = data;
          parse.headCount++;
          break;
        case 3:
          parse.deviceNo = data;
          parse.headCount++;
          parse.buffer.add(data);
          break;
      }
    } else {
      if (parse.dataCount < (parse.len - 3)) {
        parse.buffer.add(data);
        parse.dataCount++;
      } else {
        List<int> bufData = parse.buffer.sublist(0, parse.len - 2);
        parse.bcc = getCurrentCheckSum(parse, bufData, bufData.length);
        if (parse.bcc == data) {
          parse.headCount = 0;
          parse.dataCount = 0;
          return true;
        } else {
          parse.headCount = 0;
          parse.dataCount = 0;
          return false;
        }
      }
    }
    return false;
  }

  int parseStdBuffer(ParseData parse, List<int> buffer)
  {
    int result = 0;
    try {
      for (int i = 0; i < buffer.length; i++) {
        if (parseStd(parse, buffer[i])) {
          int length = parse.bufferLen[0];
          List<int> readData = parse.buffer.sublist(0, length - 2);
          parseDataInital(parseSingleVar);
          parseDataInital(parseMultipleVar);
          switch (parse.cmd) {
            case DisCommand.DIS_SET_SINGLE_PARA:
            case DisCommand.DIS_READ_VERSION:
            case DisCommand.DIS_READ_TAG_DATA:
            case DisCommand.DIS_FAST_WRITE:
            case DisCommand.DIS_WRITE_TAG_DATA:
            case DisCommand.DIS_LOCK_TAG:
            case DisCommand.DIS_UNLOCK_TAG:
            case DisCommand.DIS_KILL_TAG:
            case DisCommand.DIS_INIT_TAG:
            case DisCommand.DIS_GET_SINGLE_PARA:
            case DisCommand.DIS_GET_MULTI_PARA:
            case DisCommand.DIS_TAG_AUTHER:
            case DisCommand.DIS_SET_AUTHERPWD:
            case DisCommand.DIS_READ_SINGLE_TAG:
            case DisCommand.DIS_MULTIPLY_BEGIN:
            case DisCommand.DIS_INV_MULTIPLY_END:
            case DisCommand.DIS_SET_BEEP:
            case DisCommand.DIS_WRITE_TAG_MULTI_WORD:
              mapData[parse.cmd] = ReceiveData(parse.cmd, length, readData, communicationMode);
              //Log.d(DataConvert.bytesToHexString(readData), DataConvert.bytesToHexString(parse.cmd) + "解析发送");
              result = (i + 1);
              break;
          }
        }
      }
      return result;
    } on Exception catch (e) {
      e.toString();
    }
    return result;
  }

  Map<String, String> filterData(List<int> readData)
  {
    Map<String, String> filter = Map<String, String>();
    String deviceId = readData[0].toString();
    int length = 0;
    int start = 0;
    if (isMultiple) {
      length = readData[1];
      start = 2;
    } else {
      length = 12;
      start = 1;
    }
    List<int> epc = List.generate(length, (index) => 0);
    arrayCopy(readData, start, epc, 0, length);
    String EPC = bytesToHexString(epc);
    String ant;
    if (isMultiple) {
      ant = readData[readData.length - 1].toString();
    } else {
      ant = readData[readData.length - 2].toString();
    }
    filter["deviceId"] = deviceId;
    filter["EPC"] = EPC;
    filter["ant"] = ant;
    filter["communicationMode"] = communicationMode;
    return filter;
  }

  bool parseMultiple(ParseData parse, int data, int index)
  {
    if(index == 0){
      parse.headCount = 0;
      //parse.dataCount = 0;
    }
    if (parse.headCount < 3) {
      switch (parse.headCount) {
        case 0:
          if (data == 0) {
            parse.startcode = data;
            parse.headCount++;
          } else {
            parse.headCount = 0;
            parse.dataCount = 0;
          }
          break;
        case 1:
          parse.headCount++;
          parse.deviceNo = data;
          parse.buffer.clear();
          parse.buffer.add(data);
          break;
        case 2:
          parse.len = data;
          parse.bufferLen.clear();
          parse.bufferLen.add(data);
          parse.buffer.add(data);
          parse.headCount++;
          break;
      }
    }
    else if (parse.dataCount < parse.len) {
      parse.buffer.add(data);
      parse.dataCount++;
    } else if (parse.dataCount < parse.len + 1) {
      parse.buffer.add(data);
      parse.dataCount++;
    } else {
      List<int> bufData = [];
      List<int> backup = [];
      try{
        for(int i = 0; i < 50; i++){
          parse.buffer.add(0);
        }
        backup = parse.buffer;
        bufData = parse.buffer.sublist(0, parse.len + 3);
      }catch(e){
        print(e);
        backup.add(data);
        bufData = backup.sublist(0, parse.len + 3);
      }
      parse.bcc = getCheckSum(bufData, bufData.length);
      if (parse.bcc == data) {
        isMultiple = true;
        parse.headCount = 0;
        parse.dataCount = 0;
        return true;
      } else {
        parse.headCount = 0;
        parse.dataCount = 0;
        return false;
      }
    }
    return false;
  }

  void parseMultipleBuffer(ParseData parse, List<int> buffer, Function(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) result)
  {
    Map<String, String> map;
    // if(buffer[0] == 103 && buffer[1] == -1){
    //   buffer.removeAt(0);
    //   buffer.removeAt(1);
    // }
    try {
      for (int i = 0; i < buffer.length; i++) {
        if (parseMultiple(parse, buffer[i], i)) {
          isMultiple = true;
          int length = parse.bufferLen[0];
          List<int> readData = parse.buffer.sublist(0, length + 3);
          parseDataInital(parseSingleVar);
          parseDataInital(parseStdVar);
          parseDataInital(parseTemperatureVar);
          map = filterData(readData);
          result(map["EPC"]!, map["ant"]!, map["deviceId"]!, map["communicationMode"]!, null);
        }
      }
    } on Exception catch (e) {
      e.toString();
    } finally {
    }
  }

  bool parseSingle(ParseData parse, int data)
  {
    if (parse.headCount < 2) {
      switch (parse.headCount) {
        case 0:
          if (data == 0) {
            parse.bufferLen.clear();
            parse.buffer.clear();
            parse.startcode = data;
            parse.headCount++;
          } else {
            parse.headCount = 0;
            parse.dataCount = 0;
          }
          break;
        case 1:
          parse.deviceNo = data;
          parse.len = 12;
          parse.bufferLen.add(12);
          parse.buffer.add(data);
          parse.headCount++;
          break;
      }
    } else if (parse.dataCount < parse.len + 1) {
      parse.buffer.add(data);
      parse.dataCount++;
    } else {
      List<int> bufData = parse.buffer.sublist(0, parse.len + 2);
      parse.bcc = checkSum(bufData,0,bufData.length);
      if (parse.bcc == data) {
        isSingle = true;
        parse.headCount = 0;
        parse.dataCount = 0;
        return true;
      } else {
        parse.headCount = 0;
        parse.dataCount = 0;
        return false;
      }
    }
    return false;
  }

  void parseSingleBuffer(ParseData parse, List<int> buffer, Function(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) result)
  {
    Map<String, String> map;
    try {
      for (int i = 0; i < buffer.length; i++) {
        if (parseSingle(parse, buffer[i])) {
          isSingle = true;
          int length = parse.bufferLen[0];
          List<int> readData = parse.buffer.sublist(0, length + 3);
          parseDataInital(parseMultipleVar);
          parseDataInital(parseStdVar);
          parseDataInital(parseTemperatureVar);
          map = filterData(readData);
          result(map["EPC"]!, map["ant"]!, map["deviceId"]!, map["communicationMode"]!, null);
        }
      }
    } on Exception catch (e) {
      e.toString();
    } finally {
    }
  }

  bool parseTemperature(ParseData parse, int data)
  {
    if (parse.headCount < 3) {
      switch (parse.headCount) {
        case 0:
          if (data == 0) {
            parse.startcode = data;
            parse.headCount++;
          } else {
            parse.headCount = 0;
            parse.dataCount = 0;
          }
          break;
        case 1:
          parse.bufferLen.clear();
          parse.buffer.clear();
          parse.deviceNo = data;
          parse.buffer.add(data);
          parse.headCount++;
          break;
        case 2:
          String strLen = HEX.encode([data]);
          if (isDecimal(strLen)) {
            int len = data;
            if (len == 18) {
              parse.len = len;
              parse.bufferLen.add(data);
              parse.buffer.add(data);
              parse.headCount++;
            } else {
              parse.headCount = 0;
              parse.dataCount = 0;
            }
          } else {
            parse.headCount = 0;
            parse.dataCount = 0;
          }
          break;
      }
    } else if (parse.dataCount < parse.len - 2) {
      parse.buffer.add(data);
      parse.dataCount++;
    } else {
      List<int> bufData = parse.buffer.sublist(0, parse.len);
      int bcc = getCheckSum(bufData,bufData.length);
      if (bcc == data) {
        parse.headCount = 0;
        parse.dataCount = 0;
        return true;
      } else {
        parse.headCount = 0;
        parse.dataCount = 0;
        return false;
      }
    }
    return false;
  }

  void parseTemperatureBuffer(ParseData parse, List<int> buffer, Function(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) result)
  {
    Map<String, String> map;
    try {
      for (int i = 0; i < buffer.length; i++) {
        if (parseTemperature(parse, buffer[i])) {
          isTemperature = true;
          int length = parse.bufferLen[0];
          List<int> readData = parse.buffer.sublist(0, length);
          parseDataInital(parseMultipleVar);
          parseDataInital(parseStdVar);
          parseDataInital(parseSingleVar);
          map = filterDataTemperature(readData);
          result(map["EPC"]!, map["ant"]!, map["deviceId"]!, map["communicationMode"]!, map["temperature"]);
        }
      }
    } on Exception catch (e) {
      e.toString();
    } finally {
    }
  }

  Map<String, String> filterDataTemperature(List<int> readData)
  {
    Map<String, String> filter = Map<String, String>();
    String deviceId = readData[0].toString();
    int length = 12;
    List<int> temers = List.generate(2, (index) => 0);
    String rssi = HEX.encode([readData[2]]);
    arrayCopy(readData, 3, temers, 0, 2);
    StringBuffer temper = StringBuffer();
    String temp1 = temers[0].toString();
    String temp2 = temers[1].toString();
    temper.write(temp1);
    temper.write(".");
    temper.write(temp2);
    List<int> epc = List.generate(length, (index) => 0);
    arrayCopy(readData, 5, epc, 0, 12);
    String EPC = bytesToHexString(epc);
    String ant = readData[readData.length - 1].toString();
    filter["deviceId"] = deviceId;
    filter["rssi"] = rssi;
    filter["temperature"] = temper.toString();
    filter["communicationMode"] = communicationMode;
    filter["EPC"] = EPC;
    filter["ant"] = ant;
    return filter;
  }

  void parseBuffer(List<int> buffer, Function(String data, String antennaNo, String deviceNo, String communicationMode, String? temperature) resultF)
  {
    List<int> dest;
    int result = parseStdBuffer(parseStdVar, buffer);
    if ((result > 0) && (buffer.length >= result)) {
      dest = List.generate(buffer.length - result, (index) => 0);
      if (dest.length >= 0) {
        arrayCopy(buffer, result, dest, 0, dest.length);
        buffer = dest;
      }
    }
    if (buffer.isEmpty) {
      return;
    }
    if (((!isMultiple) && (!isSingle)) && (!isTemperature)) {
      parseMultipleBuffer(parseMultipleVar, buffer, resultF);
      if (!isMultiple) {
        parseSingleBuffer(parseSingleVar, buffer, resultF);
      }
      if (!isTemperature) {
        parseTemperatureBuffer(parseTemperatureVar, buffer, resultF);
      }
    } else {
      if (isMultiple) {
        parseMultipleBuffer(parseMultipleVar, buffer, resultF);
      } else {
        if (isSingle) {
          parseSingleBuffer(parseSingleVar, buffer, resultF);
        } else {
          if (isTemperature) {
            parseTemperatureBuffer(parseTemperatureVar, buffer, resultF);
          }
        }
      }
    }
  }

  void parseDataInital(ParseData parseData)
  {
    parseData.headCount = 0;
    parseData.dataCount = 0;
    parseData.buffer = [];
    parseData.bufferLen = [];
  }


}