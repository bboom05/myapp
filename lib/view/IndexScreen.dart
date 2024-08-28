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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    getUsers().then((_) {
      _loadInitialData();
    });

    fetchNearbyBranches();

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

  void _filterProducts() {
    setState(() {
      isLoading = true;
    });

    List<String> selectedTags =
        tags.where((tag) => tag.isSelected).map((tag) => tag.name).toList();
    String searchQuery = searchBranch.text.toLowerCase();

    _productData = _allProductData.where((product) {
      bool matchesQuery = product['product_name']
          .toString()
          .toLowerCase()
          .contains(searchQuery);
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
      var product = json.decode(response.body)[0];

      if (product != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white, // ปรับเป็นสีขาว
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          builder: (context) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
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
                      Text(
                        'ราคา: ${product['price'] != null && product['price'] != '0.00' ? formatter.format(double.parse(product['price'])) + ' บาท' : '-'}',
                        style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
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
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Kanit',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildProductWarrantyAndProtection(product),
                        ],
                      ),

                      SizedBox(
                        height: 16,
                      ),
                      // โปรโมชั่นบัตรเครดิต
                      Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'โปรโมชั่นบัตรเครดิต:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Kanit'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      product['branch_details'] != null &&
                              product['branch_details']['promotions_main'] !=
                                  null &&
                              product['branch_details']['promotions_main']
                                  .isNotEmpty &&
                              product['branch_details']['installment_plans'] !=
                                  null &&
                              product['branch_details']['installment_plans']
                                      ['0'] !=
                                  null &&
                              product['branch_details']['installment_plans']
                                      ['0']['banks'] !=
                                  null
                          ? _buildPromotionList(
                              product['branch_details']['installment_plans'])
                          : Center(
                              child: Text('ไม่มีโปรโมชั่น',
                                  style: TextStyle(
                                      fontFamily: 'Kanit',
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.bold))),

                      const SizedBox(height: 16),

                      // รายการของแถม
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'รายการของแถม:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Kanit'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildOptionSetList(product),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
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
          // padding: const EdgeInsets.all(16.0),
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

          // color: Colors.white, // ปรับให้การ์ดเป็นสีขาว
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(8),
          // ),
          // elevation: 3, // เพิ่มเงาเพื่อให้เหมือน Bootstrap
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductWarrantyAndProtection(Map<String, dynamic> product) {
    var promotionsMain = product['branch_details'] != null &&
            product['branch_details']['promotions_main'] != null &&
            product['branch_details']['promotions_main'].isNotEmpty
        ? product['branch_details']['promotions_main'][0]
        : null;

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
                  promotionsMain != null &&
                          promotionsMain['warranty2years'] != null
                      ? promotionsMain['warranty2years']
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
                  promotionsMain != null &&
                          promotionsMain['brokenscreen'] != null
                      ? promotionsMain['brokenscreen']
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
                            'https://arnold.tg.co.th:3001${bank['image']}',
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
                    ],
                  ),
                ),
                for (var i = 1; i < bank['plans'].length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: SizedBox.shrink()),
                        Expanded(flex: 1, child: SizedBox.shrink()),
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
          padding: const EdgeInsets.all(8.0),
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

  Widget _buildOptionSetList(Map<String, dynamic> product) {
    var promotionsMain = product['branch_details'] != null &&
            product['branch_details']['promotions_main'] != null &&
            product['branch_details']['promotions_main'].isNotEmpty
        ? product['branch_details']['promotions_main'][0]
        : null;

    if (promotionsMain == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        // padding: const EdgeInsets.all(16.0),
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
        // color: Colors.white, // ปรับเป็นสีขาว
        // elevation: 3, // เพิ่มเงา
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
      // padding: const EdgeInsets.all(16.0),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionSetItem(
              'ของแถม 1',
              promotionsMain['optionset1']?.toString()?.isEmpty ?? true
                  ? '-'
                  : promotionsMain['optionset1'].toString(),
            ),
            _buildOptionSetItem(
              'ของแถม 2',
              promotionsMain['optionset2']?.toString()?.isEmpty ?? true
                  ? '-'
                  : promotionsMain['optionset2'].toString(),
            ),
            _buildOptionSetItem(
              'ของแถม 3',
              promotionsMain['optionset3']?.toString()?.isEmpty ?? true
                  ? '-'
                  : promotionsMain['optionset3'].toString(),
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
                            LengthLimitingTextInputFormatter(20),
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
                                child: Text('ไม่พบข้อมูลค้า',
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
