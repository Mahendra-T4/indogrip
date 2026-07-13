import 'dart:io';

import 'package:indogrip/core/database/hive_service.dart';
import 'package:indogrip/features/chalan/data/model/challan_submit_details_modeld.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ChallanPdfService {
  /// PDF storage directory options
  static const String documentsDir = 'documents';
  static const String downloadsDir = 'downloads';

  /// Get storage directory based on type
  static Future<Directory> getStorageDirectory(String dirType) async {
    late Directory directory;

    if (dirType == documentsDir) {
      directory = await getApplicationDocumentsDirectory();
    } else if (dirType == downloadsDir) {
      try {
        if (Platform.isAndroid) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          directory =
              await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Create challan subdirectory
    final challanDir = Directory('${directory.path}/ChallanPDFs');
    if (!await challanDir.exists()) {
      await challanDir.create(recursive: true);
    }

    return challanDir;
  }

  /// Generate and save challan details PDF
  static Future<String> generateChallanPdf(
    ChallanDetailsResponse response, {
    String storageType = documentsDir,
  }) async {
    try {
      final directory = await getStorageDirectory(storageType);
      final now = DateTime.now();
      final fileName =
          'challan_${response.challanInfo!.challanNumber}_${now.millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final formattedDateTime =
          '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildHeader(response),
            pw.SizedBox(height: 20),
            _buildHeaderCard(response),
            pw.SizedBox(height: 20),
            _buildTableSection(response),
            pw.SizedBox(height: 20),
            _buildFooterCard(response),
            pw.SizedBox(height: 20),
            _buildDocumentInfoFooter(formattedDateTime, filePath),
          ],
        ),
      );

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Generate and save challan PDF
  static Future<String> printChallanDetails(
    ChallanDetailsResponse response, {
    String storageType = documentsDir,
  }) async {
    try {
      final filePath = await generateChallanPdf(
        response,
        storageType: storageType,
      );

      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file was not created successfully');
      }

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Share PDF with system share dialog
  static Future<void> sharePdf(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: 'Challan Details');
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Get list of saved challan PDFs
  static Future<List<FileSystemEntity>> getSavedChallans({
    String storageType = documentsDir,
  }) async {
    try {
      final directory = await getStorageDirectory(storageType);
      final files = directory.listSync();
      return files.where((file) => file.path.endsWith('.pdf')).toList();
    } catch (e) {
      throw Exception('Failed to get saved challans: $e');
    }
  }

  // Helper methods for building PDF widgets

  static pw.Widget _buildHeader(ChallanDetailsResponse response) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CHALLAN DETAILS',
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1E3A8A),
          ),
        ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _buildHeaderCard(ChallanDetailsResponse response) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBFE),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFF1E3A8A),
          width: 2,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeaderDetailRow(
            'Client Name',
            response.challanInfo!.consigneeeName ?? 'N/A',
            '👔',
            const PdfColor.fromInt(0xFF1E3A8A),
          ),
          pw.SizedBox(height: 14),
          _buildHeaderDetailRow(
            'Challan Number',
            response.challanInfo!.challanNumber,
            '✓',
            const PdfColor.fromInt(0xFF059669),
          ),
          pw.SizedBox(height: 14),
          _buildHeaderDetailRow(
            'Date',
            response.challanInfo!.challanDate,
            '📅',
            const PdfColor.fromInt(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderDetailRow(
    String label,
    String value,
    String icon,
    PdfColor color,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF3F4F6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(icon, style: const pw.TextStyle(fontSize: 14)),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.normal,
                  color: const PdfColor.fromInt(0xFF6B7280),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableSection(ChallanDetailsResponse response) {
    final outList = response.challanInfo!.outList;

    // Build header row
    final headerCells = ['SR No', 'Batch Code', 'Qty', 'Last Reason']
        .map(
          (label) => pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E3A8A),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFFFFFFFF),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        )
        .toList();

    // Build data rows with conditional background
    final dataRows = outList.asMap().entries.map((entry) {
      int index = entry.key;
      OutListItem record = entry.value;

      // Determine row background color based on batchStatus
      final rowBgColor = record.batchStatus == 0
          ? const PdfColor.fromInt(0xFFFFCCCC) // Light red for status 0
          : const PdfColor.fromInt(0xFFFFFFFF); // White for other statuses

      return [
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: rowBgColor,
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            (index + 1).toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: rowBgColor,
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            record.batchCode?.toString() ?? '',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: rowBgColor,
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            record.batchQty.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // pw.Container(
        //   alignment: pw.Alignment.center,
        //   padding: const pw.EdgeInsets.all(8),
        //   decoration: pw.BoxDecoration(
        //     color: rowBgColor,
        //     border: pw.Border.all(
        //       color: const PdfColor.fromInt(0xFFE5E7EB),
        //       width: 0.5,
        //     ),
        //   ),
        //   child: pw.Text(
        //     record.requiredQty.toString(),
        //     style: const pw.TextStyle(fontSize: 9),
        //     textAlign: pw.TextAlign.center,
        //   ),
        // ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: rowBgColor,
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            record.batchMessage.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Item Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1F2937),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFF1E3A8A),
              width: 1,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFE5E7EB),
              width: 0.5,
            ),
            children: [
              pw.TableRow(children: headerCells),
              ...dataRows.map((row) => pw.TableRow(children: row)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooterCard(ChallanDetailsResponse response) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBFE),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFF1E3A8A),
          width: 2,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Carton Details',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1F2937),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildDetailBox(
                  'Requested',
                  response.totalRequest.toString(),
                  '(${response.challanInfo?.outList.fold<int>(0, (sum, item) => sum + (int.tryParse(item.batchQty.toString()) ?? 0)) ?? 0} Cartons)',
                  const PdfColor.fromInt(0xFF3B82F6),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildDetailBox(
                  'Accepted',
                  response.acceptRequest.toString(),
                  '(${response.totalRequest} Cartons)',
                  const PdfColor.fromInt(0xFF10B981),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildDetailBox(
                  'Missed',
                  response.missedRequest.toString(),
                  '(${response.challanInfo?.outList.fold<int>(0, (sum, element) => element.batchStatus == 0 ? sum + (int.tryParse(element.batchQty.toString()) ?? 0) : sum) ?? 0} Cartons)',
                  PdfColors.redAccent,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF3F4F6),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFD1D5DB),
                width: 1,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFEDE9FE),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text('👤', style: const pw.TextStyle(fontSize: 12)),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Out By Name',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.normal,
                        color: const PdfColor.fromInt(0xFF6B7280),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${HiveService.getFName()} ${HiveService.getLName()}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailBox(
    String label,
    String qty,
    String value,
    PdfColor color,
  ) {
    // Define light color variants for backgrounds
    const lightBlue = PdfColor.fromInt(0xFFDEF7FF);
    const lightGreen = PdfColor.fromInt(0xFFDEFCF0);
    const lightOrange = PdfColor.fromInt(0xFFFEF3C7);

    PdfColor bgColor = lightBlue;
    if (color.toHex() == '10B981FF') {
      bgColor = lightGreen;
    } else if (color.toHex() == 'F59E0BFF') {
      bgColor = lightOrange;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            qty,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDocumentInfoFooter(String dateTime, String filePath) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3F4F6),
        border: pw.Border(
          top: pw.BorderSide(
            color: const PdfColor.fromInt(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Generated: $dateTime',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.normal,
              color: const PdfColor.fromInt(0xFF6B7280),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'File: $filePath',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.normal,
              color: const PdfColor.fromInt(0xFF9CA3AF),
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}
