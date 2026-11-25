import 'package:flutter_test/flutter_test.dart';

import 'package:ouest_tv/main.dart';
import 'package:ouest_tv/ouest/brand.dart';

void main() {
  test('config', () {
    expect(config.group, 'acasgroup');
    expect(config.appChannel, 'ouest-tv');
    expect(design.splashBuilder, isNotNull);
    expect(design.homeBuilder, isNotNull);
  });

  test('dates des vignettes', () {
    final now = DateTime(2026, 11, 20, 18);
    expect(ouestDay(DateTime(2026, 11, 20, 16, 30), now: now), "Aujourd'hui");
    expect(ouestDay(DateTime(2026, 11, 19, 9), now: now), 'Hier');
    expect(ouestDay(DateTime(2021, 10, 2), now: now), '02/10/2021');
    expect(ouestTime(DateTime(2026, 11, 20, 16, 30)), '16:30');
  });
}
