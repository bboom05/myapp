const String _baseUrl = "https://app01.tgfone.com/";
const String _baseUrlApi = "https://app01.tgfone.com/api-Flutter/";
const String _baseUrlApiQR = "https://app01.tgfone.com/qrcode/";
const String _baseUrlSecondApi = "http://203.154.201.78:3001/api-Flutter/";
const String _domain = "app01.tgfone.com";

class Info {
  // Config
  String userAPI = 'tgdatauser';
  String passAPI = 'tgf0n3';  
  String userAPIProduct = 'TgApp01';
  String passAPIProduct = '#0fUzY90';
  String domain = _domain; 
  String baseUrl = _baseUrl;
  String baseUrlApi = _baseUrlApi;

  String userLogin = '${_baseUrlApi}datauser/index.php';
  String getBranchData = '${_baseUrlApi}datauser/index.php';
  // String getProduct = '${_baseUrlApi}datauser/getProduct.php'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  String getProduct = '${_baseUrlApiQR}qr_redirect'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  String searchProduct = '${_baseUrlApi}datauser/searchProductTest.php'; // ดึงข้อมูลสินค้า

  String getGroupBrand = '${_baseUrlApi}datauser/groupBrandTags.php'; // ดึงข้อมูล Brand
  String getProductExpress = '${_baseUrlSecondApi}data'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 

  Info() : super();
}
