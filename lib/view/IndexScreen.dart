import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/HeaderHome.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../system/info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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

  // Search
  final formKeyBranch = GlobalKey<FormState>();
  final searchBranch = TextEditingController();

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
    Color(0xFFFF6F61), // Bright Red
    Color(0xFFFFB347), // Bright Orange
    Color(0xFFFFD700), // Bright Yellow
    Color(0xFF00BFFF), // Bright Blue
    Color(0xFF9370DB), // Bright Purple
    Color(0xFFFF69B4), // Bright Pink
    Color(0xFFFFA07A), // Bright Peach
    Color(0xFF20B2AA), // Bright Teal
    Color(0xFF8A2BE2), // Bright Lavender
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    getUsers().then((_) {
      _search();
    });

    fetchNearbyBranches();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    var usernameKey = Info().userAPI;
    var passwordKey = Info().passAPI;
    final encodedCredentials =
        base64Encode(utf8.encode('$usernameKey:$passwordKey'));

    final response = await http.post(Uri.parse(Info().searchProduct),
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/json',
        },
        body: json.encode(data));

    if (response.statusCode == 200) {
      var rs = json.decode(response.body);
      setState(() {
        _allProductData = List<Map<String, dynamic>>.from(rs['data']);
        _productData = _allProductData;
        _generateTags();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateTags() {
    Map<String, int> brandCount = {};
    for (var product in _allProductData) {
      String brand = product['brand'];
      if (brandCount.containsKey(brand)) {
        brandCount[brand] = brandCount[brand]! + 1;
      } else {
        brandCount[brand] = 1;
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

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'] ?? '',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ราคา: ${product['price']} บาท',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('คงเหลือ: ${product['all_qty']} ชิ้น'),
                  SizedBox(height: 16),
                  Text(
                    'Variants:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (product['variants'] as List)
                        .map((variant) => Card(
                              child: ListTile(
                                title: Text(variant['variant']),
                                subtitle: Text(
                                    'คงเหลือ: ${variant['remaining_qty']} ชิ้น'),
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'ผ่อนบัตรเครดิต',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  product['promotion'] != null
                      ? _buildPromotionTable(product['promotion'])
                      : Text('ไม่มีข้อมูล'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildPromotionTable(Map<String, dynamic> promotions) {
  List<Widget> tables = [];

  for (var plan in promotions['installment_plans']) {
    List<TableRow> rows = [];

    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'ธนาคาร',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'ระยะเวลา (เดือน)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'ค่างวดต่อเดือน',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );

    for (var bank in plan['banks']) {
      bool isFirstRow = true;
      for (var detail in bank['plans']) {
        rows.add(
          TableRow(
            decoration: isFirstRow
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: isFirstRow
                    ? Center(
                      child: Text(
                          bank['name'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                    )
                    : SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${detail['months']} เดือน',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${NumberFormat("#,##0").format(detail['monthly_payment'])} บาท',
                  style: TextStyle(color: Colors.black),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
        isFirstRow = false;
      }
    }

    tables.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'อัตราดอกเบี้ย ${plan['percentage']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            ),
          ),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300, width: 0.5,
              ),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
            },
            children: rows,
          ),
        ],
      ),
    );
  }
  return Column(
    children: tables,
  );
}


  @override
  Widget build(BuildContext context) {
    int totalProducts = _productData.length;
    final formatter = NumberFormat('#,##0.00');
    final quantityFormatter = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: Column(
          children: [
            HeaderHome(),
            SizedBox(height: 16),
            // Container(
            //   padding: EdgeInsets.all(5),
            //   margin: EdgeInsets.symmetric(horizontal: 15.0),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(50),
            //     color: Colors.grey.shade100,
            //   ),
            //   child: TabBar(
            //     splashFactory: NoSplash.splashFactory,
            //     indicatorColor: Colors.transparent,
            //     indicatorPadding: EdgeInsets.zero,
            //     indicatorWeight: double.minPositive,
            //     dividerColor: Colors.transparent,
            //     controller: _tabController,
            //     tabs: [
            //       Container(
            //         width: MediaQuery.of(context).size.width / 2 - 10,
            //         child: Tab(text: 'สาขา'),
            //       ),
            //       Container(
            //         width: MediaQuery.of(context).size.width / 2 - 10,
            //         child: Tab(text: 'สาขาใกล้เคียง'),
            //       ),
            //     ],
            //     unselectedLabelColor: Colors.black.withOpacity(0.5),
            //     labelColor: _selectedColor,
            //     indicator: BoxDecoration(
            //       borderRadius: BorderRadius.circular(50),
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 20.0),
                                  hintText: 'ชื่อสินค้า',
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade400),
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
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกคำค้นหา';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color(0xFFFF8C00)),
                              onPressed: _search,
                              child: Icon(Icons.search_outlined),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        margin: EdgeInsets.only(left: 15.0),
                        height: 30,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            Tag tag = tags[index];
                            return GestureDetector(
                              onTap: () => _onTagClick(tag),
                              child: Container(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 3),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  color: tag.isSelected
                                      ? tag.color.withOpacity(0.5)
                                      : tag.color,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      tag.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        tag.quantity.toString(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
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
                              padding: const EdgeInsets.only(
                                  left: 16.0, bottom: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'จำนวนสินค้าทั้งหมด: $totalProducts',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                      isLoading
                          ? _buildShimmerEffect()
                          : Expanded(
                              child: _productData.isEmpty
                                  ? Center(child: Text('ไม่พบข้อมูลค้า'))
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: _productData.length,
                                      itemBuilder: (context, index) {
                                        var product = _productData[index];
                                        return GestureDetector(
                                          onTap: () =>
                                              _showProductDetails(product),
                                          child: Card(
                                            color: Colors.grey.shade100,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product['product_name'] ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                      'ราคา: ${product['price'] != '0.00' ? formatter.format(double.parse(product['price'])) + ' บาท' : '-'}'),
                                                  SizedBox(height: 8),
                                                  Text(
                                                      'คงเหลือ: ${quantityFormatter.format(product['all_qty'])} ชิ้น'),
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
                  Column(
                    children: [
                      isBranchLoading
                          ? Center(child: CircularProgressIndicator())
                          : Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _nearbyBranches.length,
                                itemBuilder: (context, index) {
                                  var branch = _nearbyBranches[index];
                                  return Card(
                                    color: Colors.grey.shade100,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: _selectedColor,
                                          ),
                                          SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                branch['branch_name'] ?? '',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'รหัสสาขา: ${branch['branch_code']}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              color: Colors.grey.shade100,
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
    _search();
    await fetchNearbyBranches();
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
