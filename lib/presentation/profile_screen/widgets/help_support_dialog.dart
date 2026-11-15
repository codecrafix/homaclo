import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

Future<void> _openEmail() async {
  final uri = Uri.parse('mailto:homaclo.official@gmail.com');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> _openWhatsApp() async {
  final uri = Uri.parse(
    'https://wa.me/916262262913?text=Hi%20Homaclo%2C%20I%20need%20help',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

InputDecoration _fieldDecoration(BuildContext context, String label,
    {bool multiline = false}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppTheme.divider),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppTheme.textSecondary,
    ),
    alignLabelWithHint: multiline,
    filled: true,
    fillColor: AppTheme.inputFillColor(context),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.tealAccent, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

/// Contact row that always fits: long text shrinks instead of overflowing.
Widget _contactOption({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showHelpSupportDialog(BuildContext context) {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Help & Support',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit a support ticket or reach us directly:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subjectController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.inputTextColor(context),
                  ),
                  decoration: _fieldDecoration(context, 'Subject'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.inputTextColor(context),
                  ),
                  decoration: _fieldDecoration(
                    context,
                    'Message',
                    multiline: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Or reach us directly:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _contactOption(
                  icon: Icons.email_rounded,
                  label: 'homaclo.official@gmail.com',
                  color: AppTheme.onSurfaceStrong,
                  onTap: _openEmail,
                ),
                const SizedBox(height: 8),
                _contactOption(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp Support',
                  color: const Color(0xFF25D366),
                  onTap: _openWhatsApp,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    subjectController.dispose();
                    messageController.dispose();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final subject = subjectController.text.trim();
                          final message = messageController.text.trim();
                          if (subject.isEmpty || message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please fill in subject and message.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          final success = await SupabaseService.instance
                              .createSupportTicket(
                                subject: subject,
                                message: message,
                              );
                          if (ctx.mounted) {
                            subjectController.dispose();
                            messageController.dispose();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '✅ Support ticket submitted! We will get back to you soon.'
                                      : '❌ Failed to submit. Please try again.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: success
                                    ? AppTheme.success
                                    : AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Ticket',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
