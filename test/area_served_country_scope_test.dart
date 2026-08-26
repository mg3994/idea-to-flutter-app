import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/core/utils/area_served_matcher.dart';

void main() {
  group('AreaServedMatcher Country Scope Tests', () {
    test('Eevaluates country-wide areaServed as true for specific city query in that country', () {
      final countryWideArea = ['India', 'USA'];

      // User in Mumbai, India
      final matchesMumbai = AreaServedMatcher.matches(
        areaServed: countryWideArea,
        city: 'Mumbai',
        country: 'India',
      );
      expect(matchesMumbai, isTrue);

      // User with postal code in India
      final matchesPostal = AreaServedMatcher.matches(
        areaServed: countryWideArea,
        postalCode: '400001',
        country: 'India',
      );
      expect(matchesPostal, isTrue);
    });

    test('Evaluates Worldwide or Global areaServed as true for any user location', () {
      final globalArea = 'Worldwide';

      final matchesAnyCity = AreaServedMatcher.matches(
        areaServed: globalArea,
        city: 'Tokyo',
        country: 'Japan',
      );
      expect(matchesAnyCity, isTrue);
    });
  });
}
