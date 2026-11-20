import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';
import '../../../services/home_data_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/tap_scale.dart';
import 'web_tokens.dart';

/// Top header copied from the website: Refer & Earn, logo, theme, bell, sign in/out.
class WebHeader extends StatelessWidget {
  const WebHeader({super.key});

  Future<void> _signOut(BuildContext context) async {
    final app = context.read<AppState>();
    final router = GoRouter.of(context);
    await SupabaseService.instance.signOut();
    app.logout();
    router.go(WT.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      decoration: BoxDecoration(
        color: WT.bg,
        border: Border(bottom: BorderSide(color: WT.line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _IconBtn(
                onTap: () => showReferSheet(context),
                child: const Text('🎁', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: _Logo()),
                ),
              ),
              _IconBtn(
                onTap: () => context.read<AppState>().toggleTheme(),
                child: Text('◐', style: TextStyle(fontSize: 16, color: WT.ink)),
              ),
              const SizedBox(width: 6),
              if (app.isLoggedIn) ...[
                _IconBtn(
                  badge: app.unreadNotificationCount,
                  onTap: () => context.push(WT.routeNotifications),
                  child: const Text('🔔', style: TextStyle(fontSize: 17)),
                ),
                const SizedBox(width: 6),
              ],
              WBtn(
                app.isLoggedIn ? 'Sign out' : 'Sign in',
                small: true,
                full: false,
                onTap: () {
                  if (app.isLoggedIn) {
                    _signOut(context);
                  } else {
                    context.go(WT.routeLogin);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [WT.cyan, WT.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.elliptical(10, 16),
              topRight: Radius.elliptical(10, 16),
              bottomLeft: Radius.elliptical(10, 10),
              bottomRight: Radius.elliptical(10, 10),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7306B6D4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Text('Homaclo', style: WT.serif(22)),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final int badge;
  const _IconBtn({required this.child, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.92,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WT.sf,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WT.line),
                ),
                child: child,
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5484D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
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

// ───────────────────────── Refer & Earn ─────────────────────────

void showReferSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReferSheet(),
  );
}

const List<List<String>> _kSteps = [
  ['Get your link', 'Sign in and copy your personal referral link.'],
  [
    'Friend joins',
    'Your friend opens your link and signs up as a new customer.',
  ],
  ['Friend books', 'They book any service worth ₹500 or more.'],
  [
    'Both earn',
    '50 coins (₹50) go to your wallet and your friend’s wallet automatically.',
  ],
];

const List<String> _kRules = [
  'Only new customers: your friend must be a new account (created within the last 7 days) making their first booking.',
  'The booking must be ₹500 or more after discounts, paid online.',
  'Coins are added automatically once the paid booking is confirmed. 1 coin = ₹1, and up to 50 coins can be used per booking.',
  'No self-referrals: your own extra accounts, the same email (including Gmail dot or plus tricks) or the same address do not qualify.',
  'Up to 10 rewarded referrals in any 30 days.',
  'Homaclo can cancel rewards that look fake or abusive.',
];

class _ReferSheet extends StatefulWidget {
  const _ReferSheet();

  @override
  State<_ReferSheet> createState() => _ReferSheetState();
}

class _ReferSheetState extends State<_ReferSheet> {
  late final Future<String?> _code = HomeDataService.myReferralCode();
  bool _copied = false;

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.maintix.app';

  String _msg(String link) =>
      'Book professional water tank cleaning with Homaclo in Satna. Sign up with my link and we both get 50 coins after your first booking of ₹500 or more: $link'
      '\n\nDownload the Homaclo app: $_playStoreUrl';

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: WT.sf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('🎁 Refer & Earn', style: WT.serif(22)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: WT.mut),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: WT.sans(14.5, color: WT.mut, h: 1.55),
                  children: [
                    const TextSpan(
                      text:
                          'Share Homaclo with friends. When they make their first booking, you both get ',
                    ),
                    TextSpan(
                      text: '50 coins (₹50)',
                      style: WT.sans(14.5, w: FontWeight.w800, h: 1.55),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _kSteps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text.rich(
                    TextSpan(
                      style: WT.sans(14, h: 1.5),
                      children: [
                        TextSpan(
                          text: '${i + 1}. ${_kSteps[i][0]}. ',
                          style: WT.sans(14, w: FontWeight.w800, h: 1.5),
                        ),
                        TextSpan(
                          text: _kSteps[i][1],
                          style: WT.sans(14, color: WT.mut, h: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              FutureBuilder<String?>(
                future: _code,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Text(
                      'Loading your link…',
                      style: WT.sans(13.5, color: WT.mut),
                    );
                  }
                  final code = snap.data;
                  if (code == null) {
                    return Text(
                      'We could not load your link right now. Please try again in a moment.',
                      style: WT.sans(13.5, color: WT.mut),
                    );
                  }
                  final link = 'https://homaclo.in/?ref=$code';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: WT.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WT.line, width: 1.5),
                        ),
                        child: SelectableText(
                          link,
                          style: WT.sans(13.5, w: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: WBtn(
                              _copied ? 'Copied ✓' : 'Copy',
                              small: true,
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: link),
                                );
                                if (!mounted) return;
                                setState(() => _copied = true);
                                Future.delayed(
                                  const Duration(milliseconds: 1800),
                                  () {
                                    if (mounted) setState(() => _copied = false);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: WBtn(
                              'WhatsApp',
                              small: true,
                              ghost: true,
                              onTap: () => wOpen(
                                'https://wa.me/?text=${Uri.encodeComponent(_msg(link))}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      WBtn(
                        'Get the app',
                        small: true,
                        ghost: true,
                        onTap: () => wOpen(_playStoreUrl),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    'Rules that keep it fair',
                    style: WT.sans(14, w: FontWeight.w800),
                  ),
                  children: [
                    for (final r in _kRules)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• $r',
                          style: WT.sans(13.5, color: WT.mut, h: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
