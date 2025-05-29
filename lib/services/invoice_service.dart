import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';

class InvoiceService {
  static String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  static Future<Map<String, String>> _getSettings() async {
    try {
      final response = await SupabaseConfig.client
          .from('settings')
          .select()
          .in_('name', [
            'store_name',
            'store_address',
            'store_contact',
            'invoice_bank',
            'invoice_bank_account_holder',
            'invoice_account_number',
            'invoice_bank_logo'
          ]);

      final settings = Map<String, String>.fromEntries(
        (response as List).map((item) => 
          MapEntry(item['name'] as String, item['setting_value'] as String)
        ),
      );
      return settings;
    } catch (e) {
      print('Error fetching settings: $e');
      return {};
    }
  }

  static Future<pw.MemoryImage?> _loadImageFromStorage(String? path, String bucket) async {
    if (path == null) return null;
    
    try {
      // Extract filename from full URL if it's a URL
      String filename = path;
      if (path.contains('/')) {
        filename = path.split('/').last;
      }
      
      final response = await SupabaseConfig.client.storage
          .from(bucket)
          .download(filename);
      return pw.MemoryImage(response);
    } catch (e) {
      print('Error loading image from storage ($bucket/$path): $e');
      return null;
    }
  }

  static Future<File> generateInvoice({
    required String orderNumber,
    required String buyerName,
    required String buyerPhone,
    required List<CartItem> items,
    required dynamic subtotal,
    required dynamic tax,
    required dynamic deliveryFee,
    required dynamic total,
    String? notes,
    int? clientId,
  }) async {
    final pdf = pw.Document();
    final settings = await _getSettings();

    // Load logos
    final decremeLogoData = await rootBundle.load('assets/images/decreme_logo-removebg-preview.png');
    final decremeLogo = pw.MemoryImage(decremeLogoData.buffer.asUint8List());

    // Load store logo from clients table
    pw.MemoryImage? storeLogo;
    if (clientId != null) {
      try {
        final clientResponse = await SupabaseConfig.client
            .from('clients')
            .select('logo')
            .eq('id', clientId)
            .single();
        
        if (clientResponse != null && clientResponse['logo'] != null) {
          storeLogo = await _loadImageFromStorage(clientResponse['logo'] as String?, 'decreme');
        }
      } catch (e) {
        print('Error fetching client logo: $e');
      }
    }

    // Load bank logo from settings
    pw.MemoryImage? bankLogo;
    final bankLogoPath = settings['invoice_bank_logo'];
    if (bankLogoPath != null && bankLogoPath.isNotEmpty) {
      bankLogo = await _loadImageFromStorage(bankLogoPath, 'decreme');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logos and title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(decremeLogo, width: 100),
                  if (storeLogo != null)
                    pw.Image(storeLogo, width: 100),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Store Information
              pw.Text(settings['store_name'] ?? '',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(settings['store_address'] ?? ''),
              pw.Text(settings['store_contact'] ?? ''),
              pw.SizedBox(height: 20),

              // Order Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Order #$orderNumber'),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Buyer Information without rectangle
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bill To:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(buyerName),
                  pw.Text(buyerPhone),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Items
                  ...items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.cake.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.quantity.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rp ${formatPrice(item.cake.price)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rp ${formatPrice(item.total)}'),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Subtotal:'),
                        pw.SizedBox(width: 20),
                        pw.Text('Rp ${formatPrice(subtotal)}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Tax (10%):'),
                        pw.SizedBox(width: 20),
                        pw.Text('Rp ${formatPrice(tax)}'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Delivery Fee:'),
                        pw.SizedBox(width: 20),
                        pw.Text('Rp ${formatPrice(deliveryFee)}'),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Total:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 20),
                        pw.Text('Rp ${formatPrice(total)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Notes and Bank Information
              pw.SizedBox(height: 20),
              if (notes != null && notes.isNotEmpty) ...[
                pw.Text('Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(notes),
                pw.SizedBox(height: 20),
              ],

              // Bank Information
              pw.Text('Payment Information:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (bankLogo != null) ...[
                pw.SizedBox(height: 10),
                pw.Image(bankLogo, height: 30),
                pw.SizedBox(height: 10),
              ],
              pw.Text('Bank: ${settings['invoice_bank'] ?? ''}'),
              pw.Text('Account Holder: ${settings['invoice_bank_account_holder'] ?? ''}'),
              pw.Text('Account Number: ${settings['invoice_account_number'] ?? ''}'),

              // Thank you message at the bottom
              pw.Spacer(), // This will push the thank you message to the bottom
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your order!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'We appreciate your business',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Invoice_$orderNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
} 