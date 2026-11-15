import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';
import '../../../services/home_data_service.dart';
import '../../home_screen/widgets/web_header.dart' show showReferSheet;
import '../../home_screen/widgets/web_tokens.dart';

/// Refer & Earn section on the Profile page, same as the website profile:
/// personal link (copy / WhatsApp), four counters and the list of friends
/// with their status. Data comes from the same `my_referral_summary` RPC.
class ProfileReferralWidget extends StatefulWidget {
  const ProfileReferralWidget({super.key});

  @override
  State<ProfileReferralWidget> createState() => _ProfileReferralWidgetState();
}

class _ProfileReferralWidgetState extends State<ProfileReferralWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _copied = false;
  int? _lastCoins;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await HomeDataService.myReferralSummary();
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  int _n(String k) => (_data?[k] as num?)?.toInt() ?? 0;

  String _date(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
    if (d == null) return '';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _msg(String link) =>
      'Book professional water tank cleaning with Homaclo in Satna. Sign up with my link and we both get 50 coins after your first booking of ₹500 or more: $link';

  Widget _stat(String label, int value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: WT.bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: WT.line),
    ),
    child: Column(
      children: [
        Text('$value', style: WT.sans(22, w: FontWeight.w800, h: 1.2)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: WT.sans(12, color: WT.mut, h: 1.3),
        ),
      ],
    ),
  );

  Widget _pill(String status) {
    late final String text;
    late final Color c;
    switch (status) {
      case 'rewarded':
        text = 'Booked, +50 coins';
        c = WT.ok;
        break;
      case 'pending':
        text = 'Signed up, waiting to book';
        c = const Color(0xFFD97706);
        break;
      case 'rejected':
        text = 'Not eligible';
        c = WT.mut;
        break;
      default:
        text = status;
        c = WT.mut;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withAlpha(36),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: WT.sans(11.5, color: c, w: FontWeight.w800, h: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.isLoggedIn) return const SizedBox.shrink();

    // A reward changes the coin balance: reload the numbers when it moves.
    if (_lastCoins != null && _lastCoins != app.coinBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    _lastCoins = app.coinBalance;

    final code = _data?['code']?.toString() ?? '';
    final link = 'https://homaclo.in/?ref=$code';
    final items = (_data?['items'] as List?) ?? const [];
    final by = _data?['referred_by'];
    String? note;
    if (by is Map) {
      final s = by['status']?.toString();
      note = s == 'pending'
          ? 'You joined through a friend’s link. Make your first booking of ₹500 or more to get your 50 coins.'
          : s == 'rewarded'
          ? '🎉 You received 50 coins for joining through a friend’s link.'
          : 'Your referral reward was not eligible.';
    }

    return WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎁 Refer & Earn', style: WT.serif(20)),
          const SizedBox(height: 6),
          Text(
            'Earn 50 coins (₹50) for every friend who makes a first booking of ₹500 or more through your link. Your friend gets 50 coins too.',
            style: WT.sans(13.5, color: WT.mut, h: 1.5),
          ),
          const SizedBox(height: 14),
          if (_loading)
            Text(
              'Loading your referral details…',
              style: WT.sans(13.5, color: WT.mut),
            )
          else if (_data == null || code.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your referral details will appear here shortly.',
                  style: WT.sans(13.5, color: WT.mut),
                ),
                const SizedBox(height: 10),
                WBtn('Try again', small: true, ghost: true, full: false, onTap: () {
                  setState(() => _loading = true);
                  _load();
                }),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: WT.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WT.line, width: 1.5),
                    ),
                    child: Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WT.sans(13, w: FontWeight.w600, h: 1.2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                WBtn(
                  _copied ? 'Copied ✓' : 'Copy',
                  small: true,
                  full: false,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!mounted) return;
                    setState(() => _copied = true);
                    Future.delayed(const Duration(milliseconds: 1800), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                WBtn(
                  'WhatsApp',
                  small: true,
                  ghost: true,
                  full: false,
                  onTap: () => wOpen(
                    'https://wa.me/?text=${Uri.encodeComponent(_msg(link))}',
                  ),
                ),
                WBtn(
                  'How it works',
                  small: true,
                  ghost: true,
                  full: false,
                  onTap: () => showReferSheet(context),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(note, style: WT.sans(13, h: 1.45)),
            ],
            const SizedBox(height: 14),
            wGrid2([
              _stat('Friends joined', _n('invited')),
              _stat('Booked', _n('rewarded')),
              _stat('Waiting to book', _n('pending')),
              _stat('Coins earned', _n('coins_earned')),
            ], gap: 10),
            const SizedBox(height: 16),
            Text(
              'Your referrals',
              style: WT.sans(15, w: FontWeight.w800, h: 1.2),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                'No referrals yet. Share your link to get started.',
                style: WT.sans(13.5, color: WT.mut),
              )
            else
              for (final raw in items)
                if (raw is Map)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${raw['name'] ?? ''}',
                                style: WT.sans(
                                  14,
                                  w: FontWeight.w800,
                                  h: 1.3,
                                ),
                              ),
                              Text(
                                'joined ${_date(raw['joined'])}',
                                style: WT.sans(12, color: WT.mut, h: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill('${raw['status'] ?? ''}'),
                      ],
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
