import 'dart:io';

import 'package:mp3_music_converter/database/model/song.dart';
import 'package:mp3_music_converter/playlist/create_playlist_screen.dart';
import 'package:mp3_music_converter/playlist/select_playlist_screen.dart';
import 'package:mp3_music_converter/screens/converter/show_download_dialog.dart';
import 'package:mp3_music_converter/screens/payment/payment_screen.dart';
import 'package:mp3_music_converter/screens/split/split_loader.dart';
import 'package:mp3_music_converter/utils/helper/helper.dart';
import 'package:mp3_music_converter/utils/helper/instances.dart';
import 'package:mp3_music_converter/utils/utilFold/splitAssistant.dart';
import 'package:mp3_music_converter/widgets/progress_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mp3_music_converter/screens/song/provider/music_provider.dart';
import 'package:mp3_music_converter/utils/color_assets/color.dart';
import 'package:mp3_music_converter/utils/page_router/navigator.dart';
import 'package:mp3_music_converter/utils/string_assets/assets.dart';
import 'package:mp3_music_converter/widgets/text_view_widget.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import '../utils/color_assets/color.dart';
import '../utils/page_router/navigator.dart';
import 'package:mp3_music_converter/screens/split/delete_song.dart';
import 'package:mp3_music_converter/screens/downloads/downloads.dart';

const String splitMusicPath = 'split';

class AppDrawer extends StatefulWidget with WidgetsBindingObserver {
  final TargetPlatform platform;

