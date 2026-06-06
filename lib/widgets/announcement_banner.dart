import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// A reusable UI component that displays the announcement banner.
///
/// This maintains clean separation of concerns by placing all presentation
/// logic (styling, layout, colors, icons) here in the UI layer, while
/// querying state and triggers from the global [AppProvider].
class AnnouncementBanner extends StatelessWidget {
  final Color defaultColor;

  const AnnouncementBanner({
    super.key,
    required this.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    // Consume the global AppProvider state cleanly using watch
    final appProvider = context.watch<AppProvider>();
    final isMaintenance = appProvider.isMaintenanceMode;
    final text = isMaintenance
        ? "Sistem sedang dalam pemeliharaan berkala!"
        : appProvider.announcement;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isMaintenance ? Colors.redAccent.shade700 : defaultColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isMaintenance ? Icons.warning_amber_rounded : Icons.campaign,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (!isMaintenance)
            GestureDetector(
              onTap: () {
                // Call business logic inside the provider
                appProvider.updateAnnouncement(
                  "Hubungi Customer Service kami jika ada kendala.",
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
