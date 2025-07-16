import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FacebookWebViewAuth extends StatefulWidget {
  const FacebookWebViewAuth({super.key});

  @override
  _FacebookWebViewAuthState createState() => _FacebookWebViewAuthState();
}

class _FacebookWebViewAuthState extends State<FacebookWebViewAuth> {
  late WebViewController _controller;
  String? accessToken;

  final String appId = '1903610109953807';
  final String redirectUri = 'https://www.facebook.com/connect/login_success.html';
  final String scope = 'email,public_profile';

  @override
  void initState() {
    super.initState();

    // Khởi tạo WebView platform
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            _handleUrlChange(change.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildAuthUrl()));

    _controller = controller;
  }

  String _buildAuthUrl() {
    return 'https://www.facebook.com/v18.0/dialog/oauth?'
        'client_id=$appId&'
        'redirect_uri=$redirectUri&'
        'scope=$scope&'
        'response_type=token';
  }

  void _handleUrlChange(String? url) {
    if (url != null && url.contains('access_token=')) {
      final uri = Uri.parse(url);
      final params = Uri.splitQueryString(uri.fragment);
      final token = params['access_token'];

      if (token != null) {
        setState(() {
          accessToken = token;
        });
        _getUserInfo(token);
      }
    }
  }

  Future<void> _getUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/me?fields=id,name,email&access_token=$token'),
      );

      if (response.statusCode == 200) {
        final userInfo = json.decode(response.body);
        print('User info: $userInfo');

        // Xử lý thông tin user
        Navigator.of(context).pop({
          'token': token,
          'userInfo': userInfo,
        });
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facebook Login'),
        backgroundColor: Colors.blue,
      ),
      body: accessToken == null
          ? WebViewWidget(controller: _controller)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('Login successful!'),
                  SizedBox(height: 8),
                  Text('Token: ${accessToken?.substring(0, 20)}...'),
                ],
              ),
            ),
    );
  }
}
