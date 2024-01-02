library smartscan.strings;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';


const String appName = "scanTik";
const Color secondaryColors = Color.fromARGB(255, 8, 100, 252);
const Color lightSecondaryColors = Color.fromARGB(100, 8, 100, 252);
double width = 0;
double height = 0;
double dpWidth = 0;
double dpHigh = 0;
double ratio = 0;
// = getApplicationDocumentsDirectory() as Directory
Directory? mainDir;
List<String> types = ["school", "personal", "medical"];
const List<String> typesC = ["school", "personal", "medical"];
bool Ad = true;