import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import 'header_banner.dart';

/// The frame every inner screen shares: the title band, a Back row and a
/// scrolling body.
///
/// The body always scrolls, so a small phone or a phone turned sideways
/// never overflows. On wide screens the content stays 560 wide and centred.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.backLabel,
    this.showBack = true,
    this.bottom,
  });

  final String title;
  final List<Widget> children;

  /// Text next to the back arrow. Defaults to "Back".
  final String? backLabel;
  final bool showBack;

  /// A button pinned under the scrolling content, for example "Save".
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    // The band is navy, so the clock and battery icons above it are light.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // Full width, and painted up to the top edge so the navy runs under
            // the status bar as in the Figma. The inset keeps the title clear.
            SizedBox(
              width: double.infinity,
              child: HeaderBanner.bar(
                title: title,
                topInset: MediaQuery.paddingOf(context).top,
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.pagePadding),
                      children: [
                        if (showBack)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(backLabel ?? context.s.back),
                            ),
                          ),
                        ...children,
                        if (bottom != null) ...[
                          const SizedBox(height: AppSizes.gap),
                          bottom!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
