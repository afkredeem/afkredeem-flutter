import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/services/afk_redeem_api.dart';
import 'package:flutter/material.dart';

import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/image_manager.dart';
import 'package:afk_redeem/ui/components/html_renderer.dart';

Future<AlertDialog> aboutDialog(
    BuildContext context, AfkRedeemApi afkRedeemApi) async {
  String? html = await HtmlRenderer.getHtml(
    context: context,
    uri: kFlutterHtmlUri.about,
    afkRedeemApi: afkRedeemApi,
  );
  return AlertDialog(
    title: Text(HtmlRenderer.getTitle(html) ?? 'About'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HtmlRenderer.render(context, html) ??
            Text(
              'It appears there\'s a connection problem',
              style: TextStyle(color: AppearanceManager().color.red),
            ),
        SizedBox(
          height: 40.0,
        ),
        Text(
          'Old Player',
          style:
              TextStyle(color: AppearanceManager().color.main, fontSize: 14.0),
        ),
        SizedBox(
          height: 5.0,
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Dru**ed',
                style: TextStyle(fontSize: 14.0),
              ),
              Container(
                child: ImageManager().get('dragon'),
                height: 25.0,
                width: 25.0,
              ),
              Text(
                'Dragons',
                style: TextStyle(fontSize: 14.0),
              )
            ]),
      ],
    ),
  );
}
