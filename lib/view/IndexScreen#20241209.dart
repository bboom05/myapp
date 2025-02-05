import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'dart:convert';
import 'package:myapp/model/user.dart';
import 'package:myapp/view/HeaderHome.dart';
import 'package:myapp/view/ProductIncoming.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../system/info.dart';
import 'QRScannerPage.dart';
import 'showProductDetail.dart';

final List<Map<String, dynamic>> menuItems = [
  {
    "label": "In Transit",
    "image": "assets/icons/transporting.png",
    "color": Colors.deepOrange,
    "screen": ProductIncoming()
  }
];

// Placeholder Screens for each menu item

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TabController? _premiumTabController;
  final _selectedColor = const Color(0xffFF8C00);
  final _unselectedColor = const Color(0xff5f6368);
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  final formKeyBranch = GlobalKey<FormState>();
  final searchBranch = TextEditingController();
  final PageController _pageController = PageController();
  final ValueNotifier<List<Tag>> tagsNotifier = ValueNotifier([]);
  final CarouselController _carouselController = CarouselController();
  int _currentPage = 0; // Track the current page index
  Timer? _timer;
  final ValueNotifier<int> totalProductsNotifier = ValueNotifier(0);

  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";
  var select_branch_code = "";
  var select_branch_name = "";
  var query = "";

  List<Tag> tags = [];
  List<Map<String, dynamic>> _productData = [];
  List<Map<String, dynamic>> _allProductData = [];
  List<Map<String, dynamic>> _nearbyBranches = [];
  List<Map<String, dynamic>> _premiumData = [];
  List<Map<String, String>> branch_codes_area = [];

  bool isLoading = false;
  bool isBranchLoading = false;

  final List<Color> pastelColors = [
    // Color(0xFFFF6F61),
    // Color(0xFFFFB347),
    // Color(0xFFFFD700),
    // Color(0xFF00BFFF),
    // Color(0xFF9370DB),
    // Color(0xFFFF69B4),
    // Color(0xFFFFA07A),
    // Color(0xFF20B2AA),
    // Color(0xFF8A2BE2),
    // Color(0xFF006BFF),
    // Color(0xFFEEEEEE),
    const Color(0xFFFFFFFF),
  ];

  Set<String> _loggedProducts = Set<String>();

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    getUsers().then((_) {
      _loadInitialData();
    });

    // fetchPremiumData();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= 3) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
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

  Future<void> getUsers() async {
    await user.init();
    setState(() {
      isLogin = user.isLogin;
      fullname = user.fullname;
      brance_code = user.brance_code;
      brance_name = user.brance_name;
      select_branch_code = user.select_branch_code;
      select_branch_name = user.select_branch_name;
      branch_codes_area = user.branch_codes_area
          .map((e) => {
                "branch_code": e['branch_code']?.toString() ?? "",
                "branch_name": e['branch_name']?.toString() ?? "Unknown"
              })
          .toList();

      print('branch_codes_area: $branch_codes_area');

      print('branch_codes_area abc: {$branch_codes_area}');
    });
  }

  Future<void> _loadInitialData() async {
    _search();
  }

