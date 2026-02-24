// lib/utils/bill_printer.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import 'constants.dart';

class BillPrinter {
  static Future<void> printBill(CartProvider cart) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                AppConstants.shopName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(AppConstants.shopAddress, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(AppConstants.shopPhone,   style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              _divider(),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: $dateStr',                     style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Name: ${cart.customerName}',         style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Phone: ${cart.customerPhone}',       style: const pw.TextStyle(fontSize: 8)),
                    if (cart.customerAddress.trim().isNotEmpty)
                      pw.Text('Address: ${cart.customerAddress}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              _divider(),

              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('Item',  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty',   style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              _divider(),

              ...cart.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text(item.name,                     style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 1, child: pw.Text('${item.quantity}',            style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text(item.price.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(item.total.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                  ],
                ),
              )),

              _divider(),
              _row('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
              _row('Delivery', 'Rs. ${cart.deliveryCharges.toStringAsFixed(0)}'),
              pw.SizedBox(height: 2),
              _row('TOTAL', 'Rs. ${cart.total.toStringAsFixed(0)}', bold: true, fontSize: 11),
              _divider(),

              pw.SizedBox(height: 4),
              pw.Text(
                AppConstants.thankYouMsg,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    // No usePrinterSettings parameter = uses the modern Chrome-style preview
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'DKFoods_Bill_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
    );
  }

  static pw.Widget _divider() => pw.Column(children: [
    pw.SizedBox(height: 2),
    pw.Divider(thickness: 0.5),
    pw.SizedBox(height: 2),
  ]);

  static pw.Widget _row(String label, String value, {bool bold = false, double fontSize = 8}) {
    final style = bold
        ? pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)
        : pw.TextStyle(fontSize: fontSize);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label, style: style), pw.Text(value, style: style)],
    );
  }
}
