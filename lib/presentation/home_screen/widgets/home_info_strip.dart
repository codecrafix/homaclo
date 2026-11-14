import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';
import '../../../widgets/tap_scale.dart';
import 'web_tokens.dart';

/// Location + coin balance row shown at the top of Home, under the shared
/// website header. Replaces the old dark Home header (same data, same
/// location sheet, website colours in light and dark mode).
class HomeInfoStrip extends StatelessWidget {
  const HomeInfoStrip({super.key});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LocationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loading = app.locationLoading;
    final denied = app.locationPermissionDenied;
    final loc = app.liveLocation;

    String text;
    if (loading) {
      text = 'Fetching location...';
    } else if (denied) {
      text = 'Enable GPS / Retry';
    } else if (loc.isNotEmpty) {
      text = loc.split(',').take(2).map((s) => s.trim()).join(', ');
    } else {
      text = 'Set Location';
    }
    final accent = denied ? const Color(0xFFF59E0B) : WT.teal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TapScale(
              scale: 0.98,
              onTap: () {
                if (denied) {
                  app.fetchAndSaveLocation();
                } else {
                  _openSheet(context);
                }
              },
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: WT.sf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: denied ? accent : WT.line),
                ),
                child: Row(
                  children: [
                    loading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: WT.teal,
                            ),
                          )
                        : Icon(
                            denied
                                ? Icons.location_off_rounded
                                : Icons.location_on_rounded,
                            color: accent,
                            size: 17,
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WT.sans(
                          13.5,
                          color: denied ? accent : WT.ink,
                          w: FontWeight.w700,
                          h: 1.2,
                        ),
                      ),
                    ),
                    if (!loading)
                      Icon(
                        denied
                            ? Icons.refresh_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: WT.mut,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: WT.sf,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WT.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  '${app.coinBalance}',
                  style: WT.sans(14, w: FontWeight.w800, h: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      // The floating bottom navigation bar sits above this sheet, so leave
      // room under the content (otherwise the Refresh button is hidden).
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 112,
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
