import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/home_screen/widgets/web_tokens.dart';
import '../providers/app_state.dart';

/// Opens the live-location sheet (full current address + refresh).
/// It uses the root navigator, so it sits above the floating bottom bar and
/// nothing is hidden behind it.
void showLocationSheet(BuildContext context) {
  final app = context.read<AppState>();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: const _LocationSheet(),
    ),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    setState(() => _refreshing = true);
    await app.fetchAndSaveLocation();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final location = app.liveLocation;
    final denied = app.locationPermissionDenied;

    return Container(
      decoration: BoxDecoration(
        color: WT.sf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: WT.teal, size: 22),
              const SizedBox(width: 8),
              Text('Live Location', style: WT.serif(20)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WT.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WT.line, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT ADDRESS',
                  style: WT.sans(
                    10.5,
                    color: WT.mut,
                    w: FontWeight.w700,
                    ls: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  denied
                      ? 'Location permission denied. Tap Refresh to retry.'
                      : (location.isNotEmpty
                            ? location
                            : 'Location not yet fetched'),
                  style: WT.sans(
                    14,
                    color: denied ? const Color(0xFFF59E0B) : WT.ink,
                    w: FontWeight.w600,
                    h: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WBtn(
            _refreshing ? 'Refreshing...' : 'Refresh Live Location',
            onTap: () {
              if (!_refreshing) _refresh();
            },
          ),
        ],
      ),
    );
  }
}
