import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myapp/system/info.dart'; // อิมพอร์ตไฟล์ที่มี Info()
import 'package:myapp/model/user.dart';
import 'package:flutter/scheduler.dart';

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
      selectedType = widget.selectedType;
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
    }
    return [
      Text(
        product['product_name'] ?? '',
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
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

                  print('price_rrp: ${promotion[0]['price_rrp']}');
                  print(
                      'netselling_price: ${promotion[0]['netselling_price']}');

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
      return Text('ไม่มีตัวเลือกสินค้า', style: TextStyle(fontFamily: 'Kanit'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: (product['variants'] as List).map((variant) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variant['variant'] ?? '',
                      style: TextStyle(
                          fontFamily: 'Kanit', fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'คงเหลือ: ${variant['remaining_qty'] ?? '-'} ชิ้น',
                      style: TextStyle(fontFamily: 'Kanit', color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcode: ${variant['barcode'] ?? '-'}',
                  style: TextStyle(fontFamily: 'Kanit', color: Colors.black),
                ),
                const SizedBox(height: 4),
                if (variant['barcode_bigc'] != null &&
                    variant['barcode_bigc'].toString().isNotEmpty)
                  Text(
                    'Barcode BigC: ${variant['barcode_bigc'] ?? '-'}',
                    style: TextStyle(fontFamily: 'Kanit', color: Colors.black),
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
            'ดอกเบี้ย: $percentage',
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

      promotionsList.add(
        Column(
          children: banks.map<Widget>((bank) {
            String code = bank['code']?.trim() ?? '-';
            code = code.isEmpty ? '-' : code;
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
                                  SizedBox(
                                    height: 5,
                                  ),
                                  // เพิ่มชื่อธนาคารใต้ icon
                                  Text(
                                    bank['image']['fullname'] ?? '',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Kanit',
                                        fontSize: 10),
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
                                bank['plans'][0]['months'] ?? '-',
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
                                bank['plans'][0]['ppm'] != null
                                    ? '${formatter.format(double.tryParse(bank['plans'][0]['ppm']) ?? 0)}'
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
                for (var i = 1; i < bank['plans'].length; i++)
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
                              bank['plans'][i]['months'] ?? '-',
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
                              bank['plans'][i]['ppm'] != null
                                  ? '${formatter.format(double.tryParse(bank['plans'][i]['ppm']) ?? 0)}'
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
        ),
      );

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
              decoration: BoxDecoration(color: Color(0xfffec5bb)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'บาร์โค้ด',
                      style: TextStyle(
                        fontFamily: 'Kanit',
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
                      style: TextStyle(
                        fontFamily: 'Kanit',
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
                      : Color.fromARGB(255, 250, 236, 225), // สลับสีระหว่างแถว
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

      final uri =
          Uri.parse(Info().getProductAndPromotion).replace(queryParameters: {
        'product_name': productName,
        'warehouse': branch_code,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      });
      print('response.statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        var dataJson = json.decode(response.body);
        var product = dataJson['products'][0];
        var premium = dataJson['premium'];

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

    if (promotion == null) {
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

    if (promotion == null) {
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

    if (promotion == null) {
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
            ? Center(child: CircularProgressIndicator())
            : productDetails != null
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildBlockData(
                          productDetails!, _premiumData, selectedType),
                    ),
                  )
                : Center(child: Text('Product details not found')),
      ),
    );
  }
}
