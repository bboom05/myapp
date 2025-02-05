const String _baseUrl = "https://app01.tgfone.com/";
const String _baseUrlApi = "https://app01.tgfone.com/api-Flutter/";
const String _baseUrlApiQR = "https://app01.tgfone.com/qrcode/";
const String _baseUrlLogApi = "https://app01.tgfone.com/api-Flutterv2/";

const String _baseUrlProd = "https://arnold.tg.co.th:3001/api-Flutterv2/"; // Production



const String _baseUrlUAT = "https://arnold.tg.co.th:3002/superapp-uat/"; // UAT
const String _baseUrlAuthUAT = "https://arnold.tg.co.th:3002/superapp-auth-uat/"; // UAT
const String _baseUrlContact = "https://arnold.tg.co.th:3002/superapp-contact/"; // UAT
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

  // String userLogin = '${_baseUrlApi}datauser/index.php';
  // String getProduct = '${_baseUrlApiQR}qr_redirect'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  // String allProduct = '${_baseUrlProd}dataproducts'; // ดึงข้อมูลสินค้าทั้งหมด หน้าแรกแอป
  // String getProductAndPromotion = '${_baseUrlUAT}datauat'; // ดึงข้อมูลสินค้า และโปรโมชั่น
  // String checkPromotion = '${_baseUrlUAT}getDatauatpromotion'; // ดึงข้อมูลสินค้า และโปรโมชั่น
  // String productIncoming = '${_baseUrlUAT}getDatproductincoming'; // ดึงข้อมูลสินค้า Incomming Intransit
  // String userLoginAuth = '${_baseUrlAuth}api-auth-uat/login'; // Login authen
  // String userSignup = '${_baseUrlAuth}api-auth-uat/signup'; // Signup
  // String contactus = '${_baseUrlAuth}api-contact/contact'; // Contact
  // String logActivity = '${_baseUrlLogApi}php_log/save_log.php'; // บันทึก Log การใช้งาน 
    
  // UAT SUCCESS
  String getProductAndPromotion = '${_baseUrlUAT}datauat'; // ดึงข้อมูลสินค้า และโปรโมชั่น
  String checkPromotion = '${_baseUrlUAT}getDatauatpromotion'; // ดึงข้อมูลสินค้า และโปรโมชั่น
  String allProduct = '${_baseUrlUAT}datauatproducts';  // ดึงข้อมูลสินค้าทั้งหมด หน้าแรกแอป
  String productIncoming = '${_baseUrlUAT}getDatproductincominguat'; // ดึงข้อมูลสินค้า Incomming Intransit
  String userLoginAuth = '${_baseUrlAuthUAT}login'; // Login authen
  String userSignup = '${_baseUrlAuthUAT}signup'; // Signup
  String contactus = '${_baseUrlContact}contact'; // Contact
  String getProduct = '${_baseUrlApiQR}qr_redirect'; // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API 
  String logActivity = '${_baseUrlLogApi}php_log/save_log.php'; // บันทึก Log การใช้งาน
  // String userLogin = '${_baseUrlApi}datauser/index.php';

  Info() : super();
}



// https://app01.tgfone.com/api-Flutter/datauser/index.php Login
// https://app01.tgfone.com/qrcode/qr_redirect // ดึงข้อมูลสินค้าที่มาจากการสแกนจาก API
// https://arnold.tg.co.th:3001/api-Flutterv2/dataproducts  ดึงข้อมูลสินค้าทั้งหมด หน้าแรกแอป
// https://arnold.tg.co.th:3001/api-Flutterv2/data  ดึงข้อมูลรายละเอียดสินค้าจากการกดรายการสินค้าที่หน้าแรกของแอป




