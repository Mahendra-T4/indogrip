import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:indogrip/core/database/init_box.dart';
import 'package:indogrip/core/database/round_db_hive.dart';
import 'package:indogrip/core/responsive/responsive.dart';
import 'package:indogrip/core/service/connectivity/internate%20connectivity-checker.dart';
import 'package:indogrip/core/service/connectivity/not_connected.dart';
import 'package:indogrip/core/theme/color_conts.dart';
import 'package:indogrip/core/utils/appbar/desktop_appbar.dart';
import 'package:indogrip/core/utils/appbar/mobile_appbar.dart';
import 'package:indogrip/core/utils/sidebar.dart';
import 'package:indogrip/core/utils/widgets/toast_service.dart';
import 'package:indogrip/features/chalan/data/model/round_data_model.dart';
import 'package:indogrip/features/chalan/data/model/round_details_model.dart';
import 'package:indogrip/features/chalan/presentation/page/details/challan_details_page.dart';
import 'package:indogrip/features/chalan/presentation/page/scanned-carton/miss_record.dart';
import 'package:indogrip/features/chalan/presentation/page/scanned-carton/submittion_success_msg.dart';
import 'package:indogrip/features/global/data/repositories/global_manager_repo.dart';
import 'package:indogrip/features/global/presentation/bloc/global_bloc.dart';

class ScannedData {
  final String rKey;
  final String clientKey;

  ScannedData({required this.rKey, required this.clientKey});
}

class ScannedCarton extends StatefulWidget {
  const ScannedCarton({super.key, required this.data});
  // final List<ScanData> scannedItems;
  final ScannedData data;
  static const String routeName = '/scanned-carton';

  @override
  State<ScannedCarton> createState() => _ScannedCartonState();
}

class _ScannedCartonState extends State<ScannedCarton> {
  final GlobalKey<ScaffoldState> statekey = GlobalKey<ScaffoldState>();
  List<String> batchCodes = [];
  List<String> batchQty = [];

