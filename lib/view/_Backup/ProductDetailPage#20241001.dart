import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> premiumData;

  const ProductDetailPage({
    Key? key,
    required this.productData,
    required this.premiumData,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _tabControllerContent;
  TabController? _premiumTabController;
  final NumberFormat formatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabControllerContent = TabController(length: 2, vsync: this);

    if (widget.premiumData.isNotEmpty) {
      _premiumTabController =
          TabController(length: widget.premiumData.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _premiumTabController?.dispose();
    _tabControllerContent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productData.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No product data available')),
      );
    }

    final product = widget.productData[0]; // ใช้สินค้าแรกในรายการ productData

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text(product['product_name'] ?? '',
            style: TextStyle(color: Colors.white)),
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
      ),
      body: _buildTabbedContent(product),
    );
  }

  // แสดง TabBar สำหรับ Flash Sale และทั่วไป
  Widget _buildTabbedContent(Map<String, dynamic> product) {
    return DefaultTabController(
      length: 2, // Flash Sale และ ทั่วไป
      child: Column(
        children: [
          TabBar(
            controller: _tabControllerContent,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: const [
              Tab(text: 'Flash Sale'),
              Tab(text: 'ทั่วไป'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabControllerContent,
              children: [
                _buildFlashSaleTab(product),
                _buildGeneralTab(product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับคำนวณส่วนลด
  String _calculateDiscountPercentage(
      double originalPrice, double discountedPrice) {
    if (originalPrice == 0) return '0';
    double discount = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return discount.toStringAsFixed(0); // แสดงผลเป็นจำนวนเต็ม
  }

  // ฟังก์ชันสำหรับการแสดงผลราคาที่ปรับตามโปรโมชั่น
  Widget _buildPriceSection(
      Map<String, dynamic> product, List promotions, NumberFormat formatter) {
    if (promotions.isNotEmpty) {
      double rrp = double.tryParse(
              promotions[0]['price_rrp']?.replaceAll(',', '') ?? '0') ??
          0;
      double netSellingPrice = double.tryParse(
              promotions[0]['netselling_price']?.replaceAll(',', '') ?? '0') ??
          0;

      if (rrp != netSellingPrice) {
        return Row(
          children: [
            if (rrp != 0.00)
              Text(
                '฿${formatter.format(rrp)}',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Kanit',
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '฿${formatter.format(netSellingPrice)}',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Kanit',
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (rrp > netSellingPrice)
              Text(
                ' -${_calculateDiscountPercentage(rrp, netSellingPrice)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Kanit',
                  color: Colors.red,
                ),
              ),
          ],
        );
      } else {
        return Text(
          '฿${formatter.format(netSellingPrice)}',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Kanit',
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      return Text(
        '฿${formatter.format(double.tryParse(product['price']?.replaceAll(',', '') ?? '0'))}',
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Kanit',
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // สร้าง Widget สำหรับเนื้อหา Flash Sale
  Widget _buildFlashSaleTab(Map<String, dynamic> product) {
    // ตรวจสอบว่าข้อมูล promotions_flash_sale เป็น List หรือไม่
    List promotionsFlashSale =
        product['branch_details']?['promotions_flash_sale'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['product_name'] ?? '',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
          ),
          const SizedBox(height: 8),
          _buildPriceSection(product, promotionsFlashSale, formatter),
          const SizedBox(height: 16),
          _buildVariantsSection(product),
          const SizedBox(height: 16),
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
              _buildProductWarrantyAndProtection(product),
            ],
          ),
          const SizedBox(height: 16),

          // โปรโมชั่นบัตรเครดิต
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
          _buildTabBar(product, isFlashSale: true),

          const SizedBox(height: 16),
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
          _buildOptionSetList(product),
          const SizedBox(height: 16),

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
          _buildPremiumTabBarSection(),

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
          _buildNoteData(product),
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
          _buildNoteTG(product),
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
          _buildNoteGiftBrand(product),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // สร้าง Widget สำหรับเนื้อหาทั่วไป
  Widget _buildGeneralTab(Map<String, dynamic> product) {
    // ตรวจสอบว่าข้อมูล promotions_main เป็น List หรือไม่
    // List promotionsMain = product['promotions_main'] ?? [];
    List promotionsMain = product['branch_details']?['promotions_main'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['product_name'] ?? '',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
          ),
          const SizedBox(height: 8),
          _buildPriceSection(product, promotionsMain, formatter),
          const SizedBox(height: 16),
          _buildVariantsSection(product),
          const SizedBox(height: 16),
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
              _buildProductWarrantyAndProtection(product),
            ],
          ),

          const SizedBox(height: 16),

          // โปรโมชั่นบัตรเครดิต
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

          _buildTabBar(product),

          const SizedBox(height: 16),
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
          _buildOptionSetList(product),
          const SizedBox(height: 16),

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
          _buildPremiumTabBarSection(),

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
          _buildNoteData(product),
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
          _buildNoteTG(product),
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
          _buildNoteGiftBrand(product),
          SizedBox(height: 16),
        ],
      ),
    );
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

  Widget _buildProductWarrantyAndProtection(Map<String, dynamic> product) {
    // ตรวจสอบว่าเป็น Flash Sale หรือไม่
    bool isFlashSale = product['branch_details'] != null &&
        product['branch_details']['isFlashSale'] == true;

    // เลือกโปรโมชั่นจาก Flash Sale หรือ Main ตามสถานะ isFlashSale
    var promotions = isFlashSale
        ? product['branch_details']['promotions_flash_sale']
        : product['branch_details']['promotions_main'];

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

  Widget _buildOptionSetList(Map<String, dynamic> product) {
    bool isFlashSale = product['branch_details'] != null &&
        product['branch_details']['isFlashSale'] == true;
    var promotions = isFlashSale
        ? product['branch_details']['promotions_flash_sale']
        : product['branch_details']['promotions_main'];

    var promotionData =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotionData == null) {
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

  // สร้าง TabBar สำหรับข้อมูลพรีเมียม
  Widget _buildPremiumTabBarSection() {
    if (widget.premiumData.isEmpty) {
      return const Center(child: Text('No premium data available'));
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _premiumTabController,
            isScrollable: true,
            indicatorColor: Colors.orange.shade600,
            tabs: widget.premiumData.map((group) {
              return Tab(
                child: Text(
                  "กลุ่ม ${group['group_name']}",
                  style: const TextStyle(fontFamily: 'Kanit', fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _premiumTabController,
            children: widget.premiumData.map((group) {
              return _buildPremiumGroup(group);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // สร้างกลุ่มพรีเมียม
  Widget _buildPremiumGroup(Map<String, dynamic> group) {
    final products = group['products'] as List;

    if (products.isEmpty) {
      return const Center(child: Text('No premium products available'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Table(
          border: TableBorder.symmetric(
              outside: BorderSide(width: 0, color: Colors.grey.shade300)),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(6),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xfffec5bb)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text('บาร์โค้ด',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text('ชื่อสินค้า',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            for (final product in products)
              TableRow(
                decoration: BoxDecoration(
                  color: products.indexOf(product) % 2 == 0
                      ? Colors.white
                      : const Color.fromARGB(255, 250, 236, 225),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(product['barcode'] ?? '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(product['product_name'] ?? '-'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteData(Map<String, dynamic> product) {
    bool isFlashSale = product['branch_details'] != null &&
        product['branch_details']['isFlashSale'] == true;
    var promotions = isFlashSale
        ? product['branch_details']['promotions_flash_sale']
        : product['branch_details']['promotions_main'];

    var promotionData =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotionData == null) {
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
              promotionData['note_pm'] != null &&
                      promotionData['note_pm'].toString().isNotEmpty
                  ? promotionData['note_pm'].toString()
                  : '-',
              style: TextStyle(fontFamily: 'Kanit'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoteGiftBrand(Map<String, dynamic> product) {
    bool isFlashSale = product['branch_details'] != null &&
        product['branch_details']['isFlashSale'] == true;
    var promotions = isFlashSale
        ? product['branch_details']['promotions_flash_sale']
        : product['branch_details']['promotions_main'];

    var promotionData =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotionData == null) {
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
            promotionData['tgfreegift'] != null &&
                    promotionData['tgfreegift'].toString().isNotEmpty
                ? Text(
                    promotionData['tgfreegift']
                        .toString(), // Align left when there's a value,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: 'Kanit'))
                : Center(
                    child: Text(
                      '-', // Center the text when the value is empty
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Kanit'),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTG(Map<String, dynamic> product) {
    bool isFlashSale = product['branch_details'] != null &&
        product['branch_details']['isFlashSale'] == true;
    var promotions = isFlashSale
        ? product['branch_details']['promotions_flash_sale']
        : product['branch_details']['promotions_main'];

    var promotionData =
        promotions != null && promotions.isNotEmpty ? promotions[0] : null;

    if (promotionData == null) {
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
            promotionData['allbrandfreegift'] != null &&
                    promotionData['allbrandfreegift'].toString().isNotEmpty
                ? Text(promotionData['allbrandfreegift'].toString(),
                    style: TextStyle(fontFamily: 'Kanit'))
                : Center(
                    child: Text(
                      '-', // Center the text when the value is empty
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Kanit'),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Map<String, dynamic> product,
      {bool isFlashSale = false}) {
    // ถ้าเป็น FlashSale ไม่ต้องแสดง TabBar
    print('isFlashSale: $isFlashSale');
    print('product: $product');

    if (isFlashSale) {
      print('Flash Sale');
      print(
          "Flash Sale $product['branch_details']['installment_plans_Flash_Sale']");
      return _buildPromotionList(
          product['branch_details']['installment_plans_Flash_Sale']);
    }
    // กรณีที่ไม่ใช่ Flash Sale แสดง TabBar
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 15.0),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orange.shade600, // A subtle grey indicator
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
            tabs: [
              Tab(
                child: Text(
                  'หลัก', // Main tab
                  style: TextStyle(
                    fontFamily:
                        'Kanit', // Replace with your desired font family
                    fontSize: 16, // Adjust font size as needed
                    fontWeight: FontWeight.bold, // Optional: adjust weight
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'รอง', // Secondary tab
                  style: TextStyle(
                    fontFamily:
                        'Kanit', // Replace with your desired font family
                    fontSize: 16, // Adjust font size as needed
                    fontWeight: FontWeight.bold, // Optional: adjust weight
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300, // Adjust based on content
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPromotionList(
                  product['branch_details']['installment_plans_main']),
              _buildPromotionList(
                  product['branch_details']['installment_plans_second']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionList(List<dynamic> installmentPlans) {
    List<Widget> promotionsList = [];

    for (var plan in installmentPlans) {
      var percentage = plan['percentage'];
      var banks = plan['banks'] ?? [];

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

      final formatter = NumberFormat('#,##0');

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

      for (var bank in banks) {
        String code = bank['code']?.trim() ?? '-';
        code = code.isEmpty ? '-' : code;

        promotionsList.add(
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.network(
                          'https://arnold.tg.co.th:3001${bank['image']['image']}',
                          height: 30,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, size: 30);
                          },
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
          ),
        );
      }

      promotionsList.add(
        Divider(
          color: Colors.grey,
          thickness: 0.2,
          height: 20,
        ),
      );
    }

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

    return Scrollbar(
        thickness: 1,
        child: SingleChildScrollView(child: Column(children: promotionsList)));
  }

  Widget _buildPromotionListOLD(Map<String, dynamic> installmentPlans) {
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

      promotionsList.add(
        Column(
          children: banks.map<Widget>((bank) {
            String code = bank['code']?.trim() ?? '-';
            code = code.isEmpty ? '-' : code;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.center,
                          child: Image.network(
                            'https://arnold.tg.co.th:3001${bank['image']['image']}',
                            height: 30,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 30);
                            },
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

    return Scrollbar(
        thickness: 1,
        child: SingleChildScrollView(child: Column(children: promotionsList)));
  }
}
