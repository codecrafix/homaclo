import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/premium_ui.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  static const double _avatarSize = 72;

  Widget _buildAvatar(AppState appState) {
    final effectiveUrl = appState.effectiveProfileImageUrl;

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      final bool isNetworkUrl =
          effectiveUrl.startsWith('http://') ||
          effectiveUrl.startsWith('https://') ||
          effectiveUrl.startsWith('blob:');

      if (isNetworkUrl) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: effectiveUrl,
            width: _avatarSize,
            height: _avatarSize,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialLetterAvatar(appState),
            errorWidget: (_, __, ___) => _initialLetterAvatar(appState),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(effectiveUrl),
            width: _avatarSize,
            height: _avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialLetterAvatar(appState),
          ),
        );
      }
    }

    return _initialLetterAvatar(appState);
  }

  Widget _initialLetterAvatar(AppState appState) {
    final initial = appState.userName.isNotEmpty
        ? appState.userName[0].toUpperCase()
        : (appState.userEmail.isNotEmpty
              ? appState.userEmail[0].toUpperCase()
              : 'H');
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.tealAccent, Color(0xFF0088A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _avatarWithBadge(BuildContext context, AppState appState) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.tealAccent, Color(0xFF9BE7F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppGradients.teal.withOpacity(0.5),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryNavy,
            ),
            child: _buildAvatar(appState),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: TapScale(
            onTap: () => context.push(AppRoutes.editProfileScreen),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryNavy, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppTheme.tealAccent,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.tealAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                letterSpacing: 0.1,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    void openEdit() => context.push(AppRoutes.editProfileScreen);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryNavy,
            AppTheme.headerAlt,
            AppGradients.teal.withOpacity(0.14),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppGradients.teal.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withAlpha(90),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppGradients.teal.withOpacity(0.08),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatarWithBadge(context, appState),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.userName.isNotEmpty
                          ? appState.userName
                          : 'Homaclo User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppTheme.tealAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HOMACLO MEMBER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppTheme.tealAccent,
                          ),
                        ),
                      ],
                    ),
                    if (appState.userEmail.isNotEmpty)
                      _infoRow(Icons.mail_rounded, appState.userEmail),
                    if (appState.userPhone.isNotEmpty)
                      _infoRow(Icons.phone_rounded, appState.userPhone),
                  ],
                ),
              ),
            ],
          ),
          if (appState.userCity.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withAlpha(30)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.tealAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appState.userCity,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.35,
                      color: Colors.white.withAlpha(215),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TapScale(
                  onTap: openEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [AppTheme.tealAccent, AppGradients.cyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppGradients.teal.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Edit Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
