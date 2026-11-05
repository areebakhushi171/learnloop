import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator validates correct and incorrect emails', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('Password validator validates length', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('12345'), isNotNull);
    });
  });
}
