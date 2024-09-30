import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/HeaderHome.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../system/info.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TabController? _premiumTabController;
  final _selectedColor = Color(0xffFF8C00);
  final _unselectedColor = Color(0xff5f6368);
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  final formKeyBranch = GlobalKey<FormState>();
  final searchBranch = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _timer;

  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";
  var query = "";

  List<Tag> tags = [];
  List<Map<String, dynamic>> _productData = [];
  List<Map<String, dynamic>> _allProductData = [];
  List<Map<String, dynamic>> _nearbyBranches = [];
  List<Map<String, dynamic>> _premiumData = [];
  bool isLoading = false;
  bool isBranchLoading = false;

  final List<Color> pastelColors = [
    Color(0xFFFF6F61),
    Color(0xFFFFB347),
    Color(0xFFFFD700),
    Color(0xFF00BFFF),
    Color(0xFF9370DB),
    Color(0xFFFF69B4),
    Color(0xFFFFA07A),
    Color(0xFF20B2AA),
    Color(0xFF8A2BE2),
  ];

  Set<String> _loggedProducts = Set<String>();

  @override
  void initState() {
    print("app start");
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    getUsers().then((_) {
      _loadInitialData();
    });

    // fetchNearbyBranches();
    // fetchPremiumData();
    _timer = Timer.periodic(Duration(seconds: 10), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= 3) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _premiumTabController?.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchNearbyBranches() async {
    setState(() {
      isBranchLoading = true;
    });
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _nearbyBranches = [
        {'branch_name': 'สาขาใกล้เคียง 1', 'branch_code': '001'},
        {'branch_name': 'สาขาใกล้เคียง 2', 'branch_code': '002'},
        {'branch_name': 'สาขาใกล้เคียง 3', 'branch_code': '003'},
        {'branch_name': 'สาขาใกล้เคียง 4', 'branch_code': '004'},
        {'branch_name': 'สาขาใกล้เคียง 5', 'branch_code': '005'},
      ];
      isBranchLoading = false;
    });
  }

  Future<void> getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
    });
  }

  Future<void> _loadInitialData() async {
    _search();
  }

  void _onTagClick(Tag tag) {
    setState(() {
      tag.isSelected = !tag.isSelected;
    });
    _filterProducts();
  }

