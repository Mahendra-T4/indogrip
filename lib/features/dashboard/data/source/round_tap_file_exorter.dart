import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:indogrip/core/utils/widgets/toast_service.dart';
import 'package:indogrip/features/outsource/data/repositories/os_export_master_repo.dart';
import 'package:indogrip/features/round/domain/repositories/add_round_repo.dart';
import 'package:indogrip/features/staff/data/models/view_staff_api_param.dart';
import 'package:intl/intl.dart';

class TapeRoundFileExporter {
  static Future<Uint8List> generateTapeExcel(
    List<Map<String, dynamic>> tapeData,
    List<Map<String, dynamic>> roundData,
  ) async {
    try {
      Excel excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      const List<String> headers = [
        'S. No.',
        'Product Type',
        'Batch Code',
        'Total Carton',
        'Available Carton',
        'Cut MM',
        'Base',
        'MIC',
        'Tape Length',
        'Carton Price',
      ];

      // Write headers in row 0
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Write tape data starting from row 1
      for (int row = 0; row < tapeData.length; row++) {
        var item = tapeData[row];
        final values = [
          '${row + 1}',
          'Outsource',
          item['batchInformation']?['batchID']?.toString() ?? '',
          item['quantity']?.toString() ?? '',
          item['availableQuantity']?.toString() ?? '',
          item['additionalInfo']?['cutMMMeter']?.toString() ?? '',
          item['additionalInfo']?['baseLabel']?.toString() ?? '',
          item['additionalInfo']?['micLabel']?.toString() ?? '',
          item['additionalInfo']?['tapeLength']?.toString() ?? '',
          item['cartonPrice']?.toString() ?? '',
        ];
        for (int col = 0; col < values.length; col++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: row + 1, // row 1 onwards
                ),
              )
              .value = TextCellValue(
            values[col],
          );
        }
      }

      // Write round data AFTER tape data (offset by tapeData.length + 1 for header)
      int roundStartRow = tapeData.length + 1;

      for (int row = 0; row < roundData.length; row++) {
        var item = roundData[row];
        final values = [
          '${roundStartRow + row}',
          'Manufacture',
          item['batchInformation']?['batchID']?.toString() ?? '',
          item['totalCarton']?.toString() ?? '',
          item['availableCarton']?.toString() ?? '',
          item['cutMMMeter']?.toString() ?? '',
          item['base']?.toString() ?? '',
          item['mic']?.toString() ?? '',
          item['tapeLength']?.toString() ?? '',
          item['cartonRate']?.toString() ?? '',
        ];
        for (int col = 0; col < values.length; col++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: roundStartRow + row, // continues after tape rows
                ),
              )
              .value = TextCellValue(
            values[col],
          );
        }
      }

      return excel.encode() as Uint8List;
    } catch (e) {
      print(e);
      return Uint8List(0);
    }
  }

  static Future<void> exportTapeExcel({
    required BuildContext context,
    required ViewRecordApiParam param,
    String? folderPath,
    String fileName = 'tape_round_export.xlsx',
  }) async {
    try {
      // Generate filename with current date
      String dateFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());
      String fileNameWithDate =
          'tape_round_data_$dateFormatted.xlsx'; // Default name with date

      // Show directory picker dialog to let user select save location
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save tape data',
      );

      if (selectedDirectory == null) {
        // User cancelled the picker
        ToastService.instance.showError(context, 'Export cancelled');
        return;
      }

      List<Map<String, dynamic>> data = await OsExportManagerRepository()
          .exportToExcel(param);

      List<Map<String, dynamic>> roundData = await AddRoundRepository()
          .loadRoundJsonData(param);

      Uint8List bytes = await generateTapeExcel(data, roundData);

      // Build the full file path with selected directory and dated filename
      String savePath = '$selectedDirectory/$fileNameWithDate';

      // Use dart:io to save file
      final file = File(savePath);
      await file.writeAsBytes(bytes);

      // Show success toast
      ToastService.instance.showSuccess(
        context,
        'File exported successfully: $fileNameWithDate',
      );

      // Open the folder where file was saved
      try {
        await Process.start('explorer.exe', ['/select,', savePath]);
      } catch (openError) {
        log('Could not open Excel file: $openError');
      }
    } catch (e) {
      log('Error exporting tape Excel: $e');
      ToastService.instance.showError(context, 'Failed to export Excel file.');
    }
  }
}
