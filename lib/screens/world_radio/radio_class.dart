import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mp3_music_converter/screens/dashboard/main_dashboard.dart';
import 'package:mp3_music_converter/screens/world_radio/model/radio_model.dart';
import 'package:mp3_music_converter/screens/world_radio/provider/radio_play_provider.dart';
import 'package:mp3_music_converter/screens/world_radio/provider/radio_provider.dart';
import 'package:mp3_music_converter/utils/color_assets/color.dart';
import 'package:mp3_music_converter/utils/helper/instances.dart';
import 'package:mp3_music_converter/utils/string_assets/assets.dart';
import 'package:mp3_music_converter/widgets/red_background.dart';
import 'package:mp3_music_converter/widgets/text_view_widget.dart';
import 'package:provider/provider.dart';

class RadioClass extends StatefulWidget {
  @override
  _RadioClassState createState() => _RadioClassState();
}

class _RadioClassState extends State<RadioClass>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  RadioProvider _radioProvider;
  bool tap = false, favTap = false;
  String radioFile = '', radioMp3 = '', radioFavMp3 = '', radioFavFile = '';
  bool isPlaying = false;
  bool isVisible = true;
  RadioPlayProvider _playProvider;

  @override
  void initState() {
    _radioProvider = Provider.of<RadioProvider>(context, listen: false);
    _radioProvider.init(context);
    _playProvider = Provider.of<RadioPlayProvider>(context, listen: false);
    _playProvider.getFavoriteRadio();

    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat();
    super.initState();
    if (radioFile.isEmpty && radioMp3.isEmpty) return;
    if (radioFile.isNotEmpty && radioMp3.isNotEmpty) {
      _playProvider.playAudio(radioMp3);
      init();
    }
  }

  init() {
    preferencesHelper
        .getStringValues(key: 'radiomp3')
        .then((value) => setState(() {
              radioMp3 = value;
            }));
    preferencesHelper
        .getStringValues(key: 'radioFile')
        .then((value) => setState(() {
              radioFile = value;
            }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: AppColor.background1,
      child: Column(
        children: [
          RedBackground(
            iconButton: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_outlined,
                color: AppColor.white,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainDashBoard()),
              ),
            ),
            text: 'Radio World Wide',
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: _controller.value * 2 * 3.145,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        AppAssets.globe,
                        height: 350,
                        width: 350,
                      )),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 45,
                        width: 230,
                        color: Colors.red[200],
                        child: Center(
                          child: TextViewWidget(
                            color: AppColor.white,
                            text: 'Lagos',
                          ),
                        ),
                      ),
                      tap == true
                          ? Container(
                              height: 340,
                              width: 230,
                              color: AppColor.black2,
                              child: (_radioProvider
                                              ?.radioModels?.radio?.length ??
                                          0) >
                                      0
                                  ? ListView.builder(
                                      itemCount: _radioProvider
                                              ?.radioModels?.radio?.length ??
                                          0,
                                      itemBuilder: (context, index) {
                                        var _radioLog = _radioProvider
                                            .radioModels.radio[index];
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              radioFile = _radioLog.name;
                                              radioMp3 = _radioLog.mp3;
                                              isPlaying = true;
                                            });
                                            preferencesHelper.saveValue(
                                                key: 'radiomp3',
                                                value: radioMp3);
                                            preferencesHelper.saveValue(
                                                key: 'radioFile',
                                                value: radioFile);
                                            _playProvider.playAudio(radioMp3);
                                          },
                                          child: Column(
                                            children: [
                                              TextViewWidget(
                                                text: _radioLog.name,
                                                color: AppColor.white,
                                                textSize: 16,
                                              ),
                                              Divider(
                                                  thickness: 1,
                                                  color: AppColor.white)
                                            ],
                                          ),
                                        );
                                      })
                                  : Center(
                                      child: Text(
                                        'No Station',
                                        style: TextStyle(color: AppColor.white),
                                      ),
                                    ),
                            )
                          : Container(),
                      favTap == true
                          ? Container(
                              height: 340,
                              width: 230,
                              color: AppColor.black2,
                              child: (_playProvider.favRadio.length ?? 0) > 0
                                  ? ListView.builder(
                                      itemCount: _playProvider.favRadio.length,
                                      itemBuilder: (context, index) {
                                        var _radioFav =
                                            _playProvider.favRadio[index];
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              radioFavFile = _radioFav.name;
                                              radioFavMp3 = _radioFav.mp3;
                                              isPlaying = true;
                                            });
                                            preferencesHelper.saveValue(
                                                key: 'radiomp3',
                                                value: radioMp3);
                                            preferencesHelper.saveValue(
                                                key: 'radioFile',
                                                value: radioFile);
                                            _playProvider.playAudio(radioMp3);
                                          },
                                          child: Column(
                                            children: [
                                              TextViewWidget(
                                                text: _radioFav.name,
                                                color: AppColor.white,
                                                textSize: 16,
                                              ),
                                              Divider(
                                                  thickness: 1,
                                                  color: AppColor.white)
                                            ],
                                          ),
                                        );
                                      })
                                  : Center(
                                      child: Text(
                                        'No Station',
                                        style: TextStyle(color: AppColor.white),
                                      ),
                                    ),
                            )
                          : Container(),
                      Container(
                        width: 230,
                        height: 50,
                        color: Colors.red[400],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  tap = !tap;
                                  favTap = false;
                                });
                              },
                              child: SvgPicture.asset(
                                AppAssets.bookmark,
                                height: 25,
                                width: 25,
                                color: tap == true
                                    ? AppColor.black
                                    : AppColor.white,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  favTap = !favTap;
                                  tap = false;
                                });
                              },
                              child: SvgPicture.asset(AppAssets.favourite,
                                  height: 25,
                                  width: 25,
                                  color: favTap == true
                                      ? AppColor.black
                                      : AppColor.white),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(color: AppColor.black2),
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextViewWidget(
                        text: '$radioFile',
                        color: AppColor.white,
                        textSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            IconButton(
                                icon: Icon(
                                  Icons.skip_previous_outlined,
                                  color: AppColor.white,
                                  size: 50,
                                ),
                                onPressed: () {}),
                            IconButton(
                              icon: isPlaying
                                  ? Icon(
                                      Icons.pause_circle_outline,
                                      size: 53,
                                      color: AppColor.white,
                                    )
                                  : Icon(
                                      Icons.play_circle_outline,
                                      color: AppColor.white,
                                      size: 53,
                                    ),
                              onPressed: () {
                                setState(() {
                                  isPlaying = !isPlaying;
                                });
                                _playProvider.playAudio(radioMp3);
                              },
                            ),
                            IconButton(
                                icon: Icon(
                                  Icons.skip_next_outlined,
                                  size: 50,
                                  color: AppColor.white,
                                ),
                                onPressed: () {}),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: Icon(
                            Icons.favorite_outlined,
                            size: 35,
                            color: _playProvider.favourite.favorite
                                ? AppColor.red
                                : AppColor.white,
                          ),
                          onPressed: () {
                            _playProvider.updateFavourite(
                                _playProvider.favourite
                                  ..favorite = _playProvider.favourite.favorite
                                      ? false
                                      : true);
                          }),
                      SizedBox(
                        width: 7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
