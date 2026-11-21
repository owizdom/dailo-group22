import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../widgets/common/header_banner.dart';
import '../../widgets/home/action_grid.dart';
import '../../widgets/home/fade_slide_in.dart';
import '../../widgets/home/recent_transactions_card.dart';

/// Figma 5. Welcome banner, four actions, recent transactions, feedback link.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return Scaffold(
      body: SafeArea(
        // Pinned to the top like the Figma; centred only left to right.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    child: Stack(
                      children: [
                        HeaderBanner.card(
                          title: strings.homeWelcome,
                          subtitle: strings.tagline,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            key: K.homeSettings,
                            tooltip: strings.homeSettingsTooltip,
                            color: Colors.white,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.settings),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.gap),
                  const FadeSlideIn(order: 1, child: ActionGrid()),
                  const SizedBox(height: AppSizes.gap),
                  const FadeSlideIn(order: 2, child: RecentTransactionsCard()),
                  const SizedBox(height: AppSizes.gap),
                  Center(
                    child: TextButton(
                      key: K.homeFeedback,
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.feedback),
                      child: Text(
                        strings.homeFeedbackLink,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
