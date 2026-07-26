import 'dart:async';
import 'dart:developer' as logger;
import 'package:flutter/material.dart';
import 'package:indogrip/core/database/hive_service.dart';
import 'package:indogrip/core/responsive/responsive.dart';
import 'package:indogrip/core/service/pdf_service.dart';
import 'package:indogrip/core/utils/appbar/desktop_appbar.dart';
import 'package:indogrip/core/utils/appbar/mobile_appbar.dart';
import 'package:indogrip/core/utils/sidebar.dart';
import 'package:indogrip/features/chalan/data/model/challan_submit_details_modeld.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ChallanDetailsPage extends StatefulWidget {
  const ChallanDetailsPage({super.key, required this.response});
  static const String routeName = '/challan-details';
  final ChallanDetailsResponse response;

  @override
  State<ChallanDetailsPage> createState() => _ChallanDetailsPageState();
}

class MissRecordData {
  final String srNo;
  final String batchCode;
  final String qty;
  final String available;
  final String lastReason;

  MissRecordData({
    required this.srNo,
    required this.batchCode,
    required this.qty,
    required this.available,
    required this.lastReason,
  });
}

class MissRecordDataSource extends DataGridSource {
  final List<OutListItem> data;

  MissRecordDataSource({required this.data}) {
    buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void buildDataGridRows() {
    dataGridRows = data.asMap().entries.map<DataGridRow>((entry) {
      int index = entry.key; // Row index
      OutListItem record = entry.value;
      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'srNo',
            value: (index + 1).toString(),
          ),
          DataGridCell<String>(
            columnName: 'batchCode',
            value: record.batchCode?.toString() ?? '',
          ),
          DataGridCell<String>(
            columnName: 'qty',
            value: record.batchQty.toString(),
          ),
          DataGridCell<String>(
            columnName: 'available',
            value: record.requiredQty.toString(),
          ),
          DataGridCell<String>(
            columnName: 'lastReason',
            value: record.batchMessage.toString(),
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final int rowIndex = dataGridRows.indexOf(row);
    return DataGridRowAdapter(
      color: rowIndex.isEven ? Colors.white : const Color(0xFFF9FAFB),
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: Alignment.center,
          color: data[rowIndex].batchStatus == 0
              ? Colors.redAccent
              : const Color(0xFFE6FFFA),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            cell.value.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}

class _ChallanDetailsPageState extends State<ChallanDetailsPage> {
  late MissRecordDataSource missRecordDataSource;
  final GlobalKey<ScaffoldState> _statekey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    missRecordDataSource = MissRecordDataSource(
      data: widget.response.challanInfo!.outList,
    );
    // autoBack();
  }

  // autoBack() async {
  //   await Future.delayed(const Duration(seconds: 5));
  //   if (mounted) {
  //     context.goNamed(AppHome.routeName);
  //   }
  // }

  Future<void> _printChallan() async {
    // Show storage location selection dialog
    final storageType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Storage Location'),
          content: const Text('Where would you like to save the PDF?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, ChallanPdfService.documentsDir),
              child: const Text('App Documents'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, ChallanPdfService.downloadsDir),
              child: const Text('Downloads'),
            ),
          ],
        );
      },
    );

    if (storageType == null) return;

    // Show loading snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Generate PDF
      final filePath = await ChallanPdfService.printChallanDetails(
        widget.response,
        storageType: storageType,
      );

      if (!mounted) return;

      // Show success snackbar with actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ PDF generated successfully!'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              _sharePdf(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✗ Error: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _printChallan();
            },
          ),
        ),
      );
      logger.log('Error printing challan: $e', name: 'ChallanDetailsPage');
    }
  }

  Future<void> _sharePdf(String filePath) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening share options...'),
          duration: Duration(seconds: 3),
        ),
      );

      await ChallanPdfService.sharePdf(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  //  Padding(
  //           padding: const EdgeInsets.only(right: 12),
  //           child: IconButton(
  //             onPressed: () {
  //               _printChallan();
  //             },
  //             icon: const Icon(Icons.download, size: 30),
  //             tooltip: 'Download PDF',
  //           ),
  //         ),

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      key: _statekey,
      appBar: !Responsive.isDesktop(context)
          ? MobileAppBar(context, _statekey, 'Challan Details')
          : DesktopAppBar(context, _statekey, 'Challan Details', false),
      drawer: !Responsive.isDesktop(context) ? SideMenuWidget() : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Client Details
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: IconButton(
                      onPressed: () {
                        _printChallan();
                      },
                      icon: const Icon(Icons.download, size: 30),
                      tooltip: 'Download PDF',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildHeaderCard(),

              const SizedBox(height: 20),
              // Table Section
              _buildTableSection(),
              const SizedBox(height: 20),
              // Footer Card with Carton Details
              _buildFooterCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Client Name',
            widget.response.challanInfo!.consigneeeName ?? 'N/A',
            Icons.business,
            const Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Challan Number',
            widget.response.challanInfo!.challanNumber,
            Icons.confirmation_number,
            const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Date',
            widget.response.challanInfo!.challanDate,
            Icons.calendar_today,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SfDataGrid(
          source: missRecordDataSource,
          columnWidthMode: ColumnWidthMode.fill,
          headerGridLinesVisibility: GridLinesVisibility.horizontal,
          gridLinesVisibility: GridLinesVisibility.horizontal,
          columns: <GridColumn>[
            GridColumn(columnName: 'srNo', label: _buildHeaderLabel('SR No')),
            GridColumn(
              columnName: 'batchCode',
              label: _buildHeaderLabel('Batch Code'),
            ),
            GridColumn(columnName: 'qty', label: _buildHeaderLabel('Qty')),
            GridColumn(
              columnName: 'available',
              label: _buildHeaderLabel('Available'),
            ),
            GridColumn(
              columnName: 'lastReason',
              label: _buildHeaderLabel('Last Reason'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String label) {
    return Container(
      color: const Color(0xFF1E3A8A),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carton Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFooterDetailBox(
                  'Requested',
                  widget.response.totalRequest.toString(),
                  '(${widget.response.challanInfo?.outList.fold<int>(0, (sum, element) => sum + element.batchQty) ?? 0} Cartons)',
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFooterDetailBox(
                  'Accepted',
                  widget.response.acceptRequest.toString(),
                  '(${widget.response.totalRequest} Cartons)',
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFooterDetailBox(
                  'Missed',
                  widget.response.missedRequest.toString(),
                  '(${widget.response.challanInfo?.outList.fold<int>(0, (sum, element) => element.batchStatus == 0 ? sum + element.batchQty : sum) ?? 0} Cartons)',
                  Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Out By Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${HiveService.getFName()} ${HiveService.getLName()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
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

  Widget _buildFooterDetailBox(
    String label,
    String qty,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            qty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
