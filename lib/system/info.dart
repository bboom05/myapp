const String _baseUrl = "https://app01.tgfone.com/";
const String _baseUrlApi = "https://app01.tgfone.com/api-Flutter/";
const String _baseUrlApiQR = "https://app01.tgfone.com/qrcode/";
const String _baseUrlSecondApi = "http://203.154.201.78:3001/api-Flutter/";

const String _baseUrlProd = "https://arnold.tg.co.th:3001/api-Flutterv2/";
const String _domain = "app01.tgfone.com";

class Info {
  // Config
  String userAPI = 'tgdatauser';
  String passAPI = 'tgf0n3';
  String userAPIProd = 'TgApp01';
  String passAPIProd = '#0fUzY90';
  String domain = _domain; 
  String baseUrl = _baseUrl;
  String baseUrlApi = _baseUrlApi;
  String baseUrlProd = _baseUrlProd;

  String userLogin = '${_baseUrlApi}datauser/index.php';
  String getBranchData = '${_baseUrlApi}datauser/index.php';
  // String getProduct = '${_baseUrlApi}datauser/getProduct.php'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  String getProduct = '${_baseUrlApiQR}qr_redirect'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  // String searchProduct = '${_baseUrlApi}datauser/searchProduct.php'; // ดึงข้อมูลสินค้า
  String allProduct = '${_baseUrlProd}dataproducts'; // ดึงข้อมูลสินค้า
  String getProductAndPromotion = '${_baseUrlProd}data'; // ดึงข้อมูลสินค้า

  String getGroupBrand = '${_baseUrlApi}datauser/groupBrandTags.php'; // ดึงข้อมูล Brand
  String getProductExpress = '${_baseUrlSecondApi}data'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  String getPremiumData = '${_baseUrlApi}datauser/getPremiumData.php';
    

  Info() : super();
}



// https://app01.tgfone.com/api-Flutter/datauser/index.php Login
// https://app01.tgfone.com/qrcode/qr_redirect // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API
// https://arnold.tg.co.th:3001/api-Flutterv2/dataproducts  ดึงข้อมูลสินค้าทั้งหมด หน้าแรกแอป
// https://arnold.tg.co.th:3001/api-Flutterv2/data  ดึงข้อมูลรายละเอียดสินค้าจากการกดรายการสินค้าที่หน้าแรกของแอป




