import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:mysql_client/mysql_client.dart';

import '../utils/helpers/database_connector.dart';
import '../utils/helpers/persistance_helper.dart';
import '../utils/string_constants.dart';

class MainController extends GetxController {
  // Text Editing Controller
  final TextEditingController getItemController = TextEditingController();

  static const platform = MethodChannel('scanner_channel');

  // Reactive Variables
  var getItemID = "".obs;
  var barcode = "".obs;
  var server = "".obs;
  var table = "".obs;
  var userName = "".obs;
  var database = "".obs;
  var password = "".obs;
  var productDetails = "No product selected.".obs;
  var productID = "".obs;
  var productName = "".obs;
  var productPrice = "".obs;
  var productDetailsMap ={}.obs;

  // MySQL connection
  static MySQLConnection? _connection;

  @override
  void onInit() {
    super.onInit();
    // Set up method channel to listen for barcode results.
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onBarcodeScanned') {
        barcode.value = call.arguments; // Update the barcode value.
      }
    });
  }

  void startScan() async {
    const scanIntent = 'nlscan.action.SCANNER_TRIG';

    try {
      // Attempt to start the scanner
      await platform.invokeMethod('startScanner', {'intent': scanIntent});
    } on PlatformException catch (e) {
      // If the scanner is not available, use the fallback barcode scanner
      print('Error: Scanner not available, using fallback scanner. $e');

      await scanBarCode();
    }
  }

  // Scan Barcode Method
  Future<void> scanBarCode() async {
    try {
      final result = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.DEFAULT,
      );

      if (result != '-1') {
        barcode.value = result;
        print('$result ----------------------- Barcode value ------');
        productID.value = result;

        print('Attempting to fetch product details...');
         await fetchProductDetails();

        if (productDetailsMap.value.isNotEmpty) {
          print('Product details fetched successfully: $productDetails');
        } else {
          print('Product details not found.');
        }
      } else {
        print('Scan canceled by the user.');
      }
    } catch (e) {
      print('Error in scanBarCode: $e');
    }
  }


  // Initialize Database
  Future<void> initializeDatabase() async {
    server.value = await HelperServices.getServerData(StringConstants.server);
    database.value =
        await HelperServices.getServerData(StringConstants.dataBase);
    userName.value =
        await HelperServices.getServerData(StringConstants.userName);
    password.value =
        await HelperServices.getServerData(StringConstants.password);
    table.value = await HelperServices.getServerData(StringConstants.table);

    print("${server.value} === ${userName.value} === $table");

    try {
      _connection = await MySQLConnection.createConnection(
        host: server.value,
        port: 3306,
        userName: userName.value,
        password: password.value,
        databaseName: database.value,
      );
      await _connection!.connect();
    } catch (e) {
      print("Error initializing database: $e");
    }
  }

  // Fetch Product Details
  Future fetchProductDetails() async {
    try {
      if (_connection == null) {
        print("Connection Error>>>-------$_connection");
        throw Exception("Database connection is not initialized.");
      }
      print(_connection);

      var query = 'SELECT * FROM $table WHERE product_code = :id';


      var result = await _connection!.execute(
        query,
        {'id': barcode},
      );

      print(result.toString()+"---------result");

      if (result.rows.isNotEmpty) {
        // productDetails.value = jsonDecode(result.rows.toString());
        productDetailsMap.value = result.rows.map((row) => row.assoc()).first;
        productID.value = productDetailsMap["id"].toString();
        productName.value = productDetailsMap["product_name"].toString();
        productPrice.value = productDetailsMap["price"].toString();
        print(productDetails);
        print(productDetailsMap.toString() + "-------------------- result==--------------");
        print('${result.rows}---------------- Output');
        return result.rows.first.assoc();
      } else {
        productDetails.value = "Product not found.";
      }
    } catch (e) {
      stdout.write("Error fetching product: $e");
    }
  }
}
