import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:mp3_music_converter/database/hive_boxes.dart';
import 'package:mp3_music_converter/screens/dashboard/main_dashboard.dart';
import 'package:mp3_music_converter/screens/login/sign_in_screen.dart';
import 'package:mp3_music_converter/utils/helper/instances.dart';
import 'package:mp3_music_converter/utils/page_router/navigator.dart';
import 'package:provider/provider.dart';
import 'common/providers.dart';
import 'utils/color_assets/color.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await FirebaseDatabase.instance.setPersistenceCacheSizeBytes(100000000);
  await FirebaseDatabase.instance.setPersistenceEnabled(true);
  var path = Directory.current.path;
  Hive.init(path);
  await PgHiveBoxes.init();

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: AppColor.red));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // WidgetsBinding.instance.addObserver(LifeCycleHandler());

    // print('man man man');
    return MultiProvider(
      providers: Providers.getProviders,
      child: MaterialApp(
        title: 'YT Audio',
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: AudioServiceWidget(child: Wrapper()),
        routes: Routes.getRoutes,
      ),
    );
  }
}

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  String email;
  bool newUser;

  openBox() async {
    await Hive.openBox('task');
  }

  @override
  void initState() {
    openBox();
    getEmail();

    super.initState();
  }

  getEmail() async {
    newUser = await preferencesHelper.doesExists(key: 'email');
    email =
        !newUser ? "" : await preferencesHelper.getStringValues(key: 'email');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (email == null)
      return SpinKitCircle(
        itemBuilder: (BuildContext context, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
                color: index.isEven ? AppColor.white : AppColor.background,
                shape: BoxShape.circle),
          );
        },
      );
    if (email == "") return SignInScreen();
    return MainDashBoard();
  }
}

// class LifeCycleHandler extends WidgetsBindingObserver {
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         print('resumed');
//         break;
//       case AppLifecycleState.inactive:
//         print('inactive');
//         break;
//       case AppLifecycleState.paused:
//         print('paused');
//         break;
//       case AppLifecycleState.detached:
//         print('detached');
//         break;
//     }
//   }
// }
