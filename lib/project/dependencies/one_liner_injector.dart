// import 'dart:async';
//
// import 'package:flutter_core/domain/models/boot_load.dart';
// import 'package:flutter_core/domain/models/user_info.dart';
// import 'package:get_it/get_it.dart';
// import 'package:injectable/injectable.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// @module
// abstract class OneLinerInjector {
//   @preResolve
//   Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
//
//   @lazySingleton
//   UserInfo get userInfo => GetIt.I.get<BootLoad>().userInfo;
// }
