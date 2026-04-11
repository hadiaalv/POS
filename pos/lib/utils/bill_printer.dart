// lib/utils/bill_printer.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import 'constants.dart';

class BillPrinter {
  static Future<void> printBill(CartProvider cart) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(now);

    // Dynamic height calculation
    final double pageHeightMm = 85 + (cart.items.length * 5);

    final pageFormat = PdfPageFormat(
      2.8 * PdfPageFormat.inch,
      pageHeightMm * PdfPageFormat.mm,
      marginLeft: 0.7 * PdfPageFormat.mm,
      marginRight: 0.7 * PdfPageFormat.mm,
      marginTop: 2 * PdfPageFormat.mm,
      marginBottom: 2 * PdfPageFormat.mm,
    );

    final phoneLines = AppConstants.shopPhone
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<pw.Widget> phoneRows = [];
    for (int i = 0; i < phoneLines.length; i += 2) {
      final left = phoneLines[i];
      final right = (i + 1 < phoneLines.length) ? phoneLines[i + 1] : '';
      phoneRows.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(left, style: const pw.TextStyle(fontSize: 7.5)),
            if (right.isNotEmpty) ...[
              pw.SizedBox(width: 6), // Reduced spacing between numbers
              pw.Text(right, style: const pw.TextStyle(fontSize: 7.5)),
            ]
          ],
        ),
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 0.7 * PdfPageFormat.mm),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    AppConstants.shopName,
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    AppConstants.shopAddress,
                    style: const pw.TextStyle(fontSize: 7.5),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),

                  ...phoneRows,

                  _divider(),

                  // Customer details - compact and centered
                  pw.Text('Date: $dateStr',
                      style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('Name: ${cart.customerName}',
                      style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('Phone: ${cart.customerPhone}',
                      style: const pw.TextStyle(fontSize: 7.5)),
                  if (cart.customerAddress.trim().isNotEmpty)
                    pw.Text('Addr: ${cart.customerAddress}',
                        style: const pw.TextStyle(fontSize: 7.5),
                        textAlign: pw.TextAlign.center),

                  _divider(),

                  // Table Header - Flex adjusted for tight fit
                  pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 4,
                          child: pw.Text('Item',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('Qty',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('Total',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.SizedBox(height: 1),

                  // Item List
                  ...cart.items.map((item) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                                flex: 4,
                                child: pw.Text(item.name,
                                    style: const pw.TextStyle(fontSize: 7.5),
                                    softWrap: true,
                                    overflow: pw.TextOverflow.clip)),
                            pw.Expanded(
                                flex: 2,
                                child: pw.Text('${item.quantity}',
                                    style: const pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center)),
                            pw.Expanded(
                                flex: 2,
                                child: pw.Text(item.total.toStringAsFixed(0),
                                    style: const pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.right)),
                          ],
                        ),
                      )),

                  _divider(),

                  _row('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                  _row('Delivery',
                      'Rs. ${cart.deliveryCharges.toStringAsFixed(0)}'),
                  pw.SizedBox(height: 1),
                  _row('TOTAL', 'Rs. ${cart.total.toStringAsFixed(0)}',
                      bold: true, fontSize: 10),

                  _divider(),

                  pw.Text(
                    AppConstants.thankYouMsg,
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Bill_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
    );
  }

  static pw.Widget _divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Divider(thickness: 0.5),
      );

  static pw.Widget _row(String label, String value,
      {bool bold = false, double fontSize = 7.5}) {
    final style = bold
        ? pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)
        : pw.TextStyle(fontSize: fontSize);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }
}
