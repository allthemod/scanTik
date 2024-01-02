library smartscan.scanModes.school;

import 'package:flutter/material.dart';

import '../main.dart';
import '../resultPanel.dart';

void scanBag(BuildContext context){
  writeToFile("mode.txt", "school");
  Navigator.push(context, MaterialPageRoute(builder: (_) {
    return const result();
  },));
}


class SchoolScan extends StatelessWidget {
  const SchoolScan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: popMyAppBar(context),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        child: IconButton(
                          icon: Image.asset(
                            'lib/drawable/school/schoolbag.png',
                            fit: BoxFit.fill,
                          ), onPressed: () => scanBag(context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Scan Bag',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        child: IconButton(
                          icon: Image.asset(
                            'lib/drawable/school/folders.png',
                            fit: BoxFit.fill,
                          ),
                          onPressed: () {  },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Scan Folder',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        child: IconButton(
                          icon: Image.asset(
                            'lib/drawable/school/locker.png',
                            fit: BoxFit.fill,
                          ),
                          onPressed: () {

                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Scan Locker',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}