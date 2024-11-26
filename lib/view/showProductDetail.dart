import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myapp/system/info.dart'; // อิมพอร์ตไฟล์ที่มี Info()
import 'package:myapp/model/user.dart';
import 'package:flutter/scheduler.dart';

import '../model/loading.dart';

class ShowProductDetail extends StatefulWidget {
  final Map<String, dynamic> product; // รับข้อมูล product แบบ Map
  final String selectedType; // รับประเภทที่เลือก

  const ShowProductDetail({
    Key? key,
    required this.product,
    required this.selectedType,
  }) : super(key: key);

  @override
  State<ShowProductDetail> createState() => _ShowProductDetailState();
}

class _ShowProductDetailState extends State<ShowProductDetail>
    with TickerProviderStateMixin {
  Map<String, dynamic>? productDetails;
  bool isLoading = true;

  var user = User();
  bool isLogin = false;
  var selectedType = "";
  var fullname = "";
  var branch_code = "";
  var brance_name = "";
  var select_branch_code = "";
  var select_branch_name = "";
  Map<int, bool> showAllLotsMap = {}; // สถานะสำหรับแต่ละ variant

  List<Map<String, dynamic>> _premiumData = [];
  TabController? _premiumTabController;

  @override
  void initState() {
    super.initState();
    getUsers().then((_) {
      _fetchProductDetails(widget.product['product_name']);
    });
  }

  Future<void> getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      branch_code = user.brance_code;
      brance_name = user.brance_name;
      select_branch_code = user.select_branch_code;
      select_branch_name = user.select_branch_name;
      selectedType = widget.selectedType;
      print('selectedType: $selectedType');
      print('branch_code: $branch_code');
      print('select_branch_code: $select_branch_code');
      print('select_branch_name: $select_branch_name');
    });
  }

  List<Widget> _buildBlockData(Map<String, dynamic> product,
      List<dynamic> premium, String selectedType) {
    List<dynamic>? promotion = [];
    Map<String, dynamic>? installment = {};
    final formatter = NumberFormat('#,##0.00');
    final data = product['branch_details'];

    // ตรวจสอบ selectedType และดึงข้อมูล promotion ตามประเภทที่เลือก
    if (selectedType == 'flash_sale') {
      promotion = data['promotions_flash_sale'];
      installment = data['installment_plans_Flash_Sale'];
    } else if (selectedType == 'flash_sale_secondary') {
      promotion = data['promotions_flash_sale_second'];
      installment = data['installment_plans_Flash_Sale_Second'];
    } else if (selectedType == 'general_secondary') {
      promotion = data['promotions_second'];
      installment = data['installment_plans_second'];
    } else {
      promotion = data['promotions_main'];
      installment = data['installment_plans_main'];
      print('installment: $installment');
    }
    return [
      Text(
        product['product_name'] ?? '',
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
      ),
      // brand
      Row(
        children: [
          Text(
            'แบรนด์: ${product['brand'] ?? '-'}',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Kanit',
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      Text.rich(
        TextSpan(
          children: [
            if (promotion != null && promotion.isNotEmpty) ...[
              TextSpan(
                children: () {
                  double rrp = double.tryParse(
                          promotion![0]['price_rrp'].replaceAll(',', '')) ??
                      0;
                  double netSellingPrice = double.tryParse(promotion[0]
                              ['netselling_price']
                          .replaceAll(',', '')) ??
                      0;

                  // print('price_rrp: ${promotion[0]['price_rrp']}');
                  // print(
                  //     'netselling_price: ${promotion[0]['netselling_price']}');

                  if (rrp != netSellingPrice) {
                    return [
                      if (rrp != 0.00)
                        TextSpan(
                          text: '฿${formatter.format(rrp)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Kanit',
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (netSellingPrice != 0.00)
                        TextSpan(
                          text: ' ฿${formatter.format(netSellingPrice)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Kanit',
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (rrp > netSellingPrice)
                        TextSpan(
                          text:
                              ' -${_calculateDiscountPercentage(rrp, netSellingPrice)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            color: Colors.red,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ];
                  } else {
                    return [
                      if (netSellingPrice != 0.00)
                        TextSpan(
                          text: ' ฿${formatter.format(netSellingPrice)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Kanit',
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ];
                  }
                }(),
              ),
            ] else ...[
              if (product['price'] != null && product['price'] != '0.00')
                TextSpan(
                  text:
                      ' ฿${formatter.format(double.tryParse(product['price'].replaceAll(',', '')) ?? 0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Kanit',
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ],
        ),
      ),
      SizedBox(height: 16),
      _buildVariantsSection(product),
      SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'การรับประกัน',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Kanit',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildProductWarrantyAndProtection(promotion),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'โปรโมชั่นบัตรเครดิต:',
                style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
              ),
            ],
          ),
          SizedBox(height: 8),
          installment != null && installment.isNotEmpty
              ? _buildPromotionList(installment)
              : Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 16,
                      // color: Colors.grey,
                    ),
                  ),
                ),
        ],
      ),
      const SizedBox(height: 16),
      // รายการของแถม
      Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.orange),
          SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'รายการของแถม: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Kanit',
                  ),
                ),
                TextSpan(
                  text: '(เลือกได้กลุ่มละ 1 อย่าง)',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Kanit',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      SizedBox(height: 8),
      _buildOptionSetList(promotion),
      const SizedBox(height: 16),

      // กลุ่มรายการของแถม
      Row(
        children: [
          Icon(Icons.format_list_bulleted, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'กลุ่มรายการของแถม:',
            style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
          ),
        ],
      ),
      SizedBox(height: 8),
      _buildPremiumTabBar(),
      const SizedBox(height: 16),

      // Note:
      Row(
        children: [
          Icon(Icons.event_note, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'Note:',
            style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
          ),
        ],
      ),
      SizedBox(height: 8),
      _buildNoteData(promotion),
      const SizedBox(height: 16),
      // ของแถมเพิ่ม TG:
      Row(
        children: [
          Icon(Icons.event_note, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'ของแถมเพิ่ม TG:',
            style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
          ),
        ],
      ),
      SizedBox(height: 8),
      _buildNoteTG(promotion),
      const SizedBox(height: 16),
      // ของแถมแบรนด์ทุกช่องทาง:
      Row(
        children: [
          Icon(Icons.event_note, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'ของแถมแบรนด์ทุกช่องทาง:',
            style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
          ),
        ],
      ),
      SizedBox(height: 8),
      _buildNoteGiftBrand(promotion),
    ];
  }

  Widget _buildVariantsSection(Map<String, dynamic> product) {
    if (product['variants'] == null || product['variants'] is! List) {
      return Center(
        child: Text(
          'ไม่มีตัวเลือกสินค้า',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: (product['variants'] as List).asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> variant = entry.value;

        // เรียง lot_info ตาม days_since_received จากมากไปน้อย
        if (variant['lot_info'] != null && variant['lot_info'] is List) {
          (variant['lot_info'] as List).sort((a, b) =>
              (b['days_since_received'] as int?)
                  ?.compareTo(a['days_since_received'] as num) ??
              0);
        }

        List<dynamic> lotInfo = variant['lot_info'] ?? [];
        int initialLotsToShow = 2; // จำนวนเริ่มต้นที่จะแสดง

        // กำหนดค่าสถานะสำหรับ variant ปัจจุบัน
        bool showAllLots = showAllLotsMap[index] ?? false;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อและจำนวนคงเหลือของตัวเลือกสินค้า
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.color_lens_outlined,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          variant['variant'] ?? '-',
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'คงเหลือ: ${variant['remaining_qty'] ?? '-'} ชิ้น',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // บาร์โค้ดและบาร์โค้ด BigC ถ้ามี
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcode: ${variant['barcode'] ?? '-'}',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (variant['barcode_bigc'] != null &&
                        variant['barcode_bigc'].toString().isNotEmpty)
                      Text(
                        'BigC: ${variant['barcode_bigc']}',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lot Information (ถ้ามี)
                if (lotInfo.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Serial Number',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              // color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            'DOH in Company',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              // color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: lotInfo
                              .take(showAllLots
                                  ? lotInfo.length
                                  : initialLotsToShow)
                              .map((lot) {
                            String lotName = lot['lot_name'] ?? 'No Serial';
                            String daysSinceReceived =
                                lot['days_since_received'] != null
                                    ? '${lot['days_since_received']} วัน'
                                    : '-';

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2.0,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 12.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lotName,
                                        style: TextStyle(
                                          fontFamily: 'Kanit',
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        daysSinceReceived,
                                        style: TextStyle(
                                          fontFamily: 'Kanit',
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (lotInfo.length > initialLotsToShow)
                        Align(
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: Icon(
                              showAllLots
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                showAllLotsMap[index] =
                                    showAllLotsMap[index] ?? false;
                                showAllLotsMap[index] = !showAllLotsMap[index]!;
                              });
                            },
                          ),
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

  Widget _buildProductWarrantyAndProtection(List<dynamic>? promotions) {
    var promotionsData =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // ทำให้การ์ดเป็นสีขาว
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, size: 24, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'ประกัน:',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  promotionsData != null &&
                          promotionsData['warranty2years'] != null
                      ? promotionsData['warranty2years']
                      : '-',
                  style: TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phonelink_erase, size: 24, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'ประกันจอแตก:',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  promotionsData != null &&
                          promotionsData['brokenscreen'] != null
                      ? promotionsData['brokenscreen']
                      : '-',
                  style: TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionList(Map<String, dynamic> installmentPlans) {
    List<Widget> promotionsList = [];

    installmentPlans.forEach((percentage, value) {
      var banks = value['banks'];

      promotionsList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'ดอกเบี้ย: $percentage%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'Kanit',
            ),
          ),
        ),
      );

      final formatter = NumberFormat('#,##0'); // Formatter for number

      promotionsList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit',
                      color: Colors.grey[700],
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
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
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
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'บาท/เดือน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit',
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      promotionsList.add(Column(
        children: banks.map<Widget>((bank) {
          String code = bank['code']?.trim() ?? '-';
          code = code.isEmpty ? '-' : code;

          var plans = bank['plans'];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Image.network(
                                  'https://arnold.tg.co.th:3001${bank['image']['image']}',
                                  height: 30,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image, size: 30);
                                  },
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  bank['image']['fullname'] ?? '',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Kanit',
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              code,
                              style: TextStyle(
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
                              plans != null && plans.isNotEmpty
                                  ? plans[0]['months'] ?? '-'
                                  : '-',
                              style: TextStyle(
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
                              plans != null && plans.isNotEmpty
                                  ? (plans[0]['ppm'] != null
                                      ? '${formatter.format(plans[0]['ppm'] is String ? double.tryParse(plans[0]['ppm']) ?? 0 : plans[0]['ppm'])}'
                                      : '-')
                                  : '-',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Kanit',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (plans != null && plans.length > 1)
                for (var i = 1; i < plans.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1, child: SizedBox.shrink()), // Placeholder
                        Expanded(
                            flex: 1, child: SizedBox.shrink()), // Placeholder
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              plans[i]['months'] ?? '-',
                              style: TextStyle(
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
                              plans[i]['ppm'] != null
                                  ? '${formatter.format(plans[i]['ppm'] is String ? double.tryParse(plans[i]['ppm']) ?? 0 : plans[i]['ppm'])}'
                                  : '-',
                              style: TextStyle(
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
          );
        }).toList(),
      ));

      promotionsList.add(
        Divider(
          color: Colors.grey,
          thickness: 0.2,
          height: 20,
        ),
      );
    });

    if (promotionsList.isEmpty) {
      promotionsList.add(
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Kanit',
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 400.0, // ความสูงสูงสุดที่ต้องการ
        minHeight: promotionsList.isEmpty
            ? 50.0
            : 100.0, // ความสูงน้อยสุด ถ้าไม่มีข้อมูลจะเป็น 50, มีข้อมูลขั้นต่ำเป็น 100
      ),
      child: Scrollbar(
        thickness: 1,
        child: SingleChildScrollView(
          child: Column(
            children: promotionsList,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    // print('Premium Data: $_premiumData');
    if (_premiumData.isEmpty || _premiumTabController == null) {
      return Center(child: Text('-'));
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft, // จัดตำแหน่ง TabBar ให้อยู่ทางซ้าย
          child: TabBar(
            controller:
                _premiumTabController, // ใช้ premiumTabController สำหรับ Tab ของ premium
            isScrollable: true,
            indicatorColor: Colors.orange.shade600,
            indicatorWeight: 2, // Thin indicator line for a clean look
            labelColor: Colors.orange, // Dark grey for the active tab text
            unselectedLabelColor:
                Colors.grey.shade500, // Lighter grey for inactive tabs
            labelStyle: TextStyle(
              fontSize: 14, // Standard font size
              fontWeight: FontWeight.normal, // No bold text for minimal effect
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14, // Same font size for consistency
              fontWeight:
                  FontWeight.normal, // Normal weight for unselected tabs
            ),
            indicatorSize: TabBarIndicatorSize
                .tab, // Ensure the indicator matches tab width
            tabs: _premiumData.map((group) {
              return Tab(
                child: Text(
                  "กลุ่ม ${group['group_name']}" ?? '-',
                  style: TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller:
                _premiumTabController, // ใช้ premiumTabController สำหรับเนื้อหา Tab ของ premium
            children: _premiumData.map((group) {
              return _buildPremiumGroup(group);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGroup(Map<String, dynamic> group) {
    var products = group['products'] as List;

    if (products.isEmpty) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(fontFamily: 'Kanit', fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Table(
          border: TableBorder.symmetric(
              outside: BorderSide(width: 0, color: Colors.grey.shade300)),
          columnWidths: {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(6), // ใช้ FlexColumnWidth เพื่อแบ่งขนาดคอลัมน์
          },
          // border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              // decoration: BoxDecoration(color: Color(0xfffec5bb)),
              decoration: BoxDecoration(color: Colors.blueAccent[400]),

              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'บาร์โค้ด',
                      style: TextStyle(fontFamily: 'Kanit', color: Colors.white
                          //  fontWeight: FontWeight.bold
                          ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'ชื่อสินค้า',
                      style: TextStyle(fontFamily: 'Kanit', color: Colors.white
                          // fontWeight: FontWeight.bold
                          ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
            for (int index = 0; index < products.length; index++)
              TableRow(
                decoration: BoxDecoration(
                    color: index % 2 == 0
                        ? Colors.white
                        : Color.fromARGB(255, 217, 231, 252)
                    // : Color.fromARGB(255, 250, 236, 225), // สลับสีระหว่างแถว
                    ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        Text(
                          products[index]['barcode'] ?? '-',
                          style: TextStyle(fontSize: 12, fontFamily: 'Kanit'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.5, // แบ่งคอลัมน์ 50%
                      child: Text(
                        products[index]['product_name'] ?? '',
                        style: TextStyle(fontSize: 12, fontFamily: 'Kanit'),
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchProductDetails(String productName) async {
    try {
      var usernameKey = Info().userAPIProd;
      var passwordKey = Info().passAPIProd;

      final encodedCredentials =
          base64Encode(utf8.encode('$usernameKey:$passwordKey'));

      print('user.select_branch_code : ${user.select_branch_code}');
      print('productName : $productName');
      final uri =
          Uri.parse(Info().getProductAndPromotion).replace(queryParameters: {
        'product_name': productName,
        'warehouse': user.select_branch_code,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      });
      print('response.statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        var dataJson = json.decode(response.body);
        print('dataJson: $dataJson');
        var product = dataJson['products'][0];
        var premium = dataJson['premium'];
        print('product: $product');
        // print(
        //     'product["branch_details"]: ${product['branch_details']['promotions_main']}');
        // product['branch_details']
        // print('premium: $premium');

        if (premium != null && premium is List && premium.isNotEmpty) {
          setState(() {
            _premiumData = List<Map<String, dynamic>>.from(premium);
            _premiumTabController =
                TabController(length: _premiumData.length, vsync: this);
          });
        }

        setState(() {
          productDetails = product;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (error) {
      print('Error fetching product details: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildNoteData(List<dynamic>? promotions) {
    var promotion =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;
    print('promotion: $promotion');

    if (promotion == null ||
        promotion['note_pm'] == null ||
        promotion['note_pm'].toString().isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text(
                "-",
                style: TextStyle(fontFamily: 'Kanit'),
              )),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: MediaQuery.of(context).size.width,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promotion['note_pm'] != null &&
                      promotion['note_pm'].toString().isNotEmpty
                  ? promotion['note_pm'].toString()
                  : '-',
              style: TextStyle(fontFamily: 'Kanit'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoteGiftBrand(List<dynamic>? promotions) {
    var promotion =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotion == null ||
        promotion['allbrandfreegift'] == null ||
        promotion['allbrandfreegift'].toString().isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text(
                "-",
                style: TextStyle(fontFamily: 'Kanit'),
              )),
            ],
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            promotion['allbrandfreegift'] != null &&
                    promotion['allbrandfreegift'].toString().isNotEmpty
                ? Text(promotion['allbrandfreegift'].toString(),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: 'Kanit'))
                : Center(
                    child: Text(
                      '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Kanit'),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTG(List<dynamic>? promotions) {
    var promotion =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotion == null ||
        promotion['tgfreegift'] == null ||
        promotion['tgfreegift'].toString().isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text(
                "-",
                style: TextStyle(fontFamily: 'Kanit'),
              )),
            ],
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            promotion['tgfreegift'] != null &&
                    promotion['tgfreegift'].toString().isNotEmpty
                ? Text(promotion['tgfreegift'].toString(),
                    style: TextStyle(fontFamily: 'Kanit'))
                : Center(
                    child: Text(
                      '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Kanit'),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSetList(List<dynamic>? promotions) {
    if (promotions == null || promotions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionSetItem('ของแถม 1', '-'),
              _buildOptionSetItem('ของแถม 2', '-'),
              _buildOptionSetItem('ของแถม 3', '-'),
            ],
          ),
        ),
      );
    }

    var promotionData =
        promotions[0]; // ดึงข้อมูล promotion ตัวแรกจาก List promotions

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionSetItem(
              'ของแถม 1',
              promotionData['optionset1'] != null &&
                      promotionData['optionset1'].toString().isNotEmpty
                  ? promotionData['optionset1'].toString()
                  : '-',
            ),
            _buildOptionSetItem(
              'ของแถม 2',
              promotionData['optionset2'] != null &&
                      promotionData['optionset2'].toString().isNotEmpty
                  ? promotionData['optionset2'].toString()
                  : '-',
            ),
            _buildOptionSetItem(
              'ของแถม 3',
              promotionData['optionset3'] != null &&
                      promotionData['optionset3'].toString().isNotEmpty
                  ? promotionData['optionset3'].toString()
                  : '-',
            ),
          ],
        ),
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
            style: TextStyle(
              // fontWeight: FontWeight.bold,
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

  String _calculateDiscountPercentage(double rrp, double netSellingPrice) {
    if (rrp <= 0 || netSellingPrice <= 0) return '0';
    double discount = ((rrp - netSellingPrice) / rrp) * 100;
    return discount.toStringAsFixed(1); // ให้ทศนิยม 1 ตำแหน่ง
  }

  @override
  void dispose() {
    // Dispose the tab controller to avoid memory leaks
    _premiumTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String productName = widget.product['product_name'] ?? 'Unknown Product';
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        // automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFA726), // สีส้มอ่อน
                Color(0xFFFF5722), // สีส้มเข้ม
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'รายละเอียดสินค้า',
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontWeight: FontWeight.w300, // ใช้ตัวอักษรแบบบาง
          ),
        ),
        backgroundColor: Colors.white,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.orange),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: DotLoadingIndicator())
            : productDetails != null
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildBlockData(
                          productDetails!, _premiumData, selectedType),
                    ),
                  )
                : NotFoundPage(),
        // Center(child: Text('ไม่พบข้อมูลสินค้า')),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบข้อมูลสินค้า',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองค้นหาด้วยคำอื่น หรือตรวจสอบคำค้นหา',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ปุ่มสำหรับกลับไปหน้าค้นหา
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.pop(context); // กลับไปหน้าที่แล้ว
            //   },
            //   child: Text(
            //     'กลับไปค้นหา',
            //     style: TextStyle(
            //       fontFamily: 'Kanit',
            //     ),
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.orange, // สีของปุ่ม
            //     padding:
            //         EdgeInsets.symmetric(horizontal: 24, vertical: 12), // ขนาดปุ่ม
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