// ค้นหา iphone apple 15 pro max 12 จะไม่เจออะไรเลย

  // void _filterProducts() {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   print('tags: $tags');

  //   List<String> selectedTags =
  //       tags.where((tag) => tag.isSelected).map((tag) => tag.name).toList();
  //   String searchQuery = searchBranch.text.toLowerCase().trim();

  //   // แยกคำค้นหาที่มากกว่าหนึ่งคำ
  //   List<String> searchTerms = searchQuery.split(' ');

  //   _productData = _allProductData.where((product) {
  //     // ตรวจสอบการจับคู่คำค้นหาทุกคำ
  //     bool matchesQuery = searchTerms.every((term) {
  //       var productName = product['product_name'].toString().toLowerCase();

  //       // เปรียบเทียบด้วย contains() และ startsWith() เพื่อความยืดหยุ่น
  //       return productName.contains(term) || productName.startsWith(term);
  //     });

  //     // ตรวจสอบการจับคู่ Tags
  //     bool matchesTags = selectedTags.isEmpty ||
  //         (selectedTags.contains('No Brand') &&
  //             (product['brand'] == null || product['brand'] == 'Unknown')) ||
  //         selectedTags.contains(product['brand'].toString());

  //     return matchesQuery && matchesTags;
  //   }).toList();

  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  void _filterProducts() {
    setState(() {
      isLoading = true;
    });

    List<String> selectedTags =
        tags.where((tag) => tag.isSelected).map((tag) => tag.name).toList();
    String searchQuery = searchBranch.text.toLowerCase().trim();
    List<String> searchTerms = searchQuery.split(' ');

    _productData = _allProductData.where((product) {
      bool matchesQuery = searchTerms.every((term) {
        var productName = product['product_name'].toString().toLowerCase();
        return productName.contains(term) || productName.startsWith(term);
      });

      bool matchesTags = selectedTags.isEmpty ||
          (selectedTags.contains('No Brand') &&
              (product['brand'] == null || product['brand'] == 'Unknown')) ||
          selectedTags.contains(product['brand'].toString());

      return matchesQuery && matchesTags;
    }).toList();

    // อัปเดตจำนวนสินค้าหลังจากกรองข้อมูล
    totalProductsNotifier.value = _productData.length;

    // Update the total product count based on filtered data
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
      'warehouse': select_branch_code,
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
          totalProductsNotifier.value = _productData.length;
          _generateTags();
          isLoading = false; // เมื่อมีข้อมูลให้หยุดการโหลด
        });
      } else if (rs is Map && rs.containsKey('data')) {
        setState(() {
          _allProductData = List<Map<String, dynamic>>.from(rs['data']);
          _productData = _allProductData;
          totalProductsNotifier.value = _productData.length;
          _generateTags();
          isLoading = false; // เมื่อมีข้อมูลให้หยุดการโหลด
        });
      } else {
        setState(() {
          _allProductData = [];
          _productData = []; // กรณีไม่มีข้อมูลใน rs
          totalProductsNotifier.value = 0;
          _generateTags();
          isLoading = false; // หยุดการโหลดเมื่อไม่มีข้อมูล
        });
      }
    } else {
      setState(() {
        totalProductsNotifier.value = 0;
        _productData = []; // กรณีมีปัญหาใน response
        isLoading = false; // หยุดการโหลดในกรณีที่มีข้อผิดพลาด
      });
    }
  }

  // final ValueNotifier<List<Tag>> tagsNotifier = ValueNotifier([]);

  void _generateTags() {
    Map<String, int> brandCount = {};
    int noBrandCount = 0; // ตัวแปรสำหรับนับสินค้าที่ไม่มีแบรนด์

    for (var product in _allProductData) {
      String? brand = product['brand']; // ตรวจสอบ brand

      if (brand == null || brand == 'Unknown') {
        noBrandCount++; // เพิ่มจำนวนสินค้าที่ไม่มีแบรนด์
      } else {
        brandCount[brand] = (brandCount[brand] ?? 0) + 1;
      }
    }

    List<Tag> newTags = [];
    int index = 0;
    brandCount.forEach((brand, count) {
      newTags.add(Tag(
        name: brand,
        quantity: count,
        color: pastelColors[index % pastelColors.length],
      ));
      index++;
    });

    if (noBrandCount > 0) {
      newTags.add(Tag(
        name: 'No Brand',
        quantity: noBrandCount,
        color: const Color(0xFFEEEEEE), // สีสำหรับ No Brand
      ));
    }
    setState(() {
      tags = newTags; // ตรวจสอบการกำหนดค่า tags ใหม่
    });
    tagsNotifier.value = newTags; // อัปเดตค่าใน ValueNotifier
  }

  void _onTagClick(Tag tag) {
    setState(() {
      tag.isSelected = !tag.isSelected;
    });
    tagsNotifier.value = List.from(tagsNotifier.value); // อัปเดต ValueNotifier
    _filterProducts();
  }

  // void _generateTags() {
  //   Map<String, int> brandCount = {};
  //   int noBrandCount = 0; // ตัวแปรสำหรับนับสินค้าที่ไม่มีแบรนด์

  //   for (var product in _allProductData) {
  //     String? brand = product['brand']; // ตรวจสอบ brand

  //     if (brand == null || brand == 'Unknown') {
  //       noBrandCount++; // เพิ่มจำนวนสินค้าที่ไม่มีแบรนด์
  //     } else {
  //       if (brandCount.containsKey(brand)) {
  //         brandCount[brand] = brandCount[brand]! + 1;
  //       } else {
  //         brandCount[brand] = 1;
  //       }
  //     }
  //   }

  //   setState(() {
  //     tags = [];
  //     int index = 0;

  //     // สร้างแท็กสำหรับแบรนด์ที่มีสินค้า
  //     brandCount.forEach((brand, count) {
  //       tags.add(Tag(
  //         name: brand,
  //         quantity: count,
  //         color: pastelColors[index % pastelColors.length],
  //       ));
  //       index++;
  //     });

  //     // เพิ่มแท็ก No Brand ไว้ท้ายสุด
  //     if (noBrandCount > 0) {
  //       tags.add(Tag(
  //         name: 'No Brand',
  //         quantity: noBrandCount,
  //         color: Color(0xFFEEEEEE), // สีสำหรับ No Brand
  //       ));
  //     }
  //     print('tags: $tags');
  //   });
  // }

  // void _onTagClick(Tag tag) {
  //   setState(() {
  //     tag.isSelected = !tag.isSelected;
  //   });
  //   _filterProducts();
  // }

  Future<Map<String, dynamic>?> _fetchProductType(String productName) async {
    try {
      var usernameKey = Info().userAPIProd;
      var passwordKey = Info().passAPIProd;
      final encodedCredentials =
          base64Encode(utf8.encode('$usernameKey:$passwordKey'));
      final uri = Uri.parse(Info().checkPromotion).replace(queryParameters: {
        'product_name': productName,
        'warehouse': select_branch_code,
      });
      print('branch_code: $select_branch_code');
      final response = await http.get(uri, headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        var dataJson = json.decode(response.body);
        var product = dataJson['products'][0]; // สมมติว่าคืนค่าผลิตภัณฑ์ตัวแรก
        var branchDetails =
            product['branch_details']; // ดึงข้อมูล branch_details จาก product
        return branchDetails; // คืนค่า branch_details กลับ
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (error) {
      print('Error fetching product details: $error');
      return null; // คืนค่า null ในกรณีเกิดข้อผิดพลาด
    }
  }

  void _showProductDetails(Map<String, dynamic> product) async {
    var data = await _fetchProductType(product['product_name']);
    var branchDetails = data;

    // สร้างรายการ promotion ที่จะใช้สร้างปุ่ม
    List<Map<String, dynamic>> availablePromotions = [];

    if (branchDetails != null &&
        branchDetails['promotions_flash_sale'] != null &&
        branchDetails['promotions_flash_sale'].isNotEmpty) {
      availablePromotions.add({
        'type': 'flash_sale',
        'text': 'Flash Sale',
        'icon': Icons.flash_on,
        'color': Colors.red,
      });
    }

    if (branchDetails != null &&
        branchDetails['promotions_flash_sale_second'] != null &&
        branchDetails['promotions_flash_sale_second'].isNotEmpty) {
      availablePromotions.add({
        'type': 'flash_sale_secondary',
        'text': 'Flash Sale รอง',
        'icon': Icons.flash_auto,
        'color': Colors.orange,
      });
    }

    if (branchDetails != null &&
        branchDetails['promotions_main'] != null &&
        branchDetails['promotions_main'].isNotEmpty) {
      availablePromotions.add({
        'type': 'general',
        'text': 'ทั่วไป',
        'icon': Icons.store,
        'color': Colors.green,
      });
    }

    if (branchDetails != null &&
        branchDetails['promotions_second'] != null &&
        branchDetails['promotions_second'].isNotEmpty) {
      availablePromotions.add({
        'type': 'general_secondary',
        'text': 'ทั่วไป รอง',
        'icon': Icons.storefront,
        'color': Colors.blue,
      });
    }

    // ถ้าไม่มีโปรโมชั่นใดๆ ให้พาไปยัง ShowProductDetail ในโหมดทั่วไป
    if (availablePromotions.isEmpty) {
      _navigateToShowProductDetail(product, 'general');

      return;
    }

    // ถ้ามีโปรโมชั่นเพียงปุ่มเดียว ให้พาไปยังหน้านั้นเลย
    if (availablePromotions.length == 1) {
      _navigateToShowProductDetail(product, availablePromotions[0]['type']);

      return;
    }

    // ถ้ามีมากกว่าหนึ่งโปรโมชั่น ให้แสดง showModalBottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.4,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    // สร้างปุ่มจาก availablePromotions
                    ...availablePromotions.map((promotion) {
                      return Column(
                        children: [
                          _buildStyledButton(
                            text: promotion['text'],
                            icon: promotion['icon'],
                            iconColor: promotion['color'],
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToShowProductDetail(
                                  product, promotion['type']);
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// ต้องการให้ส่ง premiumData ไปด้วย
  void _navigateToShowProductDetail(
      Map<String, dynamic> product, String selectedType) async {
    await _logActivity(
      employeeCode: user.employee_code,
      branchCode: user.brance_code,
      model: product['product_name'],
      activityType: 'click_product',
      detailSearch: searchBranch.text,
      tagsBrand:
          tags.where((tag) => tag.isSelected).map((tag) => tag.name).join(','),
      promotionType: selectedType,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowProductDetail(
          product: product, // เปลี่ยนจาก product_name เป็น product
          selectedType: selectedType,
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required Color iconColor, // เพิ่ม parameter เพื่อรับสีไอคอน
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9, // กำหนดความกว้างเป็น 90%
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.white, // พื้นหลังสีขาว
          elevation: 0, // ไม่มีเงา
          side: BorderSide(color: Colors.grey.shade400), // ขอบปุ่มเป็นสีเทาอ่อน
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // จัดไอคอนและข้อความให้อยู่ตรงกลาง
          children: [
            Icon(
              icon,
              color: iconColor, // ใช้สีไอคอนที่ส่งมา
            ),
            const SizedBox(width: 10), // เว้นระยะระหว่างไอคอนกับข้อความ
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Kanit',
                color: Colors.black, // สีข้อความเป็นสีดำเพื่อความคมชัด
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logActivity(
      {required String employeeCode,
      required String branchCode,
      required String model,
      required String activityType,
      required String detailSearch,
      required String tagsBrand,
      required String promotionType}) async {
    Map<String, dynamic> logData = {
      'employee_code': employeeCode,
      'branch_code': branchCode,
      'model': model,
      'activity_type': activityType,
      'detail_search': detailSearch,
      'tags_brand': tagsBrand,
      'promotion_type': promotionType
    };

    try {
      final uri = Uri.parse(
          Info().logActivity); // เปลี่ยน URL เป็น URL ที่ต้องการใช้จริง
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(logData),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Log activity successful');
      } else {
        throw Exception('Failed to log activity');
      }
    } catch (error) {
      print('Error logging activity: $error');
    }
  }

  void _selectBranch(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredBranches =
        List.from(user.branch_codes_area);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void _filterBranches() {
              String searchText = searchController.text.toLowerCase();
              setModalState(() {
                filteredBranches = user.branch_codes_area.where((branch) {
                  String branchName = branch["branch_name"]!.toLowerCase();
                  String branchCode = branch["branch_code"]!.toLowerCase();
                  return branchName.contains(searchText) ||
                      branchCode.contains(searchText);
                }).toList();
              });
            }

            return GestureDetector(
              onTap: () {
                // เมื่อกดพื้นที่ว่าง จะพับ Keyboard ลง
                FocusScope.of(context).unfocus();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ช่องค้นหา
                    Container(
                      margin:
                          const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: searchController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                              ],
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 20.0),
                                hintText: 'ค้นหาสาขา',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontFamily: 'Kanit',
                                ),
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
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey.shade400),
                                        onPressed: () {
                                          setModalState(() {
                                            searchController.clear();
                                            _filterBranches(); // กรองข้อมูลใหม่
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                _filterBranches(); // กรองข้อมูลเมื่อพิมพ์
                              },
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(fontFamily: 'Kanit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // แสดงจำนวนสาขาทั้งหมดที่กรองได้
                    Align(
                      alignment: Alignment.topRight, // ชิดซ้าย
                      child: Text(
                        'จำนวน ${filteredBranches.length} สาขา',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.left, // ชิดซ้าย
                      ),
                    ),

                    const SizedBox(height: 10),

                    // รายการสาขา
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBranches.length,
                        itemBuilder: (context, index) {
                          var branch = filteredBranches[index];
                          String branchCode = branch["branch_code"]!;
                          String branchName = branch["branch_name"]!;
                          bool isSelected = select_branch_code == branchCode;

                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                user.select_branch_code = branchCode;
                                user.select_branch_name = branchName;
                                select_branch_code = branchCode;
                                select_branch_name = branchName;

                                // รีเซ็ตสถานะการเลือกของแท็กทั้งหมด
                                searchBranch.clear();
                                for (var tag in tags) {
                                  tag.isSelected = false;
                                }
                              });

                              // ดึงข้อมูลสินค้ามาใหม่หลังจากเลือกสาขา
                              await _loadInitialData();
                              Navigator.pop(context); // ปิด BottomSheet
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0, // ไม่มีเงาเพื่อความเรียบง่าย
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Colors.grey.shade300, // ใช้สีเทาอ่อน
                                  width: 1, // เส้นขอบบาง
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white, // พื้นหลังสีขาว
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                leading: Icon(
                                  Icons.storefront,
                                  color: isSelected
                                      ? Colors.orangeAccent
                                      : Colors.grey[400],
                                  size: 24, // ไอคอนเล็กลงเพื่อความเรียบง่าย
                                ),
                                title: Text(
                                  branchName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey[800],
                                    fontFamily: 'Prompt',
                                  ),
                                ),
                                subtitle: Text(
                                  branchCode,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontFamily: 'Prompt',
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.orangeAccent)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalProducts = _productData.length;
    final formatter = NumberFormat('#,##0.00');
    final quantityFormatter = NumberFormat('#,##0');

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true, // ติดอยู่ด้านบน
                floating: false, // ไม่ลอย
                expandedHeight: 150.0,
                centerTitle: false, // ระบุให้ title อยู่ซ้ายมือเสมอ
                backgroundColor: Colors.orange,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double scrollPercentage =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (150.0 - kToolbarHeight))
                            .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      title: scrollPercentage < 0.9
                          ? _buildHeader(scrollPercentage)
                          : null,
                      background: _buildBackground(scrollPercentage),
                    );
                  },
                ),
              ),

              // Product Incoming Section
              SliverToBoxAdapter(
                child: CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(
                    height: 110,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentPage = index; // Update the current page index
                      });
                    },
                  ),
                  items: List.generate(
                    (menuItems.length / 4).ceil(),
                    (pageIndex) {
                      int start = pageIndex * 4;
                      int end = start + 4;
                      end = end > menuItems.length ? menuItems.length : end;
                      return buildMenuPage(
                          context, menuItems.sublist(start, end));
                    },
                  ),
                ),
                // Dot indicator
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: List.generate(
                //     (menuItems.length / 4).ceil(),
                //     (index) => Container(
                //       width: 8.0,
                //       height: 8.0,
                //       margin:
                //           EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: _currentPage == index
                //             ? Color(0xffFF8C00) // Active dot color
                //             : Colors.grey, // Inactive dot color
                //       ),
                //     ),
                //   ),
                // ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    color: Colors.white, // พื้นหลังสีขาว
                    padding:
                        // const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        const EdgeInsets.only(left: 16, top: 5, right: 16),
                    child: Row(
                      children: [
                        // Expanded(
                        //   child: TextFormField(
                        //     controller: searchBranch,
                        //     focusNode: FocusNode(),
                        //     inputFormatters: [
                        //       LengthLimitingTextInputFormatter(50),
                        //     ],
                        //     decoration: InputDecoration(
                        //       prefixIcon: const Icon(Icons.search),
                        //       contentPadding: const EdgeInsets.symmetric(
                        //           vertical: 8.0, horizontal: 20.0),
                        //       hintText: 'ชื่อสินค้า',
                        //       hintStyle: TextStyle(
                        //           color: Colors.grey.shade400,
                        //           fontFamily: 'Kanit'),
                        //       fillColor: Colors.white,
                        //       filled:
                        //           true, // เพื่อให้พื้นหลังของ search box เป็นสีขาว
                        //       focusedBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(25.0),
                        //         borderSide: BorderSide(
                        //           color: Colors.grey.shade300,
                        //         ),
                        //       ),
                        //       enabledBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(25.0),
                        //         borderSide: BorderSide(
                        //           color: Colors.grey.shade300,
                        //         ),
                        //       ),
                        //       border: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(25.0),
                        //       ),
                        //       isDense: true,
                        //       suffixIcon: searchBranch.text.isNotEmpty
                        //           ? IconButton(
                        //               icon: const Icon(Icons.clear),
                        //               onPressed: () {
                        //                 setState(() {
                        //                   searchBranch.clear();
                        //                   _filterProducts();
                        //                 });
                        //               },
                        //             )
                        //           : null,
                        //     ),
                        //     onChanged: (value) {
                        //       _filterProducts();
                        //     },
                        //     keyboardType: TextInputType.text,
                        //     textInputAction: TextInputAction.search,
                        //     style: const TextStyle(fontFamily: 'Kanit'),
                        //   ),
                        // ),

                        Expanded(
                          child: TextFormField(
                            controller: searchBranch,
                            focusNode: FocusNode(),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 20.0),
                              hintText: 'ชื่อสินค้า',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontFamily: 'Kanit'),
                              fillColor: Colors.white,
                              filled:
                                  true, // เพื่อให้พื้นหลังของ search box เป็นสีขาว
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
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ปุ่ม Clear
                                  if (searchBranch.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          searchBranch.clear();
                                          _filterProducts();
                                        });
                                      },
                                    ),
                                  // ปุ่ม Scan
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () async {
                                      // เปิดหน้า QRScannerPage
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QRScannerPage(),
                                        ),
                                      );

                                      // ตรวจสอบผลลัพธ์จากการสแกน QR Code
                                      if (result != null && result is String) {
                                        setState(() {
                                          searchBranch.text = result;
                                          _filterProducts();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            onChanged: (value) {
                              _filterProducts();
                            },
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(fontFamily: 'Kanit'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Tag List Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  height: 50,
                  child: Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(
                        left: 15.0, top: 0.0, bottom: 0.0),
                    padding: const EdgeInsets.only(top: 5, bottom: 10),
                    height: 40,
                    child: ValueListenableBuilder<List<Tag>>(
                      valueListenable: tagsNotifier,
                      builder: (context, tags, _) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            Tag tag = tags[index];
                            return GestureDetector(
                              onTap: () => _onTagClick(tag),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                padding:
                                    const EdgeInsets.only(left: 10, right: 3),
                                height: tag.isSelected ? 40 : 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: tag.isSelected
                                        ? const Color(0xFF0077c2)
                                        : Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 35),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            transitionBuilder:
                                                (child, animation) {
                                              return ScaleTransition(
                                                  scale: animation,
                                                  child: child);
                                            },
                                            child: tag.isSelected
                                                ? Icon(
                                                    Icons.check,
                                                    key: ValueKey(
                                                        'check_${tag.name}'),
                                                    size: 14,
                                                    color:
                                                        const Color(0xFF0077c2),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          SizedBox(
                                              width: tag.isSelected ? 3 : 0),
                                          Text(
                                            tag.name,
                                            style: TextStyle(
                                              color: tag.isSelected
                                                  ? const Color(0xFF0077c2)
                                                  : Colors.black45,
                                              fontFamily: 'Kanit',
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 25,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tag.isSelected
                                              ? const Color(0xFF0077c2)
                                                  .withOpacity(0.7)
                                              : Colors.grey.shade300,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            tag.quantity.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: tag.quantity
                                                          .toString()
                                                          .length >
                                                      3
                                                  ? 6
                                                  : 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 5.0),
                    child: isLoading
                        ? Row(
                            children: [
                              _buildShimmerEffect(),
                              const Text(
                                'กำลังโหลดข้อมูลสินค้า...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Kanit',
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          )
                        : ValueListenableBuilder<int>(
                            valueListenable: totalProductsNotifier,
                            builder: (context, totalProducts, _) {
                              return Text(
                                'พบสินค้า $totalProducts รายการ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Kanit',
                                  color: Colors.black54,
                                ),
                              );
                            },
                          ),
                  ),
                  height: 40,
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (isLoading) {
                      // แสดง shimmer effect ขณะโหลดข้อมูล
                      return _buildShimmerEffect();
                    } else if (_productData.isEmpty) {
                      // แสดงข้อความ "ไม่พบข้อมูลสินค้า" เมื่อไม่มีข้อมูล
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .sentiment_dissatisfied, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
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
                      );
                    } else {
                      // แสดงรายการสินค้าเมื่อมีข้อมูล
                      var product = _productData[index];
                      return GestureDetector(
                        onTap: () => _showProductDetails(product),
                        child: Card(
                          color: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['product_name'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 16, fontFamily: 'Kanit'),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ราคา ${product['price'] != null && product['price'] != '0.00' ? formatter.format(double.parse(product['price'])) + ' บาท' : '-'}',
                                        style: const TextStyle(
                                            fontFamily: 'Kanit'),
                                      ),
                                    ),
                                    Text(
                                      'คงเหลือ ${quantityFormatter.format(product['all_qty'] ?? 0)} ชิ้น',
                                      style:
                                          const TextStyle(fontFamily: 'Kanit'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  childCount: isLoading || _productData.isNotEmpty
                      ? _productData.length
                      : 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Widget สำหรับส่วนที่แสดงเมื่อ scroll เล็กน้อย
  Widget _buildHeader(double scrollPercentage) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildUserInfo(),
          GestureDetector(
            onTap: () => _selectBranch(context),
            child: _buildBranchSelector(),
          ),
        ],
      ),
    );
  }

// Widget สำหรับแสดงข้อมูลผู้ใช้
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person,
              size: 26,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              '$fullname',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Kanit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$select_branch_name',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontFamily: 'Kanit',
          ),
        ),
      ],
    );
  }

// Widget สำหรับแสดงปุ่มเลือกสาขา
  Widget _buildBranchSelector() {
    return Row(
      children: const [
        Icon(
          Icons.store,
          size: 24,
          color: Colors.white,
        ),
        Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
          size: 24,
        ),
      ],
    );
  }

// Widget สำหรับพื้นหลังของ AppBar
  Widget _buildBackground(double scrollPercentage) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          if (scrollPercentage > 0.9) _buildFullInfo(),
        ],
      ),
    );
  }

