import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';
import '../models/user.dart';
import 'currency.dart';
import 'order_ref.dart';

const _gold = PdfColor.fromInt(0xFFC17F00);
const _goldSurface = PdfColor.fromInt(0xFFF7EFD9);
const _ink = PdfColor.fromInt(0xFF1F1B13);
const _muted = PdfColor.fromInt(0xFF7A7263);
const _divider = PdfColor.fromInt(0xFFE8DEC7);

final _labelStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _muted, letterSpacing: 1);
final _mutedStyle = const pw.TextStyle(fontSize: 10, color: _muted);
final _boldStyle = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink);

Future<Uint8List> buildInvoicePdf({required Order order, User? user}) async {
  final doc = pw.Document();
  final logoBytes = await rootBundle.load('assets/branding/icon.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(logo),
          pw.SizedBox(height: 24),
          _billingRow(order, user),
          pw.SizedBox(height: 24),
          _itemsTable(order),
          pw.SizedBox(height: 16),
          pw.Align(alignment: pw.Alignment.centerRight, child: _summary(order)),
          pw.SizedBox(height: 40),
          _footer(),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _header(pw.MemoryImage logo) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.ClipOval(child: pw.Image(logo, height: 44, width: 44, fit: pw.BoxFit.cover)),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'THE SHOOLINS',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 3, color: _ink),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Fashion & Ethnic Wear', style: _mutedStyle),
            ],
          ),
        ],
      ),
      pw.Text(
        'TAX INVOICE',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 1),
      ),
    ],
  );
}

pw.Widget _billingRow(Order order, User? user) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(color: _goldSurface, borderRadius: pw.BorderRadius.circular(6)),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BILLED TO', style: _labelStyle),
            pw.SizedBox(height: 4),
            pw.Text((user?.name.isNotEmpty ?? false) ? user!.name : 'Guest', style: _boldStyle),
            pw.Text('+91 ${user?.mobile ?? '-'}', style: _mutedStyle),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('INVOICE NO.', style: _labelStyle),
            pw.Text('#${shortOrderRef(order.id)}', style: _boldStyle),
            pw.SizedBox(height: 8),
            pw.Text('DATE', style: _labelStyle),
            pw.Text(_formatDate(order.createdAt), style: _boldStyle),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _itemsTable(Order order) {
  return pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(4),
      1: pw.FlexColumnWidth(1.2),
      2: pw.FlexColumnWidth(1.6),
      3: pw.FlexColumnWidth(1.6),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _gold),
        children: [
          _cell('ITEM', header: true),
          _cell('QTY', header: true, align: pw.TextAlign.center),
          _cell('RATE', header: true, align: pw.TextAlign.right),
          _cell('AMOUNT', header: true, align: pw.TextAlign.right),
        ],
      ),
      for (final item in order.items)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _divider)),
          ),
          children: [
            _cell(item.name),
            _cell('${item.quantity}', align: pw.TextAlign.center),
            _cell(formatInr(item.price), align: pw.TextAlign.right),
            _cell(formatInr(item.lineTotal), align: pw.TextAlign.right),
          ],
        ),
    ],
  );
}

pw.Widget _cell(String text, {bool header = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: header ? PdfColors.white : _ink,
        letterSpacing: header ? 0.6 : 0,
      ),
    ),
  );
}

pw.Widget _summary(Order order) {
  return pw.SizedBox(
    width: 220,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _summaryRow('Subtotal', formatInr(order.total)),
        _summaryRow('Shipping', 'Free'),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Divider(color: _divider),
        ),
        _summaryRow('Total', formatInr(order.total), bold: true),
      ],
    ),
  );
}

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: bold ? _boldStyle : _mutedStyle),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bold ? 14 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold ? _gold : _ink,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _footer() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Divider(color: _divider),
      pw.SizedBox(height: 8),
      pw.Text(
        'Thank you for shopping with The Shoolins',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'This is a computer-generated invoice and does not require a signature.',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
