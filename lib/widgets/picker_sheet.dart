import 'package:flutter/material.dart';

import '../presentation/home_screen/widgets/web_tokens.dart';

/// Full list picker (like the website's select list). Opens above the floating
/// bottom bar, scrolls, and never hides an option.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _OptionSheet(title: title, options: options, selected: selected),
  );
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.82;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: WT.sf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WT.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: WT.serif(19))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: WT.mut),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: WT.line),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: WT.line),
                itemBuilder: (context, i) {
                  final o = options[i];
                  final on = o == selected;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(o),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o,
                              style: WT.sans(
                                15,
                                w: on ? FontWeight.w800 : FontWeight.w500,
                                h: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            on
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: on ? WT.teal : WT.mut,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
