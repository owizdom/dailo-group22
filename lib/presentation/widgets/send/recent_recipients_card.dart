import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/recipient.dart';
import '../../cubits/recipients_cubit.dart';
import '../common/empty_state.dart';
import '../common/recipient_tile.dart';
import '../common/section_card.dart';

/// Figma 6, second card: the Recents and Favorites tabs, up to five saved
/// recipients, and a View All button.
class RecentRecipientsCard extends StatefulWidget {
  const RecentRecipientsCard({
    super.key,
    required this.onPick,
    required this.onViewAll,
  });

  final ValueChanged<Recipient> onPick;
  final VoidCallback onViewAll;

  @override
  State<RecentRecipientsCard> createState() => _RecentRecipientsCardState();
}

class _RecentRecipientsCardState extends State<RecentRecipientsCard> {
  static const _maxShown = 5;

  /// 0 is Recents, 1 is Favorites.
  final ValueNotifier<int> _tab = ValueNotifier(0);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: ValueListenableBuilder<int>(
        valueListenable: _tab,
        builder: (context, selected, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      key: K.sendTabRecents,
                      label: context.s.recents,
                      selected: selected == 0,
                      onTap: () => _tab.value = 0,
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      key: K.sendTabFavorites,
                      label: context.s.favorites,
                      selected: selected == 1,
                      onTap: () => _tab.value = 1,
                    ),
                  ),
                ],
              ),
              BlocBuilder<RecipientsCubit, RecipientsState>(
                builder: (context, state) {
                  final all = selected == 0 ? state.recents : state.favorites;
                  return _RecipientList(
                    recipients: all.take(_maxShown).toList(),
                    emptyMessage: selected == 0
                        ? context.s.noRecents
                        : context.s.noFavorites,
                    onPick: widget.onPick,
                  );
                },
              ),
              Center(
                child: TextButton(
                  key: K.sendViewAll,
                  onPressed: widget.onViewAll,
                  child: Text(context.s.sendViewAll),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One tab title with an underline when it is the chosen tab.
class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : context.palette.mutedText;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RecipientList extends StatelessWidget {
  const _RecipientList({
    required this.recipients,
    required this.emptyMessage,
    required this.onPick,
  });

  final List<Recipient> recipients;
  final String emptyMessage;
  final ValueChanged<Recipient> onPick;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return EmptyState(
        key: K.sendListEmpty,
        icon: Icons.people_outline,
        message: emptyMessage,
      );
    }
    return Column(
      key: K.sendList,
      children: [
        for (final recipient in recipients)
          RecipientTile(
            key: K.recipientTile(recipient.id),
            recipient: recipient,
            onTap: () => onPick(recipient),
          ),
      ],
    );
  }
}
