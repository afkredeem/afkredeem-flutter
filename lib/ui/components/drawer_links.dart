import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/ui/components/html_renderer.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/image_manager.dart';

Widget drawerLinks(BuildContext context, Future<String?> drawerHtml) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Column(
      children: [
        UnconstrainedBox(
          child: InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: ImageManager().get('app_circle'),
                  height: 20,
                  width: 20,
                ),
                SizedBox(
                  width: 5.0,
                ),
                Text(
                  'afkredeem.com',
                  style: TextStyle(
                    color: AppearanceManager().color.mainBright,
                    fontSize: 16.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () => launch(kLinks.afkRedeem),
            splashColor: AppearanceManager().color.mainBright,
          ),
        ),
        SizedBox(height: 10.0),
        UnconstrainedBox(
          child: InkWell(
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
        ),
        FutureBuilder<String?>(
            future: drawerHtml,
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return Container();
              }
              Widget? htmlWidget =
                  HtmlRenderer.tryRender(context, snapshot.data);
              if (htmlWidget == null) {
                return Container();
              }
              return htmlWidget;
            }),
      ],
    ),
  );
}