// Widget สำหรับแสดงข้อมูลเต็มเมื่อเลื่อนสุด
  Widget _buildFullInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person,
              size: 26,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              '$fullname',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Kanit',
              ),
            ),
          ],
        ),
        if (branch_codes_area.isNotEmpty && branch_codes_area.length > 1)
          GestureDetector(
            onTap: () => _selectBranch(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$select_branch_name ($select_branch_code)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  '$select_branch_name ($select_branch_code)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Kanit',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget buildMenuPage(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items.map((item) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['screen']),
            );
          },
          child: Container(
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(8),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.grey.withOpacity(0.2),
            //       spreadRadius: 1,
            //       blurRadius: 4,
            //       offset: Offset(0, 2),
            //     ),
            //   ],
            // ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(
                      12), // Reduced padding for more space
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEEEEEE)
                        .withOpacity(0.2), // Light gray background color
                  ),
                  child: Image.asset(
                    item['image'],
                    width: 28, // Reduced icon size for better fit
                    height: 28,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  // Wrap Text with Expanded to avoid overflow
                  child: Text(
                    item['label'],
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow up to 2 lines of text
                    overflow: TextOverflow
                        .ellipsis, // Show ellipsis if text is too long
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget _buildShimmerEffect() {
  //   return Expanded(
  //     child: ListView.builder(
  //       padding: EdgeInsets.zero,
  //       itemCount: 5,
  //       itemBuilder: (context, index) {
  //         return Shimmer.fromColors(
  //           baseColor: Colors.grey.shade300,
  //           highlightColor: Colors.grey.shade100,
  //           child: Card(
  //             color: Colors.white,
  //             margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //             child: Padding(
  //               padding: EdgeInsets.all(16),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Container(
  //                     width: double.infinity,
  //                     height: 16,
  //                     color: Colors.white,
  //                   ),
  //                   SizedBox(height: 8),
  //                   Container(
  //                     width: double.infinity,
  //                     height: 16,
  //                     color: Colors.white,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildShimmerEffect() {
    return Container(
      height: 100.0, // กำหนดความสูงเองให้เหมาะสมแทนการใช้ Expanded
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
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

  Future<void> _onRefresh() async {
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height; // เพิ่มตัวแปรสำหรับตั้งค่าความสูงที่เหมาะสม

  _StickyHeaderDelegate({required this.child, this.height = 55.0});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height, // กำหนดความสูงที่แน่นอน
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false; // กำหนดให้ไม่ต้อง rebuild เมื่อไม่มีการเปลี่ยนแปลง
  }
}
