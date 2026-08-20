import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  static const String _fileName = 'user_data.json';
  
  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }
  
  static Future<void> saveOid(String oid) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      Map<String, dynamic> data = {};
      
      if (await file.exists()) {
        final content = await file.readAsString();
        data = jsonDecode(content);
      }
      
      data['userOid'] = oid;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('❌ خطأ في حفظ Oid: $e');
    }
  }
  
  static Future<String> loadOid() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        return data['userOid'] ?? '';
      }
      return '';
    } catch (e) {
      print('❌ خطأ في تحميل Oid: $e');
      return '';
    }
  }
  
  static Future<void> saveBID(String bid) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      Map<String, dynamic> data = {};
      
      if (await file.exists()) {
        final content = await file.readAsString();
        data = jsonDecode(content);
      }
      
      data['userBID'] = bid;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('❌ خطأ في حفظ BID: $e');
    }
  }
  
  static Future<String> loadBID() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        return data['userBID'] ?? '';
      }
      return '';
    } catch (e) {
      print('❌ خطأ في تحميل BID: $e');
      return '';
    }
  }
  
  static Future<void> clearOid() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('💾 تم مسح Oid من ملف محلي');
      }
    } catch (e) {
      print('❌ خطأ في مسح Oid: $e');
    }
  }
  
  static Future<void> clearBID() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        data.remove('userBID');
        await file.writeAsString(jsonEncode(data));
        print('💾 تم مسح BID من ملف محلي');
      }
    } catch (e) {
      print('❌ خطأ في مسح BID: $e');
    }
  }
  
  static Future<void> saveHost(String host) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      Map<String, dynamic> data = {};
      
      if (await file.exists()) {
        final content = await file.readAsString();
        data = jsonDecode(content);
      }
      
      data['host'] = host;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('❌ خطأ في حفظ HOST: $e');
    }
  }
  
  static Future<String> loadHost() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        final host = data['host'] ?? '192.168.92.20';
        return host;
      }
      return '192.168.92.20';
    } catch (e) {
      return '192.168.92.20';
    }
  }
}
