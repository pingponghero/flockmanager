import 'package:flutter/material.dart';

import '../../../data/medications.dart';
import '../../../app/status_colors.dart';

/// Badge showing the legal status of a medication
class LegalStatusBadge extends StatelessWidget {
  final LegalStatus legalStatus;

  const LegalStatusBadge({super.key, required this.legalStatus});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusStyle(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (legalStatus) {
      case LegalStatus.fdaApproved:
        return 'FDA Approved';
      case LegalStatus.offLabel:
        return 'Off-Label';
      case LegalStatus.prescriptionRequired:
        return 'Rx Required';
      case LegalStatus.bannedInUs:
        return 'BANNED';
      case LegalStatus.notForFoodAnimals:
        return 'NOT FOR FOOD';
    }
  }

  (Color, IconData) _getStatusStyle(BuildContext context) {
    final status = StatusColors.of(context);
    switch (legalStatus) {
      case LegalStatus.fdaApproved:
        return (status.success.icon, Icons.check_circle_outline);
      case LegalStatus.offLabel:
        return (status.info.icon, Icons.info_outline);
      case LegalStatus.prescriptionRequired:
        return (status.special.icon, Icons.medical_services_outlined);
      case LegalStatus.bannedInUs:
        return (status.danger.icon, Icons.block);
      case LegalStatus.notForFoodAnimals:
        return (status.danger.icon, Icons.dangerous_outlined);
    }
  }
}