// ค้นหา iphone apple 15 pro max 12 จะไม่เจออะไรเลย
  void _filterProducts() {
    setState(() {
      isLoading = true;
    });

    List<String> selectedTags =
        tags.where((tag) => tag.isSelected).map((tag) => tag.name).toList();
    String searchQuery = searchBranch.text.toLowerCase().trim();

    // แยกคำค้นหาที่มากกว่าหนึ่งคำ
    List<String> searchTerms = searchQuery.split(' ');

    _productData = _allProductData.where((product) {
      // ตรวจสอบการจับคู่คำค้นหาทุกคำ
      bool matchesQuery = searchTerms.every((term) {
        var productName = product['product_name'].toString().toLowerCase();

        // เปรียบเทียบด้วย contains() และ startsWith() เพื่อความยืดหยุ่น
        return productName.contains(term) || productName.startsWith(term);
      });

      // ตรวจสอบการจับคู่ Tags
      bool matchesTags = selectedTags.isEmpty ||
          selectedTags.contains(product['brand'].toString());

      return matchesQuery && matchesTags;
    }).toList();

    setState(() {
      isLoading = false;
    });
  }

  void _search() async {
    setState(() {
      isLoading = true;
    });

    List<String> selectedTags =
        tags.where((tag) => tag.isSelected).map((tag) => tag.name).toList();
    String searchQuery = searchBranch.text;
    Map<String, dynamic> data = {
      'product_name': searchQuery,
      'tags': selectedTags,
      'warehouse': brance_code,
    };
    print("data ${data}");
    await _sendSearchData(data);
  }

  Future<void> _sendSearchData(Map<String, dynamic> data) async {
    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    final uri = Uri.parse(Info().allProduct).replace(queryParameters: {
      'product_name': data['product_name'],
      'tags': data['tags'].join(','),
      'warehouse': data['warehouse'],
    });

    final response = await http.get(uri, headers: {
      'Authorization': 'Basic $encodedCredentials',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      var rs = json.decode(response.body);
      if (rs is List && rs.isNotEmpty) {
        setState(() {
          _allProductData = List<Map<String, dynamic>>.from(rs);
          _productData = _allProductData;
          _generateTags();
          isLoading = false;
        });
      } else if (rs is Map && rs.containsKey('data')) {
        setState(() {
          _allProductData = List<Map<String, dynamic>>.from(rs['data']);
          _productData = _allProductData;
          _generateTags();
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateTags() {
    Map<String, int> brandCount = {};
    for (var product in _allProductData) {
      String brand = product['brand'] ?? 'Unknown';
      if (brand != 'Unknown') {
        if (brandCount.containsKey(brand)) {
          brandCount[brand] = brandCount[brand]! + 1;
        } else {
          brandCount[brand] = 1;
        }
      }
    }

    setState(() {
      tags = [];
      int index = 0;
      brandCount.forEach((brand, count) {
        tags.add(Tag(
          name: brand,
          quantity: count,
          color: pastelColors[index % pastelColors.length],
        ));
        index++;
      });
    });
  }

  Future<void> _showProductDetails(String productName) async {
    final formatter = NumberFormat('#,##0.00');

    await _logActivity(
      employeeCode: user.employee_code,
      branchCode: user.brance_code,
      model: productName,
      activityType: 'click_product',
      detailSearch: searchBranch.text,
      tagsBrand:
          tags.where((tag) => tag.isSelected).map((tag) => tag.name).join(','),
    );

    var usernameKey = Info().userAPIProd;
    var passwordKey = Info().passAPIProd;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    final uri =
        Uri.parse(Info().getProductAndPromotion).replace(queryParameters: {
      'product_name': productName,
      'warehouse': brance_code,
    });

    final response = await http.get(uri, headers: {
      'Authorization': 'Basic $encodedCredentials',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      var dataJson = json.decode(response.body);
      var product = dataJson['products'][0];

      if (dataJson.containsKey('premium')) {
        setState(() {
          _premiumData = List<Map<String, dynamic>>.from(dataJson['premium']);
          _premiumTabController =
              TabController(length: _premiumData.length, vsync: this);
        });
      }
      var branchDetails = product['branch_details'];
      var promotionsMain = branchDetails['promotions_main'] ?? [];
      var promotionsFlashSale = branchDetails['promotions_flash_sale'] ?? [];

      var installmentPlansFlashSale =
          branchDetails['installment_plans_flash_sale'] ?? [];
      var isFlashSale = branchDetails['isFlashSale'] ?? false;

      if (dataJson['products'] != null && dataJson['products'].isNotEmpty) {
        if (product != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            builder: (context) {
              return FractionallySizedBox(
                heightFactor: 0.9,
                child: isFlashSale
                    ? _buildTabbedContent(
                        product,
                        promotionsMain,
                        promotionsFlashSale,
                        installmentPlansFlashSale,
                        formatter)
                    : _buildGeneralTab(product, promotionsMain, formatter),
              );
            },
          );
        }
      }
    }
  }

// สร้าง Widget ที่มี TabBar สำหรับ Flash Sale และทั่วไป
  Widget _buildTabbedContent(
      Map<String, dynamic> product,
      List promotionsMain,
      List promotionsFlashSale,
      List installmentPlansFlashSale,
      NumberFormat formatter) {
    return DefaultTabController(
      length: 2, // มีสองแท็บใหญ่: Flash Sale และ ทั่วไป
      child: Column(
        children: [
          // Header ของ TabBar ใหญ่
          TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(
                child: Text(
                  'Flash Sale',
                  style: TextStyle(
                    fontFamily: 'Kanit', // เพิ่ม fontFamily ที่นี่
                    fontSize: 16, // ขนาดของฟอนต์
                    fontWeight: FontWeight.bold, // น้ำหนักของฟอนต์
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'ทั่วไป',
                  style: TextStyle(
                    fontFamily: 'Kanit', // เพิ่ม fontFamily ที่นี่
                    fontSize: 16, // ขนาดของฟอนต์
                    fontWeight: FontWeight.bold, // น้ำหนักของฟอนต์
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // เนื้อหาของ Flash Sale
                _buildFlashSaleTab(product, promotionsFlashSale,
                    installmentPlansFlashSale, formatter),
                // เนื้อหาของทั่วไป
                _buildGeneralTab(product, promotionsMain, formatter),
              ],
            ),
          ),
        ],
      ),
    );
  }

// สร้าง Widget สำหรับเนื้อหา Flash Sale
  Widget _buildFlashSaleTab(
      Map<String, dynamic> product,
      List promotionsFlashSale,
      List installmentPlansFlashSale,
      NumberFormat formatter) {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['product_name'] ?? '',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Kanit'),
            ),
            SizedBox(height: 8),
            // การแสดงผลส่วนอื่น ๆ เช่น ราคา, ตัวเลือกสินค้า, การรับประกัน ฯลฯ
            Text.rich(
              TextSpan(
                children: [
                  if (promotionsFlashSale != null &&
                      promotionsFlashSale.isNotEmpty) ...[
                    TextSpan(
                      children: () {
                        double rrp = double.tryParse(promotionsFlashSale[0]
                                    ['price_rrp']
                                .replaceAll(',', '')) ??
                            0;
                        double netSellingPrice = double.tryParse(
                                promotionsFlashSale[0]['netselling_price']
                                    .replaceAll(',', '')) ??
                            0;

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
            // Section ตัวเลือกสินค้า
            _buildVariantsSection(product),
            SizedBox(height: 16),
            // Card สำหรับการรับประกัน
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
            SizedBox(height: 16),
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
            _buildOptionSetList(product),
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
          ],
        ),
      ),
    );
  }

// สร้าง Widget สำหรับเนื้อหาทั่วไป
  Widget _buildGeneralTab(Map<String, dynamic> product, List promotionsMain,
      NumberFormat formatter) {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['product_name'] ?? '',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Kanit'),
            ),
            SizedBox(height: 8),
            // การแสดงผลส่วนอื่น ๆ เช่น ราคา, ตัวเลือกสินค้า, การรับประกัน ฯลฯ
            Text.rich(
              TextSpan(
                children: [
                  if (promotionsMain != null && promotionsMain.isNotEmpty) ...[
                    TextSpan(
                      children: () {
                        double rrp = double.tryParse(promotionsMain[0]
                                    ['price_rrp']
                                .replaceAll(',', '')) ??
                            0;
                        double netSellingPrice = double.tryParse(
                                promotionsMain[0]['netselling_price']
                                    .replaceAll(',', '')) ??
                            0;

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
            // Section ตัวเลือกสินค้า
            _buildVariantsSection(product),
            SizedBox(height: 16),
            // Card สำหรับการรับประกัน
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
            SizedBox(height: 16),
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
            _buildOptionSetList(product),
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
          ],
        ),
      ),
    );
  }

  String _calculateDiscountPercentage(
      double originalPrice, double discountedPrice) {
    if (originalPrice == 0) return '0';
    double discount = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return discount.toStringAsFixed(0); // แสดงผลเป็นจำนวนเต็ม
  }

  Widget _buildTabBar(Map<String, dynamic> product,
      {bool isFlashSale = false}) {
    // ถ้าเป็น FlashSale ไม่ต้องแสดง TabBar
    // if (isFlashSale) {
    //   return _buildPromotionList(
    //       product['branch_details']['installment_plans_Flash_Sale']);
    // }
    // กรณีที่ไม่ใช่ Flash Sale แสดง TabBar
    if (isFlashSale) {
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
                fontWeight:
                    FontWeight.normal, // No bold text for minimal effect
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
                    product['branch_details']['installment_plans_Flash_Sale']),
                _buildPromotionList(product['branch_details']
                    ['installment_plans_Flash_Sale_Second']),
              ],
            ),
          ),
        ],
      );
    } else {
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
                fontWeight:
                    FontWeight.normal, // No bold text for minimal effect
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
                                  SizedBox(height: 5,),
                                  // เพิ่มชื่อธนาคารใต้ icon
                                  Text(
                                    bank['image']['fullname'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Kanit',
                                      fontSize: 10
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

            // return Column(
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 8.0),
            //       child: Row(
            //         children: [
            //           Expanded(
            //             flex: 1,
            //             child: Align(
            //               alignment: Alignment.center,
            //               child: Image.network(
            //                 'https://arnold.tg.co.th:3001${bank['image']['image']}',
            //                 height: 30,
            //                 fit: BoxFit.contain,
            //                 alignment: Alignment.centerLeft,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Icon(Icons.broken_image, size: 30);
            //                 },
            //               ),
            //             ),
            //           ),
            //           Expanded(
            //             flex: 1,
            //             child: Center(
            //               child: Text(
            //                 code,
            //                 style: TextStyle(
            //                   color: Colors.black,
            //                   fontFamily: 'Kanit',
            //                 ),
            //                 textAlign: TextAlign.center,
            //               ),
            //             ),
            //           ),
            //           Expanded(
            //             flex: 1,
            //             child: Center(
            //               child: Text(
            //                 bank['plans'][0]['months'] ?? '-',
            //                 style: TextStyle(
            //                   color: Colors.black,
            //                   fontFamily: 'Kanit',
            //                 ),
            //                 textAlign: TextAlign.center,
            //               ),
            //             ),
            //           ),
            //           Expanded(
            //             flex: 1,
            //             child: Center(
            //               child: Text(
            //                 bank['plans'][0]['ppm'] != null
            //                     ? '${formatter.format(double.tryParse(bank['plans'][0]['ppm']) ?? 0)}'
            //                     : '-',
            //                 style: TextStyle(
            //                   color: Colors.black,
            //                   fontFamily: 'Kanit',
            //                 ),
            //                 textAlign: TextAlign.center,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //     for (var i = 1; i < bank['plans'].length; i++)
            //       Padding(
            //         padding: const EdgeInsets.symmetric(vertical: 8.0),
            //         child: Row(
            //           children: [
            //             Expanded(
            //                 flex: 1, child: SizedBox.shrink()), // Placeholder
            //             Expanded(
            //                 flex: 1, child: SizedBox.shrink()), // Placeholder
            //             Expanded(
            //               flex: 1,
            //               child: Center(
            //                 child: Text(
            //                   bank['plans'][i]['months'] ?? '-',
            //                   style: TextStyle(
            //                     color: Colors.black,
            //                     fontFamily: 'Kanit',
            //                   ),
            //                   textAlign: TextAlign.center,
            //                 ),
            //               ),
            //             ),
            //             Expanded(
            //               flex: 1,
            //               child: Center(
            //                 child: Text(
            //                   bank['plans'][i]['ppm'] != null
            //                       ? '${formatter.format(double.tryParse(bank['plans'][i]['ppm']) ?? 0)}'
            //                       : '-',
            //                   style: TextStyle(
            //                     color: Colors.black,
            //                     fontFamily: 'Kanit',
            //                   ),
            //                   textAlign: TextAlign.center,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //   ],
            // );
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

  Future<void> _logActivity({
    required String employeeCode,
    required String branchCode,
    required String model,
    required String activityType,
    required String detailSearch,
    required String tagsBrand,
  }) async {
    Map<String, dynamic> logData = {
      'employee_code': employeeCode,
      'branch_code': branchCode,
      'model': model,
      'activity_type': activityType,
      'detail_search': detailSearch,
      'tags_brand': tagsBrand,
    };

    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    print('logActivity ${json.encode(logData)}');
  }

  @override
  Widget build(BuildContext context) {
    int totalProducts = _productData.length;
    final formatter = NumberFormat('#,##0.00');
    final quantityFormatter = NumberFormat('#,##0');

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: Container(
            child: Column(
              children: [
                HeaderHome(),
                const SizedBox(height: 5),
                SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: searchBranch,
                          focusNode: FocusNode(),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 20.0),
                            hintText: 'ชื่อสินค้า',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontFamily: 'Kanit'),
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            isDense: true,
                            suffixIcon: searchBranch.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        searchBranch.clear();
                                        _filterProducts();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _filterProducts();
                          },
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(fontFamily: 'Kanit'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  margin: EdgeInsets.only(left: 15.0),
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      Tag tag = tags[index];
                      return GestureDetector(
                        onTap: () => _onTagClick(tag),
                        child: Container(
                          padding: const EdgeInsets.only(left: 10, right: 3),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: tag.isSelected
                                ? Colors.grey.shade100
                                : tag.color,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            children: [
                              Text(
                                tag.name,
                                style: TextStyle(
                                    color: tag.isSelected
                                        ? Colors.grey.shade400
                                        : Colors.white,
                                    fontFamily: 'Kanit',
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                padding: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Text(
                                    tag.quantity.toString(),
                                    style: TextStyle(
                                      color: tag.isSelected
                                          ? Colors.grey.shade400
                                          : Colors.black,
                                      fontSize:
                                          tag.quantity.toString().length > 3
                                              ? 8
                                              : 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                isLoading
                    ? _buildShimmerEffect()
                    : Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'จำนวนสินค้าทั้งหมด: $totalProducts รายการ',
                            style: const TextStyle(
                                fontSize: 16, fontFamily: 'Kanit'),
                          ),
                        ),
                      ),
                isLoading
                    ? _buildShimmerEffect()
                    : Expanded(
                        child: _productData.isEmpty
                            ? Center(
                                child: Text('ไม่พบข้อมูลสินค้า',
                                    style: TextStyle(fontFamily: 'Kanit')))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _productData.length,
                                itemBuilder: (context, index) {
                                  var product = _productData[index];
                                  return GestureDetector(
                                    onTap: () => _showProductDetails(
                                        product['product_name']),
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['product_name'] ?? '',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Kanit'),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'ราคา: ${product['price'] != null && product['price'] != '0.00' ? formatter.format(double.parse(product['price'])) + ' บาท' : '-'}',
                                                    style: TextStyle(
                                                        fontFamily: 'Kanit'),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'คงเหลือ: ${quantityFormatter.format(product['all_qty'] ?? 0)} ชิ้น',
                                                    style: TextStyle(
                                                        fontFamily: 'Kanit'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onRefresh() async {
    await _loadInitialData();
    _refreshController.refreshCompleted();
  }
}

class Tag {
  final String name;
  final int quantity;
  final Color color;
  bool isSelected;

  Tag(
      {required this.name,
      required this.quantity,
      required this.color,
      this.isSelected = false});
}
