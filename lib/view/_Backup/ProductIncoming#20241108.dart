import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:myapp/system/info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/model/user.dart';

class ProductIncoming extends StatefulWidget {
  @override
  _ProductIncomingState createState() => _ProductIncomingState();
}

class _ProductIncomingState extends State<ProductIncoming> {
  List<Map<String, dynamic>> _productIncomingData = [];
  List<Map<String, dynamic>> _filteredProductIncomingData = [];
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();

  var user = User();
  bool isLogin = false;
  var fullname = "";
  var brance_code = "";
  var brance_name = "";
  var select_branch_code = "";
  var select_branch_name = "";
  List<Map<String, dynamic>> branch_codes_area = [];

  @override
  void initState() {
    super.initState();
    getUsers().then((_) => fetchProductIncomingData());
    _searchController.addListener(_filterProducts);
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
    });
  }

  Future<void> fetchProductIncomingData() async {
    try {
      var usernameKey = Info().userAPIProd;
      var passwordKey = Info().passAPIProd;
      final encodedCredentials =
          base64Encode(utf8.encode('$usernameKey:$passwordKey'));
      final uri = Uri.parse(Info().productIncoming).replace(queryParameters: {
        'warehouse': select_branch_code,
      });
      final response = await http.get(uri, headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _productIncomingData =
              List<Map<String, dynamic>>.from(jsonData['data']);
          _filteredProductIncomingData = _productIncomingData; // Initial filter
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load product incoming data');
      }
    } catch (error) {
      print('Error fetching product incoming data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    List<String> searchTerms = query.split(' ');

    setState(() {
      _filteredProductIncomingData = _productIncomingData.where((product) {
        final productName = product['product_name']?.toLowerCase() ?? '';
        final serialNumber = product['serial_number']?.toLowerCase() ?? '';

        return searchTerms.every((term) =>
            productName.contains(term) || serialNumber.contains(term));
      }).toList();
    });
  }

  // int _calculateTotalQuantity() {
  //   return _filteredProductIncomingData.fold<int>(
  //     0,
  //     (sum, product) =>
  //         sum + (double.tryParse(product['qty_done'] ?? '0')?.toInt() ?? 0),
  //   );
  // }

  int _calculateTotalItems() {
    return _filteredProductIncomingData.length;
  }

  void _selectBranch(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredBranches = List.from(branch_codes_area);

    // Clear search text and reset filtered branches on open
    searchController.clear();
    filteredBranches = List.from(branch_codes_area);

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
                filteredBranches = branch_codes_area.where((branch) {
                  String branchName = branch["branch_name"]!.toLowerCase();
                  String branchCode = branch["branch_code"]!.toLowerCase();
                  return branchName.contains(searchText) ||
                      branchCode.contains(searchText);
                }).toList();
              });
            }

            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus(); // Close the keyboard
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
                    // Search Field
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: searchController,
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
                                            _filterBranches();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                _filterBranches();
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'จำนวน ${filteredBranches.length} สาขา',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                                select_branch_code = branchCode;
                                select_branch_name = branchName;
                              });
                              await fetchProductIncomingData();
                              Navigator.pop(context);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                leading: Icon(
                                  Icons.storefront,
                                  color: isSelected
                                      ? Colors.orangeAccent
                                      : Colors.grey[400],
                                  size: 24,
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
                                    fontFamily: 'Kanit',
                                  ),
                                ),
                                subtitle: Text(
                                  branchCode,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontFamily: 'Kanit',
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
  @override
  Widget build(BuildContext context) {
    final quantityFormatter = NumberFormat('#,##0');

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: const Text(
            'In Transit',
            style: TextStyle(color: Colors.white),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            GestureDetector(
              onTap: branch_codes_area.length > 1
                  ? () => _selectBranch(context)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'สาขา: $select_branch_name',
                        style: const TextStyle(
                          fontSize: 16,
                          // fontWeight: FontWeight.bold,
                          fontFamily: 'Kanit',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow
                            .ellipsis, // Prevent overflow by adding ellipsis
                      ),
                    ),
                    if (branch_codes_area.length > 1) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ],
                ),
              ),
            ),
            // Modified Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 20.0),
                  hintText: 'ค้นหาชื่อสินค้า หรือ Serial Number',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'Kanit',
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
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
                style: const TextStyle(fontFamily: 'Kanit'),
              ),
            ),
            if (!isLoading && _filteredProductIncomingData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'จำนวนสินค้าทั้งหมด: ${_calculateTotalItems()} รายการ',
                    style: const TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? _buildShimmerEffect()
                  : _filteredProductIncomingData.isEmpty
                      ? const Center(
                          child: Text('ไม่พบข้อมูลสินค้า'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredProductIncomingData.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProductIncomingData[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${index + 1}. ', // ลำดับรายการ
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Kanit',
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                product['product_name'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Kanit',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantity Done: ${quantityFormatter.format(double.parse(product['qty_done'] ?? '0'))} ${product['uom'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Kanit',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          'DOH Company: ${product['DOH COMPANY'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Kanit',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SN: ${product['serial_number'] ?? 'No'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Kanit',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.end,
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
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    );
  }
}
