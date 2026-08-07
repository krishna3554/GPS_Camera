import 'package:flutter/material.dart';

import '../../../core/widgets/location_stamp_card.dart';
import '../../../models/location_info.dart';

class DetailLocationCard extends StatelessWidget {
  const DetailLocationCard({required this.locationInfo, this.width, super.key});

  final LocationInfo? locationInfo;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return LocationStampCard(
      locationInfo: locationInfo,
      cardWidth: width ?? MediaQuery.sizeOf(context).width * 0.85,
    );
  }
}
