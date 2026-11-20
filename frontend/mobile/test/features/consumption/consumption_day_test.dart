import 'package:elecpay/features/consumption/consumption_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valeur d’une case du calendrier : kWh au dixième, sans unité', () {
    expect(formatCellValue(9000), '9');
    expect(formatCellValue(12450), '12,5');
    expect(formatCellValue(380), '0,4');
  });
}
