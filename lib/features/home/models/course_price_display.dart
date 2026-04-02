const int maxCourseDisplayPrice = 100;

int normalizeCoursePrice(int price) {
  if (price <= 0) {
    return price;
  }

  return price > maxCourseDisplayPrice ? maxCourseDisplayPrice : price;
}

int displayCoursePrice(int price) {
  return normalizeCoursePrice(price);
}

String displayCoursePriceLabel(int price) {
  final resolvedPrice = displayCoursePrice(price);
  return resolvedPrice <= 0 ? 'Free' : '\$$resolvedPrice';
}
