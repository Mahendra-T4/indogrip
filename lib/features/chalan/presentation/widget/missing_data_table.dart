import 'package:flutter/material.dart';
import 'package:indogrip/features/chalan/data/model/challan_details_model.dart';

class MissingDataTable extends StatelessWidget {
  const MissingDataTable({super.key, required this.orderMissingProduct});
  final List<OrderMissingProduct>? orderMissingProduct;

  @override
  Widget build(BuildContext context) {
    return orderMissingProduct != null && orderMissingProduct!.isNotEmpty
        ? Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              Text(
                'Order Missing Product Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.98,
                child: Table(
                  border: TableBorder.all(color: Colors.black, width: 1.5),
                  columnWidths: {
                    0: FixedColumnWidth(80),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FixedColumnWidth(MediaQuery.sizeOf(context).width * 0.3),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'S.NO.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'BatchID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Applied Quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Available Quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Reason',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...List<TableRow>.generate(orderMissingProduct!.length, (
                      index,
                    ) {
                      final data = orderMissingProduct![index];

                      return TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Center(
                              child: Text(
                                data.sNo?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Center(
                              child: Text(
                                data.mBatchID?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              data.mAppliedQty?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Center(
                              child: Text(
                                data.mAvailableQty?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Center(
                              child: Text(
                                data.mReason?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }, growable: true),
                  ],
                ),
              ),
            ],
          )
        : SizedBox.shrink();
  }
}