  final TextEditingController addScannedBarcodeController =
      TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  late final GlobalBloc _globalBloc;
  bool isShowButton = false;
  @override
  void initState() {
    super.initState();
    log('ScannerView initialized with rKey: ${widget.data.clientKey}');
    _globalBloc = GlobalBloc(globalRepository: GlobalManagerRepository());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      barcodeFocusNode.requestFocus();
    });
    loader();
  }

  Future<void> loader() async {
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    addScannedBarcodeController.dispose();
    barcodeFocusNode.dispose();
    super.dispose();
  }

  int _scannedItemCount = 0;
  int _totalQuantity = 0;
  int _totalScannedCount = 0;
  bool isLoading = true;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: InternetConnectionService().connectionStream,
      initialData: true, // Assume connected initially
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return const NoInternetConnection();
        }

        // Handle disconnected state
        if (snapshot.data == false) {
          return const NoInternetConnection();
        }

        // Handle loading state
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            key: statekey,
            appBar: !Responsive.isDesktop(context)
                ? MobileAppBar(context, statekey, 'Scanned Cartons')
                : DesktopAppBar(context, statekey, 'Scanned Cartons', false),
            drawer: !Responsive.isDesktop(context)
                ? const SideMenuWidget()
                : null,
            body: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading scanned items...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      children: [
                        buildBarcodeField,
                        Expanded(
                          child: ValueListenableBuilder<Box<RoundDataModel>>(
                            valueListenable: Boxes.roundData().listenable(),
                            builder: (context, box, child) {
                              final scannedData = box.values
                                  .toList()
                                  .cast<RoundDataModel>();
                              final scannedDataByKey = scannedData
                                  .where(
                                    (element) =>
                                        element.rKey == widget.data.rKey,
                                  )
                                  .toList()
                                  .reversed
                                  .toList();

                              // ============================================
                              // BLOCK 1: GROUP ITEMS BY BATCH ID
                              // ============================================
                              Map<String, List<RoundDataModel>>
                              groupedByBatchId = {};

                              for (var item in scannedDataByKey) {
                                final batchId = item.batchID ?? 'N/A';

                                if (!groupedByBatchId.containsKey(batchId)) {
                                  groupedByBatchId[batchId] = [];
                                }

                                groupedByBatchId[batchId]!.add(item);
                              }

                              // ============================================
                              // BLOCK 2: CREATE MERGED ITEMS & COUNT DUPLICATES
                              // ============================================
                              final mergedItems = <RoundDataModel>[];
                              final duplicateCounts = <String, int>{};

                              for (var item in scannedDataByKey) {
                                final batchId = item.batchID ?? 'N/A';

                                if (!duplicateCounts.containsKey(batchId)) {
                                  mergedItems.add(item);
                                  duplicateCounts[batchId] =
                                      groupedByBatchId[batchId]!.length;
                                }
                              }

                              final scannedQntByKey = scannedData
                                  .where(
                                    (element) =>
                                        element.quantity.toString() ==
                                        element.quantity,
                                  )
                                  .toList()
                                  .reversed
                                  .toList();

                              _scannedItemCount = mergedItems.length;
                              _totalQuantity = mergedItems.fold(0, (sum, item) {
                                final qty =
                                    int.tryParse(item.quantity ?? '0') ?? 0;
                                return sum + qty;
                              });
                              _totalScannedCount = duplicateCounts.values.fold(
                                0,
                                (sum, count) => sum + count,
                              );

                              // Update state variables without calling setState during build
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    mergedItems.isNotEmpty &&
                                    !isShowButton) {
                                  setState(() {
                                    isShowButton = true;
                                  });
                                }
                              });

                              batchCodes = mergedItems.expand((element) {
                                final batchId =
                                    element.batchID?.split(',').join(',') ?? '';
                                final duplicateCount =
                                    duplicateCounts[element.batchID ?? 'N/A'] ??
                                    1;
                                return List.filled(duplicateCount, batchId);
                              }).toList();
                              batchQty = scannedQntByKey
                                  .map(
                                    (element) =>
                                        element.quantity
                                            ?.split(',')
                                            .join(',') ??
                                        '',
                                  )
                                  .toList();

                              return mergedItems.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(28),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(
                                                    0xFF2D7FD9,
                                                  ).withOpacity(0.12),
                                                  const Color(
                                                    0xFF2D7FD9,
                                                  ).withOpacity(0.06),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF2D7FD9,
                                                ).withOpacity(0.2),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.inbox_rounded,
                                              size: 72,
                                              color: const Color(
                                                0xFF2D7FD9,
                                              ).withOpacity(0.4),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'No Items Scanned Yet',
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF1E3A5F),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Start scanning cartons to populate this list',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                              0.5,
                                          child: ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: mergedItems.length,
                                            itemBuilder: (context, index) {
                                              final item = mergedItems[index];
                                              final duplicateCount =
                                                  duplicateCounts[item
                                                          .batchID ??
                                                      'N/A'] ??
                                                  1;

                                              return _buildCartonCard(
                                                item,
                                                index,
                                                duplicateCount,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            bottomNavigationBar: _buildBottomSubmitBar(),
          ),
        );
      },
    );
  }

  Widget _buildCartonCard(RoundDataModel item, int index, int duplicateCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7FD9).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Theme(
            data: ThemeData(useMaterial3: true),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.97),
                      Colors.white.withOpacity(0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2D7FD9).withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: ExpansionTile(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D7FD9),
                          const Color(0xFF1E5FA8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D7FD9).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.batchCode?.toString() ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A5F),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2D7FD9).withOpacity(0.15),
                              const Color(0xFF2D7FD9).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2D7FD9).withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D7FD9),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (duplicateCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.withOpacity(0.15),
                                Colors.orange.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.content_copy_rounded,
                                size: 12,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'x$duplicateCount',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange.shade600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.white,
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.red.withOpacity(0.2),
                                        Colors.orange.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.warning_rounded,
                                    color: Colors.red.shade600,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Remove Item?',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: const Color(0xFF1E3A5F),
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'This scanned carton will be permanently removed. You cannot undo this action.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(false),
                                child: Text(
                                  'Keep',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => context.pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade500,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (shouldDelete == true) {
                          item.delete();
                          setState(() {
                            _scannedItemCount--;
                            if (_scannedItemCount == 0) {
                              isShowButton = false;
                            }
                          });
                        }
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.red.shade500,
                        size: 24,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 1.2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF2D7FD9).withOpacity(0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Details',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E3A5F),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildDetailGrid(item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailGrid(RoundDataModel item) {
    return Column(
      children: [
        _buildDetailRow2(
          'BatchCode',
          item.batchCode,

          item.productType == 1 ? 'Cut MM Meter' : 'Stretch Weight',
          item.productType == 1 ? item.cutMMMeter : item.stretchWeigh,
        ),
        const SizedBox(height: 12),
        _buildDetailRow2(
          'Mic Label',
          item.micLabel,
          'Base Label',
          item.baseLabel,
        ),
        // const SizedBox(height: 12),
        // _buildDetailRow2('Mic ID', item.micID),
        const SizedBox(height: 12),
        item.productType == 1
            ? _buildDetailRow2(
                item.showFor == '1' ? 'Tape Length' : 'Tape Weight',
                item.showFor == '1' ? item.tapeLength : item.tapeWeight,
                'Round Count',
                item.roundCount,
              )
            : _buildDetailRow2(
                'Operation',
                item.operation,
                'Round Count',
                item.roundCount,
              ),
        // const SizedBox(height: 12),
        // _buildDetailRow2(
        //   'So',
        //  ,
        //   'Tape Weight',
        //   ,
        // ),
        const SizedBox(height: 12),
        _buildDetailRow2(
          item.productType == 1 ? 'Pieces Per Carton' : 'Size',
          item.productType == 1 ? item.piecesPerCarton : item.size,

          'Display MFG',
          item.displayMFG,
        ),
        // const SizedBox(height: 12),
        // _buildDetailRow2('Unit', item.unitName, '', ''),

        // const SizedBox(height: 12),
      ],
    );
  }

  String _convertToString(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value;
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  Widget _buildDetailRow2(
    String label1,
    dynamic value1,
    String label2,
    dynamic value2,
  ) {
    final displayValue1 = _convertToString(value1);
    final displayValue2 = _convertToString(value2);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D7FD9).withOpacity(0.08),
                  const Color(0xFF2D7FD9).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2D7FD9).withOpacity(0.15),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D7FD9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue1,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D7FD9).withOpacity(0.08),
                  const Color(0xFF2D7FD9).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2D7FD9).withOpacity(0.15),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D7FD9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue2,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7FD9).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, -12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, -16),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width * 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D7FD9).withOpacity(0.06),
                    Colors.white.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2D7FD9).withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCANNED ITEMS',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green.withOpacity(0.2),
                                  Colors.green.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalScannedCount Carton${_scannedItemCount != 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: const Color(0xFF1E3A5F),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // if (_totalScannedCount > _scannedItemCount)
                              //   Text(
                              //     'Total scanned: $_totalScannedCount',
                              //     style: GoogleFonts.poppins(
                              //       fontSize: 11,
                              //       color: Colors.orange.shade600,
                              //       fontWeight: FontWeight.w700,
                              //       letterSpacing: 0.2,
                              //     ),
                              //   ),
                              // if (_totalQuantity > 0)
                              //   Text(
                              //     'Total Qty: $_totalQuantity',
                              //     style: GoogleFonts.poppins(
                              //       fontSize: 11,
                              //       color: Colors.blue.shade600,
                              //       fontWeight: FontWeight.w700,
                              //       letterSpacing: 0.2,
                              //     ),
                              //   ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isShowButton) submitButton,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get submitButton => BlocConsumer(
    bloc: _globalBloc,
    listener: (context, state) {
      if (state is SubmitRoundScannedDataSuccessStatus) {
        if (state.model.status == 1) {
          ToastService.instance.showSuccess(
            context,
            state.model.message.toString(),
          );

          GoRouter.of(
            context,
          ).pushNamed(ChallanDetailsPage.routeName, extra: state.model);
          final box = Boxes.roundData();
          box.clear();
        } else {
          ToastService.instance.showError(
            context,
            state.model.message.toString(),
          );
          GoRouter.of(
            context,
          ).pushNamed(ChallanDetailsPage.routeName, extra: state.model);
        }
      }
      if (state is SubmitRoundScannedDataFailureStatus) {
        ToastService.instance.showError(context, state.errorMessage.toString());
      }
    },
    builder: (context, state) {
      if (state is GlobalLoadingStatus) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2D7FD9), const Color(0xFF1E5FA8)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D7FD9).withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D7FD9).withOpacity(0.45),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            _globalBloc.add(
              SubmitRoundScannedDataEvent(
                batchCodes: batchCodes,
                clientKey: widget.data.clientKey,
                unitIndex: '',
                batchQty: batchQty,
                rKey: widget.data.rKey,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D7FD9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: Icon(Icons.send_rounded, color: Colors.white, size: 24),
          iconAlignment: IconAlignment.end,
          label: Text(
            'Submit',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    },
  );

  Widget get buildBarcodeField => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2D7FD9).withOpacity(0.12),
          blurRadius: 30,
          spreadRadius: 4,
          offset: const Offset(0, -12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, -16),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(child: SizedBox()),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: addScannedBarcodeController.text.isNotEmpty
                    ? const Color(0xFF2D8FCF)
                    : const Color(0xFFE5E7EB),
                width: 1.8,
              ),
              boxShadow: addScannedBarcodeController.text.isNotEmpty
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D8FCF).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: addScannedBarcodeController,
              focusNode: barcodeFocusNode,
              onChanged: (value) {
                // Auto-submit when hardware scanner sends newline character
                if (value.endsWith('\n')) {
                  addScannedBarcodeController.text = value
                      .replaceAll('\n', '')
                      .trim();
                  addScannedBarcodeController.selection =
                      TextSelection.fromPosition(
                        TextPosition(
                          offset: addScannedBarcodeController.text.length,
                        ),
                      );
                }
                setState(() {});
              },
              onFieldSubmitted: (_) {
                barcodeFocusNode.requestFocus();
              },
              decoration: InputDecoration(
                hintText: 'Scan barcode...',
                hintStyle: TextStyle(
                  color: const Color(0xFFA0AEC0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: addScannedBarcodeController.text.isNotEmpty
                        ? const Color(0xFF2D8FCF)
                        : const Color(0xFFCBD5E0),
                    size: 22,
                  ),
                ),
                suffixIcon: addScannedBarcodeController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            addScannedBarcodeController.clear();
                          });
                          barcodeFocusNode.requestFocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.close_rounded,
                            color: const Color(0xFF2D8FCF).withOpacity(0.6),
                            size: 22,
                          ),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D8FCF),
                    width: 1.8,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: buildModernAddButton()),
        Expanded(child: SizedBox()),
      ],
    ),
  );

  String _safeValue(dynamic value, {String defaultValue = 'N/A'}) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    if (value is int || value is double) return value.toString();
    return value.toString();
  }

  Widget buildModernAddButton() {
    return BlocConsumer<GlobalBloc, GlobalState>(
      bloc: _globalBloc,
      listenWhen: (previous, current) =>
          current is ChallanRoundDetailsLoadedSuccessStatus ||
          current is ChallanRoundDetailsLoadedFailureStatus,
      listener: (context, state) {
        if (state is ChallanRoundDetailsLoadedSuccessStatus) {
          final roundDetails = state.dataModel;
          if (roundDetails.status == 1) {
            ToastService.instance.showSuccess(
              context,
              roundDetails.message.toString(),
            );
            showRoundDetailsPopDialogBox(roundDetails.record!);
          } else {
            ToastService.instance.showError(
              context,
              roundDetails.message?.toString() ??
                  'Failed to fetch round details',
            );
          }
        } else if (state is ChallanRoundDetailsLoadedFailureStatus) {
          ToastService.instance.showError(context, state.errorMessage);
        }
      },
      builder: (BuildContext context, GlobalState state) {
        final isLoading = state is GlobalLoadingStatus;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: addScannedBarcodeController.text.isNotEmpty
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D8FCF).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: isLoading || addScannedBarcodeController.text.isEmpty
                  ? null
                  : () {
                      if (addScannedBarcodeController.text.isNotEmpty) {
                        _globalBloc.add(
                          FetchRoundDetailsEvent(
                            batchCode: addScannedBarcodeController.text,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: addScannedBarcodeController.text.isNotEmpty
                    ? const Color(0xFF2D7FD9)
                    : const Color(0xFFBFDBFE),
                disabledBackgroundColor: const Color(0xFFBFDBFE),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shadowColor: const Color(0xFF2D8FCF).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Scan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  updateScannedItemCount(int count) {
    setState(() {
      _scannedItemCount = count;
    });
  }

  void showRoundDetailsPopDialogBox(RoundDetailsRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2D7FD9).withOpacity(0.2),
                      const Color(0xFF2D7FD9).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: const Color(0xFF2D7FD9),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Item Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: const Color(0xFF1E3A5F),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard('Tape Information', [
                      if (record.productType == 1) ...[
                        _buildDetailItem(
                          'Cut MM Meter',
                          _safeValue(record.cutMMMeter),
                        ),
                        _buildDetailItem(
                          'Pieces Per Carton',
                          _safeValue(record.piecesPerCarton),
                        ),
                        _buildDetailItem(
                          'Tape Length',
                          _safeValue(record.tapeLength),
                        ),
                      ],
                      if (record.productType == 2) ...[
                        _buildDetailItem('Size', _safeValue(record.size)),
                        _buildDetailItem(
                          'Stretch Weight',
                          _safeValue(record.stretchWeight),
                        ),
                        _buildDetailItem(
                          'Operation',
                          _safeValue(record.operation),
                        ),
                      ],
                      _buildDetailItem('Base', _safeValue(record.baseLabel)),
                      _buildDetailItem('Mic', _safeValue(record.micLabel)),
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoCard('Information', [
                      _buildDetailItem(
                        'Batch Code',
                        _safeValue(record.batchCode),
                      ),
                      _buildDetailItem('MFG', _safeValue(record.displayMFG)),
                      _buildDetailItem(
                        'Batch Remark',
                        _safeValue(record.batchRemark),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                GoRouter.of(context).pop();
                              },
                              icon: Icon(Icons.refresh_rounded, size: 22),
                              label: Text(
                                'Rescan',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2D7FD9,
                                  ).withOpacity(0.45),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final data = RoundDataModel(
                                  productType: record.productType,
                                  size: record.size.toString(),
                                  stretchWeigh: record.stretchWeight.toString(),
                                  operation: record.operation.toString(),
                                  unitName: '',
                                  unitIndex: '',
                                  rKey: widget.data.rKey.toString(),
                                  baseID: record.baseID.toString(),
                                  piecesPerCarton: record.piecesPerCarton
                                      .toString(),
                                  cutMMMeter: record.cutMMMeter.toString(),
                                  micID: record.micID.toString(),
                                  micLabel: record.micLabel.toString(),
                                  showFor: record.showFor?.toString() ?? '',
                                  tapeLength:
                                      record.tapeLength?.toString() ?? '',
                                  batchRemark:
                                      record.batchRemark?.toString() ?? '',
                                  baseLabel: record.baseLabel?.toString() ?? '',
                                  displayMFG:
                                      record.displayMFG?.toString() ?? '',
                                  displayMFGLabel:
                                      record.displayMFGLabel?.toString() ?? '',
                                  tapeWeight:
                                      record.tapeWeight?.toString() ?? '',
                                  showForLabel: '',
                                  batchID: addScannedBarcodeController.text,
                                  batchCode: record.batchCode?.toString() ?? '',
                                  quantity: '1',
                                );

                                final box = Hive.box<RoundDataModel>(
                                  RoundDBHive.roundBox,
                                );
                                await box.add(data);

                                updateScannedItemCount(_scannedItemCount + 1);

                                if (mounted) {
                                  ToastService.instance.showSuccess(
                                    context,
                                    'Item added successfully!',
                                  );
                                  GoRouter.of(context).pop();
                                }
                              },
                              icon: Icon(Icons.check_circle_rounded, size: 22),
                              label: Text(
                                'Submit',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D7FD9),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7FD9).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.97),
              Colors.white.withOpacity(0.93),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF2D7FD9).withOpacity(0.12),
            width: 1.3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E3A5F),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D7FD9).withOpacity(0.12),
                  const Color(0xFF2D7FD9).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2D7FD9).withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1E3A5F),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
