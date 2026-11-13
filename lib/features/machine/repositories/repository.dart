import 'package:dio/dio.dart';
import 'package:indogrip/core/database/hive_service.dart';
import 'package:indogrip/core/service/api%20service/dio_service.dart';
import 'package:indogrip/core/service/logger.dart';
import 'package:indogrip/features/machine/models/machine_cal_model.dart';

class MachineCalculationRepository {
  static Future<MachineCalculationModel> machineCalculation({
    required String meters,
  }) async {
    MachineCalculationModel model = MachineCalculationModel();
    try {
      final response = await DioService.dioPostApiCall(
        data: FormData.fromMap({
          'activity': 'machine-information',
          'userKey': HiveService.getUserId(),
          'meter': meters,
        }),
      );
      if (response.statusCode == 200) {
        model = MachineCalculationModel.fromJson(response.data);
        logger.i('Machine Calculation: ${model.toJson()}');
      } else {
        logger.w('Machine Calculation Warning: ${response.data['message']}');
      }
    } on DioException catch (e) {
      logger.e('Machine Calculation DioException: $e');
    } catch (e) {
      logger.e('Machine Calculation Error: $e');
    } finally {
      return model;
    }
  }
}
