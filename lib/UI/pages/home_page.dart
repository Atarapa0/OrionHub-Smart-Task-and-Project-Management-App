import 'package:flutter/material.dart';
import 'package:todo_list/core/consants/color_file.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  double offsetY = 0; // Container'ların dikey hareketi
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu), // Sol tarafta menü butonu
          onPressed: () {
            // Menü sayfasına gitme işlemi
          },
        ),
        title: Text('TaskNest'),
        backgroundColor: ColorFile.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Sağ tarafta ayarlar butonu
            onPressed: () {
              // Ayarlar sayfasına gitme işlemi
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.2,
                      color: ColorFile.loveColor,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                  color: ColorFile.starColor,
                                  child: Column(
                                    children: [
                                      Text('Başlık & Görevler'),
                                      Text('Not içenriği'),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                  color: ColorFile.starColor,
                                  child: Column(
                                    children: [
                                      Text('Başlık & Görevler'),
                                      Text('Not içeği'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ), //Dönen notlar yada görevler olan Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.05,
                      color: ColorFile.starColor,
                      child: Column(
                        children: [
                          Text('3 seçenekli bar'),
                          
                        ],
                      ),
                    ),
                  ],
                ),
                /*Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height/50),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: ColorFile.backgroundColor,
                      child: Column(
                        children: [
                          Text('Tasklar olacak '),
                        ],
                      ),
                    ),
                  ],
                ),*/
              ],
            ),
          )
        ],
      ),
    );
  }
}
