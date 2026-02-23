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
    final currencyFormat = NumberFormat('#,##0.00');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm, // 80mm thermal printer width
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Center(
                child: pw.Text(
                  AppConstants.shopName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  AppConstants.shopAddress,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  AppConstants.shopPhone,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 4),
              _divider(),

              // ── Customer Info ──
              pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Customer: ${cart.customerName}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Phone: ${cart.customerPhone}', style: const pw.TextStyle(fontSize: 8)),
              if (cart.customerAddress.isNotEmpty)
                pw.Text('Address: ${cart.customerAddress}', style: const pw.TextStyle(fontSize: 8)),
              _divider(),

              // ── Items ──
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              _divider(),

              ...cart.items.map((item) => pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Expanded(
                    child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(currencyFormat.format(item.price), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(currencyFormat.format(item.total), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              )),

              _divider(),

              // ── Totals ──
              _totalsRow('Subtotal', currencyFormat.format(cart.subtotal)),
              _totalsRow('Delivery', currencyFormat.format(cart.deliveryCharges)),
              pw.SizedBox(height: 2),
              _totalsRow(
                'TOTAL',
                'Rs. ${currencyFormat.format(cart.total)}',
                bold: true,
                fontSize: 10,
              ),
              _divider(),

              // ── Footer ──
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  AppConstants.thankYouMsg,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bill_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
    );
  }

  static pw.Widget _divider() {
    return pw.Column(children: [
      pw.SizedBox(height: 2),
      pw.Divider(thickness: 0.5),
      pw.SizedBox(height: 2),
    ]);
  }

  static pw.Widget _totalsRow(String label, String value, {bool bold = false, double fontSize = 8}) {
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