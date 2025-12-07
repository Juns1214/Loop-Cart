import 'dart:math';
import 'package:geocoding/geocoding.dart';

class DeliveryFeeService {
  // Base location: KL City Center (Petronas Twin Towers as reference)
  static const double baseLat = 3.1570;
  static const double baseLng = 101.7116;
  
  // Service coverage radius in kilometers
  static const double maxServiceRadius = 50.0;
  
  // Malaysian Ringgit pricing tiers
  static const Map<String, dynamic> pricingTiers = {
    'tier1': {'maxKm': 5.0, 'fee': 10.0, 'label': 'Within 5km'},
    'tier2': {'maxKm': 10.0, 'fee': 15.0, 'label': '5-10km'},
    'tier3': {'maxKm': 20.0, 'fee': 25.0, 'label': '10-20km'},
    'tier4': {'maxKm': 35.0, 'fee': 35.0, 'label': '20-35km'},
    'tier5': {'maxKm': 50.0, 'fee': 50.0, 'label': '35-50km'},
  };

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Get coordinates from address string
  static Future<Map<String, dynamic>> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      // Combine address with Malaysia to improve accuracy
      String fullAddress = '$address, Malaysia';
      
      List<Location> locations = await locationFromAddress(fullAddress);
      
      if (locations.isNotEmpty) {
        return {
          'success': true,
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      } else {
        return {
          'success': false,
          'error': 'Address not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Unable to geocode address: ${e.toString()}',
      };
    }
  }

  /// Calculate delivery fee based on address
  static Future<Map<String, dynamic>> calculateDeliveryFee(
    Map<String, dynamic> addressData,
  ) async {
    try {
      // Build full address string
      String fullAddress = '${addressData['line1']}, ';
      if (addressData['line2'] != null && addressData['line2'].isNotEmpty) {
        fullAddress += '${addressData['line2']}, ';
      }
      fullAddress += '${addressData['postal']} ${addressData['city']}, ';
      fullAddress += '${addressData['state']}, Malaysia';

      // Get coordinates
      Map<String, dynamic> coordResult = 
          await getCoordinatesFromAddress(fullAddress);
      
      if (!coordResult['success']) {
        return {
          'success': false,
          'error': coordResult['error'],
        };
      }

      // Calculate distance
      double distance = calculateDistance(
        baseLat,
        baseLng,
        coordResult['latitude'],
        coordResult['longitude'],
      );

      // Check if within service area
      if (distance > maxServiceRadius) {
        return {
          'success': false,
          'error': 
              'Sorry, this location is outside our service area (${distance.toStringAsFixed(1)}km away). Maximum distance: ${maxServiceRadius}km',
          'distance': distance,
        };
      }

      // Determine pricing tier
      Map<String, dynamic> tier = _determinePricingTier(distance);

      return {
        'success': true,
        'distance': distance,
        'deliveryFee': tier['fee'],
        'tierLabel': tier['label'],
        'coordinates': {
          'latitude': coordResult['latitude'],
          'longitude': coordResult['longitude'],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error calculating delivery fee: ${e.toString()}',
      };
    }
  }

  /// Determine which pricing tier applies
  static Map<String, dynamic> _determinePricingTier(double distance) {
    for (var tier in pricingTiers.values) {
      if (distance <= tier['maxKm']) {
        return tier;
      }
    }
    // Fallback to highest tier
    return pricingTiers['tier5']!;
  }

  /// Get formatted delivery fee breakdown
  static String getDeliveryFeeBreakdown(Map<String, dynamic> feeResult) {
    if (!feeResult['success']) {
      return feeResult['error'];
    }

    return '''
Distance: ${feeResult['distance'].toStringAsFixed(1)} km
Category: ${feeResult['tierLabel']}
Delivery Fee: RM ${feeResult['deliveryFee'].toStringAsFixed(2)}
''';
  }

  /// Check if address is within service area (quick check)
  static Future<bool> isWithinServiceArea(
    Map<String, dynamic> addressData,
  ) async {
    Map<String, dynamic> result = await calculateDeliveryFee(addressData);
    return result['success'] == true;
  }

  /// Get all pricing tiers info for display
  static List<Map<String, dynamic>> getPricingTiersInfo() {
    return pricingTiers.entries.map((entry) {
      return {
        'tier': entry.key,
        'label': entry.value['label'],
        'fee': entry.value['fee'],
        'maxKm': entry.value['maxKm'],
      };
    }).toList();
  }
}