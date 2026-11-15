import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/gps_enforcement_wrapper.dart';
import '../../widgets/site_footer.dart';
import 'package:provider/provider.dart';
import './widgets/home_web_hero.dart';
import './widgets/home_web_proof.dart';
import './widgets/home_web_sections.dart';

/// Home screen: same content and order as the Homaclo website home page
/// (hero, stats, services, how it works, why Homaclo, real work proof,
/// how we keep your water safe, reviews, call to action). This is the only
/// screen that shows the footer.
///
/// The location now lives in the shared header (location icon), so the hero
/// starts right under the header, like the website.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget section(Widget child, {double top = 22}) => SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, 0),
        child: child,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(Theme.of(context).brightness == Brightness.dark),
      child: GpsEnforcementWrapper(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          // The shared website header (SiteHeader) is added by AppScaffold.
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshAllData(
              refreshLocation: true,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Full-width hero, same as the website.
                const SliverToBoxAdapter(child: HomeHero()),
                section(const HomeWebStats(), top: 22),
                section(const HomeWebServices(), top: 28),
                section(const HomeWebHowItWorks(), top: 28),
                section(const HomeWebWhy(), top: 28),
                section(const HomeWebProof(), top: 28),
                section(const HomeWebStory(), top: 28),
                section(const HomeWebReviews(), top: 28),
                section(const HomeWebCta(), top: 28),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                const SliverToBoxAdapter(child: SiteFooter()),
                // Room for the floating bottom nav, same colour as the footer end.
                const SliverToBoxAdapter(
                  child: ColoredBox(
                    color: Color(0xFF0F172A),
                    child: SizedBox(height: 90, width: double.infinity),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
