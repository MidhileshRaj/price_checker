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

  void startScan() {
    const scanIntent = 'nlscan.action.SCANNER_TRIG';
    platform.invokeMethod('startScanner', {'intent': scanIntent});
  }


  // Scan Barcode Method
  Future scanBarCode() async {
    try {
      final result = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.DEFAULT,
      );
      barcode.value = result;
      getItemID.value = result;
    } on PlatformException {
      throw Exception("Error fetching ID");
    }
  }


  // Initialize Database
  Future<void> initializeDatabase() async {
    server.value = await HelperServices.getServerData(StringConstants.server);
    database.value = await HelperServices.getServerData(StringConstants.dataBase);
    userName.value = await HelperServices.getServerData(StringConstants.userName);
    password.value = await HelperServices.getServerData(StringConstants.password);
    table.value = await HelperServices.getServerData(StringConstants.table);

    print("${server.value} === ${userName.value} ===");

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
      print(barcode.toString()+"=================-===============--========");
      if (_connection == null) {
        print("Connection Error>>>-------$_connection");
        throw Exception("Database connection is not initialized.");
      }

      var query = 'SELECT * FROM $table WHERE id = :id';

      var result = await _connection!.execute(
        query,
        {'id': barcode.toString()},
      );

      if (result.rows.isNotEmpty) {

         print(result.rows.toString()+'---------------- Output');
          stdout.write("${productDetails.value} ====== Fetched Successfully");
         return result.rows.first.assoc();
      }else {
        productDetails.value = "Product not found.";
      }

    } catch (e) {
      stdout.write("Error fetching product: $e");
    }
  }
}
