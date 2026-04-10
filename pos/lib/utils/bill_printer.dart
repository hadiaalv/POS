// lib/utils/bill_printer.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import 'constants.dart';

class BillPrinter {
  static Future<void> printBill(CartProvider cart, {int copies = 2}) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(now);
    final int safeCopies = copies < 1 ? 1 : copies;
    final double pageHeightMm = 90 + cart.items.length * 5;
    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      pageHeightMm * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    );

    // Split into individual numbers
    final phoneLines = AppConstants.shopPhone
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Pair them up: [0,1] on row 1, [2,3] on row 2
    final List<pw.Widget> phoneRows = [];
    for (int i = 0; i < phoneLines.length; i += 2) {
      final left = phoneLines[i];
      final right = (i + 1 < phoneLines.length) ? phoneLines[i + 1] : '';
      phoneRows.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                left,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
            if (right.isNotEmpty)
              pw.Expanded(
                child: pw.Text(
                  right,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    for (var copyIndex = 0; copyIndex < safeCopies; copyIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Shop name
                pw.Text(
                  AppConstants.shopName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 1),

                // Address
                pw.Text(
                  AppConstants.shopAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 0.5),

                // Phone numbers — 2 per row
                ...phoneRows,

                pw.SizedBox(height: 1),
                _divider(),

                // Customer info
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Date: $dateStr',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Name: ${cart.customerName}',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Phone: ${cart.customerPhone}',
                          style: const pw.TextStyle(fontSize: 8)),
                      if (cart.customerAddress.trim().isNotEmpty)
                        pw.Text('Address: ${cart.customerAddress}',
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                _divider(),

                // Items header
                pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 5,
                        child: pw.Text('Item',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Qty',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text('Total',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
                _divider(),

                // Items
                ...cart.items.map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                              flex: 5,
                              child: pw.Text(item.name,
                                  style: const pw.TextStyle(fontSize: 8))),
                          pw.Expanded(
                              flex: 2,
                              child: pw.Text('${item.quantity}',
                                  style: const pw.TextStyle(fontSize: 8),
                                  textAlign: pw.TextAlign.center)),
                          pw.Expanded(
                              flex: 3,
                              child: pw.Text(item.total.toStringAsFixed(0),
                                  style: const pw.TextStyle(fontSize: 8),
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
                    bold: true, fontSize: 11),
                _divider(),

                pw.SizedBox(height: 1),
                pw.Text(
                  AppConstants.thankYouMsg,
                  style:
                      pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'DKFoods_Bill_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
    );
  }

  static pw.Widget _divider() => pw.Column(children: [
        pw.SizedBox(height: 1),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 1),
      ]);

  static pw.Widget _row(String label, String value,
      {bool bold = false, double fontSize = 8}) {
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
