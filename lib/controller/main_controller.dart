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

  // Scan Barcode Method
  Future<void> scanBarCode() async {
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
      stdout.write("Error initializing database: $e");
    }
  }

  // Fetch Product Details
  Future<void> fetchProductDetails(String productId) async {
    try {
      var product = await MySQLHelper.getProductById(productId, table.value);
      if (product != null) {
        productDetails.value =
        'Id: ${product['id']}, Name: ${product['name']}, Price: ${product['price']}';
        stdout.write("${productDetails.value} ====== Fetched Successfully");
      } else {
        productDetails.value = "Product not found.";
      }
    } catch (e) {
      stdout.write("Error fetching product: $e");
    }
  }
}
