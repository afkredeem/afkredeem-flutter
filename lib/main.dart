import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:afk_redeem/ui/components/app_builder.dart';
import 'package:afk_redeem/ui/screens/main_screen.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/data/preferences.dart';

void main() => runApp(AfkRedeemApp());

Future<void> initializeNonBlockingFutures() async {
  WidgetsFlutterBinding.ensureInitialized();
  // parallelize async operations
  await Future.wait([
    MobileAds.instance.initialize(),
    Firebase.initializeApp(),
  ]);
}

Future<Preferences> initializeBlockingFutures() async {
  return Preferences.create();
}

class AfkRedeemApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeNonBlockingFutures(); // no need to await (non-blocking)
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return FutureBuilder<Preferences>(
        future: initializeBlockingFutures(),
        builder: (BuildContext context, AsyncSnapshot<Preferences> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          AppearanceManager().applyTheme(
            isChristmas: snapshot.data!.isChristmasTime,
            isHypogean: snapshot.data!.isHypogean,
          );
          return AppBuilder(
            builder: (context) => MaterialApp(
              // debugShowCheckedModeBanner: false,
              title: 'AFK Redeem',
              theme: AppearanceManager().themeData(),
              home: MainScreen(),
            ),
          );
        });
  }
}
