import 'package:flutter_test/flutter_test.dart';
import 'package:indogrip/features/global/data/model/delete_record_model.dart';

void main() {
  group('DeleteRecordEntity.fromJson', () {
    test('parses message values when the API returns a map payload', () {
      final entity = DeleteRecordEntity.fromJson({
        'status': 1,
        'message': {'success': true, 'details': 'Deleted'},
      });

      expect(entity.status, 1);
      expect(entity.message, '{"success":true,"details":"Deleted"}');
    });
  });
}
