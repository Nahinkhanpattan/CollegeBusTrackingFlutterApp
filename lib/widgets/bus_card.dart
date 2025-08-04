import 'package:flutter/material.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;
  final RouteModel? route;
  final VoidCallback? onViewLocation;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showLiveStatus;

  const BusCard({
    super.key,
    required this.bus,
    this.route,
    this.onViewLocation,
    this.onTap,
    this.isSelected = false,
    this.showLiveStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected ? AppColors.primary : AppColors.success,
                    child: Text(
                      bus.busNumber.replaceAll('Bus ', ''),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus ${bus.busNumber}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        if (route != null) ...[
                          Text(
                            '${route!.startPoint} → ${route!.endPoint}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (route!.stopPoints.isNotEmpty)
                            Text(
                              'Stops: ${route!.stopPoints.join(', ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (showLiveStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bus.isActive ? AppColors.success : AppColors.warning,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      child: Text(
                        bus.isActive ? 'Live' : 'Offline',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (onViewLocation != null) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewLocation,
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('View Live Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}