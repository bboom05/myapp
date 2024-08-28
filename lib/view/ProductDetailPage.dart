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
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
              );
            },
          ),
          title: const Text(
            'รายละเอียดสินค้า',
            style: TextStyle(color: Colors.white, fontFamily: 'Kanit'),
          ),
          backgroundColor: const Color(0xFFFF8C00),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('ไม่มีรายละเอียดสินค้า',
              style: TextStyle(fontFamily: 'Kanit')),
        ),
      );
    }

    final productName = data['product_name'] ?? 'Unknown';
    final variants = data['variants'] as List<dynamic>? ?? [];
    final price = data['price'] ?? '0.00';
    final branchDetails = data['branch_details'] ?? {};
    final formatter = NumberFormat('#,##0.00');
    final totalQty = data['all_qty'] ?? 0; // จำนวนสินค้าทั้งหมด

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productName,
          style: const TextStyle(color: Colors.white, fontFamily: 'Kanit'),
        ),
        backgroundColor: const Color(0xFFFF8C00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8C00),
                fontFamily: 'Kanit',
              ),
            ),
            const SizedBox(height: 16),
            // _buildSectionTitleNoIcon('ราคา'),
            Row(
              children: [
                Text(
                  'ราคา: ',
                  style: const TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit'),
                ),
                Text(
                  '${formatter.format(double.parse(price))} บาท',
                  style: const TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // แสดงตัวเลือกสินค้า
            _buildSectionTitle('ตัวเลือกสินค้า', Icons.shopping_bag),
            _buildVariantsCards(variants),
            const SizedBox(height: 16),
            // แสดงโปรโมชั่นบัตรเครดิต
            _buildSectionTitle('โปรโมชั่นบัตรเครดิต', Icons.credit_card),
            _buildPromotionList(branchDetails),
            const SizedBox(height: 16),
            // แสดงการรับประกัน
            _buildSectionTitle('การรับประกัน', Icons.security),
            _buildWarrantyInfo(branchDetails),
            const SizedBox(height: 16),
            // แสดงของแถม
            _buildSectionTitle('รายการของแถม', Icons.card_giftcard),
            _buildOptionSetList(branchDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitleNoIcon(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Kanit',
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Kanit',
          ),
        ),
      ],
    );
  }

  // ฟังก์ชัน _buildWarrantyInfo ที่หายไป
  Widget _buildWarrantyInfo(Map<String, dynamic> branchDetails) {
    var promotionsMain = branchDetails['promotions_main'] != null &&
            branchDetails['promotions_main'].isNotEmpty
        ? branchDetails['promotions_main'][0]
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, size: 24, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'การรับประกัน:',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  promotionsMain != null &&
                          promotionsMain['warranty2years'] != null
                      ? promotionsMain['warranty2years']
                      : '-',
                  style: const TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phonelink_erase,
                        size: 24, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'ประกันจอแตก:',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  promotionsMain != null &&
                          promotionsMain['brokenscreen'] != null
                      ? promotionsMain['brokenscreen']
                      : '-',
                  style: const TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCards(List<dynamic> variants) {
    if (variants.isEmpty) {
      return const Text('สินค้าหมด', style: TextStyle(fontFamily: 'Kanit'));
    }

    return Column(
      children: variants.map((variant) {
        final variantName = variant['variant'] ?? '-';
        final barcodeVariants = variant['barcode'] ?? '-';
        final remainingQty = variant['remaining_qty'].toString();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4.0,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    variantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Kanit',
                    ),
                  ),
                  Text(
                    'คงเหลือ: $remainingQty ชิ้น',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Barcode: $barcodeVariants',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontFamily: 'Kanit',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromotionList(Map<String, dynamic> branchDetails) {
    List<Widget> promotionsList = [];

    if (branchDetails['installment_plans'] != null) {
      Map<String, dynamic> installmentPlans =
          branchDetails['installment_plans'];

      installmentPlans.forEach((percentage, bankData) {
        promotionsList.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'ดอกเบี้ย: $percentage%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Kanit',
              ),
            ),
          ),
        );

        promotionsList.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kanit',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kanit',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'เดือน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kanit',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        List<dynamic> banks = bankData['banks'];
        banks.forEach((bank) {
          List<dynamic> plans = bank['plans'];

          promotionsList.add(
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Image.network(
                            'https://arnold.tg.co.th:3001${bank['image']}',
                            height: 30,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 30);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            bank['code']?.trim() ?? '-',
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Kanit',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            plans[0]['months'] ?? '-',
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Kanit',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 1; i < plans.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox.shrink()),
                        const Expanded(flex: 1, child: SizedBox.shrink()),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              plans[i]['months'] ?? '-',
                              style: const TextStyle(
                                color: Colors.black,
                                fontFamily: 'Kanit',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });

        promotionsList.add(
          const Divider(
            color: Colors.grey,
            thickness: 0.2,
            height: 20,
          ),
        );
      });
    }

    if (promotionsList.isEmpty) {
      promotionsList.add(
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'ไม่มีโปรโมชั่น',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: 'Kanit',
              ),
            ),
          ),
        ),
      );
    }

    return Column(children: promotionsList);
  }

  Widget _buildOptionSetList(Map<String, dynamic> branchDetails) {
    var promotionsMain = branchDetails['promotions_main'] != null &&
            branchDetails['promotions_main'].isNotEmpty
        ? branchDetails['promotions_main'][0]
        : null;

    if (promotionsMain == null) {
      return const Text('ไม่มีของแถม', style: TextStyle(fontFamily: 'Kanit'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionSetItem('ของแถม 1', promotionsMain['optionset1'] ?? '-'),
          _buildOptionSetItem('ของแถม 2', promotionsMain['optionset2'] ?? '-'),
          _buildOptionSetItem('ของแถม 3', promotionsMain['optionset3'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildOptionSetItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Kanit',
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontFamily: 'Kanit',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