  AppDrawer({
    Key key,
    this.platform,
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  List<String> _apiSplitList = ['', ''];
  MusicProvider _musicProvider;
  int id;
  bool _permissionReady;
  static String _localPath;
  bool shuffle;
  bool repeat;
  Song drawerSong;

  @override
  void initState() {
    _musicProvider = Provider.of<MusicProvider>(context, listen: false);

    drawerSong = _musicProvider.drawerItem;
    _permissionReady = false;
    _prepare();
    shuffle = _musicProvider.shuffleSong;
    repeat = _musicProvider.repeatSong;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

// prepares the items we wish to download
  Future<Null> _prepare() async {
    _permissionReady = await _checkPermission(); // checks for users permission

    _localPath = (await _findLocalPath()) +
        Platform.pathSeparator +
        splitMusicPath; // gets users

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

//* finds available space for storage on users device
  Future<String> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    // return Consumer<MusicProvider>(
    //   builder: (_, _provider, __) {
    //     print(_musicProvider.drawerItem.songName);
    return Padding(
      padding: const EdgeInsets.only(top: 150, bottom: 120),
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(color: AppColor.black.withOpacity(0.5)),
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          width: 50,
                          child:
                              _musicProvider?.drawerItem?.artWork?.isNotEmpty ??
                                      false
                                  ? Image.memory(
                                      _musicProvider?.drawerItem?.artWork)
                                  : Image.asset('assets/new_icon.png',
                                      fit: BoxFit.cover),
                        ),
                      ),
                      _musicProvider?.drawerItem?.songName?.isNotEmpty ?? false
                          ? Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: TextViewWidget(
                                  text: _musicProvider?.drawerItem?.songName ??
                                      '',
                                  color: AppColor.white,
                                  textSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                subtitle: TextViewWidget(
                                  text:
                                      _musicProvider?.drawerItem?.artistName ??
                                          '',
                                  color: AppColor.white,
                                  textSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : Container()
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => _musicProvider.updateSong(_musicProvider
                          .drawerItem
                        ..favorite =
                            _musicProvider.drawerItem.favorite ? false : true),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            AppAssets.favorite,
                            height: 20.8,
                            color: _musicProvider.drawerItem.favorite
                                ? AppColor.red
                                : AppColor.white,
                          ),
                          TextViewWidget(
                            text: 'Favorite',
                            color: AppColor.white,
                          )
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        shuffle
                            ? _musicProvider.stopShuffle()
                            : _musicProvider.shuffle(false);
                        PageRouter.goBack(context);
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            AppAssets.shuffle,
                            color:
                                shuffle ? AppColor.bottomRed : AppColor.white,
                          ),
                          TextViewWidget(text: 'Shuffle', color: AppColor.white)
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        repeat
                            ? _musicProvider.undoRepeat()
                            : _musicProvider.repeat(_musicProvider.drawerItem);
                        PageRouter.goBack(context);
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(AppAssets.repeat,
                              color:
                                  repeat ? AppColor.bottomRed : AppColor.white),
                          TextViewWidget(text: 'Repeat', color: AppColor.white)
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        PageRouter.goBack(context);
                        Share.shareFiles([
                          File('${_musicProvider.drawerItem.filePath}/${_musicProvider.drawerItem.fileName}')
                              .path
                        ]);
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(AppAssets.share),
                          TextViewWidget(text: 'Share', color: AppColor.white)
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: AppColor.white,
                ),
                ListTile(
                  onTap: () => splitSongMethod(),
                  leading: SvgPicture.asset(AppAssets.split),
                  title: TextViewWidget(
                    text: 'Split Song',
                    color: AppColor.white,
                    textSize: 18,
                  ),
                ),
                Divider(
                  color: AppColor.white,
                ),
                Wrap(
                  children: [
                    ListTile(
                      onTap: () async {
                        await _musicProvider.getPlayListNames();
                        print(drawerSong.songName);
                        PageRouter.goBack(context);
                        _musicProvider.playLists.isEmpty
                            ? createPlayListScreen(
                                context: context,
                                musicid: drawerSong.musicid,
                                showToastMessage: true)
                            : selectPlayListScreen(
                                context: context,
                                songName: drawerSong.fileName,
                                musicid: drawerSong.musicid);
                      },
                      leading: Icon(
                        Icons.add_box_outlined,
                        color: AppColor.white,
                      ),
                      title: TextViewWidget(
                        text: 'Add to Playlist',
                        color: AppColor.white,
                        textSize: 18,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    Divider(
                      color: AppColor.white,
                    ),
                    ListTile(
                      onTap: () async {
                        Song song = _musicProvider?.drawerItem;
                        Navigator.pop(context);
                        showDownloadDialog(
                            context: context,
                            artist: song.artistName,
                            song: song.songName,
                            musicid: song.musicid,
                            download: false,
                            split: false);
                      },
                      leading: Icon(Icons.edit, color: AppColor.white),
                      title: TextViewWidget(
                        text: 'Rename Song',
                        color: AppColor.white,
                        textSize: 18,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Divider(
                        color: AppColor.white,
                      ),
                      ListTile(
                        onTap: () async {
                          if (_musicProvider?.drawerItem?.fileName ==
                              _musicProvider?.currentSong?.fileName) {
                            Navigator.pop(context);
                            showToast(context,
                                message: 'Cannot delete currently playing song',
                                backgroundColor: Colors.white,
                                textColor: Colors.black);
                          } else {
                            Navigator.pop(context);
                            DeleteSongs(context).showConfirmDeleteDialog(
                                song: _musicProvider?.drawerItem);
                          }
                        },
                        leading: SvgPicture.asset(AppAssets.rubbish),
                        title: TextViewWidget(
                          text: 'Delete Song',
                          color: AppColor.white,
                          textSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
    //   },
    // );
  }

  Future splitSongMethod() async {
    String userToken = await preferencesHelper.getStringValues(key: 'token');
    if ((_musicProvider.drawerItem.size / 1000000.0).ceil() <= 8) {
      showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black87,
          builder: (_) {
            return SplitLoader();
          });

      String result = '${_musicProvider.drawerItem.filePath}/'
          '${_musicProvider.drawerItem.fileName}';
      var splitFiles = await SplitAssistant.splitFile(
        filePath: result,
        userToken: userToken,
      );
      if (Provider.of<SplitLoaderProvider>(context, listen: false).isShowing)
        Navigator.pop(context);
      if (splitFiles['reply'] == "success") {
        Map splitData = await SplitAssistant.saveSplitFiles(
          decodedData: splitFiles['data'],
          userToken: userToken,
          artistName: _musicProvider?.drawerItem?.artistName,
          songName: _musicProvider?.drawerItem?.songName,
        );
        if (_permissionReady) {
          if (splitData['reply'] == 'success') {
            // showToast(context,
            //     message:
            //         'Song has been successfully split and saved to Library. If download fails, you can retry from the history page or use the sync button in Voice Over or Sing Along to pull your changes.',
            //     duration: 15,
            //     backgroundColor: Colors.blue[400],
            //     textColor: Colors.black);
            String voiceUrl = splitFiles['data']["voice"];
            String otherUrl = splitFiles['data']["other"];
            _apiSplitList = ['', ''];
            _apiSplitList.insert(0, otherUrl);
            _apiSplitList.insert(1, voiceUrl);
            Song newSong = _musicProvider?.drawerItem;
            newSong.musicid = splitFiles['data']['id'].toString();
            newSong.vocalLibid = splitData['data']['vocalid'];
            newSong.libid = splitData['data']['othersid'];

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Downloads(
                        apiSplitList: _apiSplitList,
                        localPath: _localPath,
                        song: newSong)));
          } else {
            showToast(context, message: splitData['data']);
          }
        } else {
          _buildNoPermissionWarning();
        }
      } else if (splitFiles['data'] ==
          'please subscribe to enjoy this service') {
        // await _progressIndicator.dismiss();
        showSubscriptionMessage(context);
      } else if (splitFiles['data'] == "insufficient storage") {
        // await _progressIndicator.dismiss();
        insufficientStorageWarning(context);
      } else {
        // await _progressIndicator.dismiss();
        showToast(context, message: 'An error occurred');
      }
    } else {
      showToast(context,
          message: 'File exceeds 8MB limit. Please select another file',
          duration: 6,
          gravity: 1,
          backgroundColor: Colors.red[700]);
    }
  }

  Widget _buildNoPermissionWarning() => Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Please grant accessing storage permission to continue -_-',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
                ),
              ),
              SizedBox(
                height: 32.0,
              ),
              TextButton(
                  onPressed: () {
                    _checkPermission().then((hasGranted) {
                      setState(() {
                        _permissionReady = hasGranted;
                      });
                    });
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0),
                  ))
            ],
          ),
        ),
      );
}

