import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/gps_enforcement_wrapper.dart';
import '../../widgets/site_footer.dart';
import 'package:provider/provider.dart';
import './widgets/home_before_after_widget.dart';
import './widgets/home_cleaning_process_widget.dart';
import './widgets/home_faqs_widget.dart';
import './widgets/home_hero_banner_widget.dart';
import './widgets/home_info_strip.dart';
import './widgets/home_services_widget.dart';
import './widgets/home_why_clean_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const SliverToBoxAdapter(child: HomeInfoStrip()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeHeroBannerWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeBeforeAfterWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeWhyCleanWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeServicesWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeCleaningProcessWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeFaqsWidget(),
                  ),
                ),
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
