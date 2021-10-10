import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

import 'package:afk_redeem/data/services/afk_redeem_api.dart';
import 'package:afk_redeem/ui/components/loader_overlay.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';

class HtmlRenderer {
  static Map<String, String> lastRenderButtonLinks = {};

  static Future<String?> getHtml({
    required BuildContext context,
    required String uri,
    required AfkRedeemApi afkRedeemApi,
    bool? showLoadingOverlay,
  }) async {
    showLoadingOverlay ??= false;
    if (showLoadingOverlay) {
      LoaderOverlay.show(context);
    }

    String? html = await afkRedeemApi.getPage(uri);
    if (showLoadingOverlay) {
      LoaderOverlay.hide();
    }
    return html;
  }

  static Html render(BuildContext context, String html) {
    return tryRender(context, html)!;
  }

  static Html? tryRender(BuildContext context, String? html) {
    if (html == null) {
      return null;
    }
    lastRenderButtonLinks = {};
    return Html(
      data: html,
      onLinkTap: (String? url, RenderContext context,
          Map<String, String> attributes, dom.Element? element) {
        if (url != null) {
          launch(url);
        }
      },
      style: {
        "a": Style(
          color: AppearanceManager().color.main,
        ),
        "body": Style(
          color: AppearanceManager().color.dialogText,
        ),
      },
      customRender: {
        "color": (RenderContext context, Widget child) {
          String value = context.tree.element!.attributes['value']!;
          return Text(
            context.tree.element!.text,
            style: TextStyle(
              color: AppearanceManager().color.fromString[value] ??
                  Color(int.tryParse(value) ?? 0xFF000000),
            ),
          );
        },
        "button-link": (RenderContext context, Widget child) {
          var attributes = context.tree.element!.attributes;
          if (attributes['id'] != null && attributes['href'] != null) {
            lastRenderButtonLinks[attributes['id']!] = attributes['href']!;
          }
          return null;
        }
      },
      tagsList: Html.tags..addAll(["color", "button-link"]),
    );
  }

  static const String titleTag = '<title>';
  static const String closeTitleTag = '</title>';
  static String? getTitle(String? html) {
    if (html == null) {
      return null;
    }
    if (titleTag.length + closeTitleTag.length > html.length) {
      return null;
    }
    int start = html.indexOf(titleTag);
    int end = html.indexOf(closeTitleTag, start + titleTag.length);
    if (start == -1 || end == -1) {
      return null;
    }
    return html.substring(start + titleTag.length, end);
  }
}