Future<void> showSubscriptionMessage(BuildContext context) {
  return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(40, 40, 40, 1),
          content: Text(
            'You need to subscribe to enjoy this service. \n\nSubscribe now?',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          actions: [
            TextButton(
              child: Text('No',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              onPressed: () {
                Navigator.pop(_);
              },
            ),
            TextButton(
              child: Text('Yes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PaymentScreen()));
              },
            ),
          ],
        );
      });
}

Future<void> insufficientStorageWarning(BuildContext context) {
  return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(40, 40, 40, 1),
          content: Text(
            'Available storage is insufficient. Please purchase an additional plan. \n\nBuy now?',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          actions: [
            TextButton(
              child: Text('No',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              onPressed: () {
                Navigator.pop(_);
              },
            ),
            TextButton(
              child: Text('Yes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PaymentScreen()));
              },
            ),
          ],
        );
      });
}

// Future<Widget> buildShareOptions(BuildContext context, {Song song}) {
//   return showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Color.fromRGBO(40, 40, 40, 1),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextButton(
//                 onPressed: () {
//                   showPrivateShareDialog(context, song);
//                   Navigator.pop(context);
//                 },
//                 child: Text(
//                   'Private share',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ),
//               Divider(
//                 color: Colors.white,
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => PublicShare(song.libid,
//                               vocalLibid: song.vocalLibid)));
//                 },
//                 child: Text(
//                   'Share to youtubeaudio.ca',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ),
//               Divider(
//                 color: Colors.white,
//               ),
//               TextButton(
//                 onPressed: () async {
//                   PageRouter.goBack(context);
//                   Share.shareFiles(
//                       [File('${song.filePath}/${song.fileName}').path]);
//                 },
//                 child: Text(
//                   'Share to other apps',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ),
//             ],
//           ),
//         );
//       });
// }
