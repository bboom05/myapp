import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/view/HomeView.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> promotion;

  const ProductDetailPage(
      {super.key, required this.data, required this.promotion});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
              );
            },
          ),
          title: const Text('รายละเอียดสินค้า',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFFF8C00),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('ไม่มีรายละเอียดสินค้า'),
        ),
      );
    }

    final productName = data['product_name'] ?? 'Unknown';
    final barcode = data['barcode'] ?? 'Unknown';
    final warehouse = data['warehouse'] ?? 'Unknown';
    final branchName = data['branch_name'] ?? 'Unknown';
    final category = data['cat3'] ?? 'Unknown';
    final brand = data['brand'] ?? 'Unknown';
    final variants = data['variants'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                productName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8C00),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('รายละเอียดสินค้า', Icons.description),
            const SizedBox(height: 8),
            _buildInfoTile('แบรนด์', brand),
            // _buildInfoTile('บาร์โค้ด', barcode),
            // _buildInfoTile('รหัสสาขา', warehouse),
            _buildInfoTile('สาขา', branchName),
            _buildInfoTile('หมวดหมู่', category),
            const SizedBox(height: 16),
            _buildSectionTitle('ตัวเลือกสินค้า', Icons.shopping_bag),
            const SizedBox(height: 8),
            _buildVariantsCards(variants),
            const SizedBox(height: 10),
            // Container(
            //   child: ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       foregroundColor: Colors.black,
            //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     ),
            //     onPressed: () {
            //       _showModalBottomSheet(context, promotion);
            //     },
            //     child: const Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(Icons.credit_card, color: Colors.green),
            //         SizedBox(width: 8),
            //         Text('ผ่อนบัตรเครดิต'),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showModalBottomSheet(
      BuildContext context, Map<String, dynamic> promotion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ผ่อนบัตรเครดิต',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildPromotionTable(promotion),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotionTable(Map<String, dynamic> promotion) {
    final installmentPlans =
        promotion['installment_plans'] as List<dynamic>? ?? [];

    if (installmentPlans.isEmpty) {
      return const Text('ไม่มีโปรโมชั่น');
    }

    final numberFormat = NumberFormat('#,##0', 'en_US'); // Number formatter

    return Column(
      children: installmentPlans.map((plan) {
        final percentage = plan['percentage'] ?? '-';
        final banks = plan['banks'] as List<dynamic>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'อัตราดอกเบี้ย $percentage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey, width: 0.5),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[400]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'ธนาคาร',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'ระยะเวลา (เดือน)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'ค่างวดต่อเดือน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                ...banks.map((bank) {
                  final bankName = bank['name'] ?? '-';
                  final plans = bank['plans'] as List<dynamic>? ?? [];

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: Text(bankName)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plans.map((plan) {
                            final months = plan['months'] ?? '-';
                            return Center(child: Text('$months เดือน'));
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plans.map((plan) {
                            final monthlyPayment =
                                plan['monthly_payment'] ?? '-';
                            final formattedPayment = numberFormat
                                .format(monthlyPayment); // Format the number
                            return Center(child: Text('$formattedPayment'));
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildVariantsCards(List<dynamic> variants) {
    if (variants.isEmpty) {
      return const Text('สินค้าหมด');
    }

    return Column(
  children: variants.map((variant) {
    final variantName = variant['variant'] ?? '-';
    final barcodeVariants = variant['barcode'] ?? '-';
    final remainingQty = variant['remaining_qty'].toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align all children to the start
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  variantName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'สินค้าคงเหลือ: $remainingQty',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Barcode: $barcodeVariants',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }).toList(),
);

  }
}
