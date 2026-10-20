import 'package:flutter/material.dart';

IconData placeKeywordIcon(String keyword) {
  switch (keyword.trim()) {
    case '카페':
      return Icons.coffee_outlined;
    case '음식점':
    case '맛집':
      return Icons.restaurant_outlined;
    case '호텔':
    case '숙소':
      return Icons.bed_outlined;
    case '사진':
      return Icons.camera_alt_outlined;
    case '전시회':
      return Icons.image_outlined;
    case '관광지':
      return Icons.account_balance_outlined;
    case '자연':
    case '공원':
      return Icons.park_outlined;
    default:
      return Icons.place_outlined;
  }
}
