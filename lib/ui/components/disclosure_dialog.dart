import 'package:afk_redeem/data/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/image_manager.dart';
import 'package:afk_redeem/data/preferences.dart';

Widget disclosureDialog(BuildContext context) {
  return WillPopScope(
    onWillPop: () {
      // prevent close using 'back' button
      return false as Future<bool>;
    },
    child: AlertDialog(
      title: Text('Disclosure'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'AFK Redeem is a fan-app and is not affiliated with ',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                TextSpan(
                  text: 'Lilith Games',
                  style: TextStyle(color: AppearanceManager().color.main),
                ),
                TextSpan(
                  text: ' in any way.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                TextSpan(text: '\n\n'),
                TextSpan(
                  text:
                      'This app anonymously collects basic analytics & crash reports.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                TextSpan(text: '\n\n'),
                TextSpan(
                  text: 'For more information visit the github project.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: ImageManager().get('github_icon'),
                  height: 20,
                  width: 20,
                ),
                SizedBox(
                  width: 5.0,
                ),
                Text(
                  'github.com/afkredeem',
                  style: TextStyle(
                    color: AppearanceManager().color.mainBright,
                    fontSize: 16.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () => launch(kLinks.githubProject),
            splashColor: AppearanceManager().color.mainBright,
          ),
          SizedBox(
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  SystemChannels.platform
                      .invokeMethod<void>('SystemNavigator.pop', true);
                },
                child: Text(
                  'Get me out',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Preferences().wasDisclosureApproved = true;
                  Navigator.pop(context); // pop this dialog
                },
                child: Text(
                  '     OK     ',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
