import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_tooapp/src/features/reports/models/report.dart';

void main() {
  test('maps report and its allowlisted author summary from the API DTO', () {
    final report = Report.fromJson({
      'id': 'r1',
      'type': 'CLAIM',
      'content': 'A report body',
      'isResolved': false,
      'createdAt': '2026-10-30T10:00:00.000Z',
      'author': {
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
      },
    });

    expect(report.author.displayName, 'Ada Lovelace');
    expect(report.author.email, 'ada@example.com');
    expect(report.type, 'CLAIM');
    expect(report.isResolved, isFalse);
  });

  test('handles absent optional author contact fields', () {
    final report = Report.fromJson({
      'id': 'r2',
      'type': 'SUGGESTION',
      'content': 'A report body',
      'isResolved': true,
      'createdAt': 'invalid-date',
    });

    expect(report.author.displayName, 'Autor sin nombre');
    expect(report.author.email, isNull);
    expect(report.createdAt, isNull);
  });
}
