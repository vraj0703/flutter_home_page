// import 'dart:io';
//
// import 'package:flutter_core/domain/enums/storage_directory_options.dart';
// import 'package:flutter_core/domain/exception/storage_exceptions.dart';
// import 'package:flutter_core/domain/files_storage/file_storage.dart';
// import 'package:flutter_core/domain/models/storage_args.dart';
// import 'package:path_provider/path_provider.dart';
//
// class FlutterStorage implements IFileStorage {
//   // Within the chosen directory, this is the foldername to write into
//   final String _folderName;
//
//   // This directory object is the base directory for our storage module
//   final Directory _location;
//
//   // This constructor is the main INIT function for TwinFlutterStorage
//   // Has to be Future<T> because we need to set the initial directory
//   static Future<IFileStorage> create(
//       {required StorageArgs storageArgs}) async {
//     Directory dirToUse;
//     switch (storageArgs.dirLocation) {
//       case StorageDirectoryOptions.cache:
//         dirToUse = await getTemporaryDirectory();
//         break;
//       case StorageDirectoryOptions.document:
//         dirToUse = await getApplicationDocumentsDirectory();
//         break;
//     }
//     return FlutterStorage._(storageArgs.folderName, dirToUse);
//   }
//
//   String get _fullPath => '${_location.path}/$_folderName';
//
//   @override
//   bool write(
//       {required String content,
//         required String filename,
//         FileMode mode = FileMode.write}) {
//     // First we check if file even exists
//     File existingFile = File('$_fullPath/$filename');
//     if (existingFile.existsSync()) {
//       //Overwrite the contents here
//       existingFile.writeAsStringSync(content);
//       return true;
//     } else {
//       Directory existingDirectory = Directory(_fullPath);
//       // If this directory does not exist, create that first as well, then write the file
//       if (!existingDirectory.existsSync()) {
//         Directory(_fullPath).createSync();
//       }
//       // Create the file and write contnets here
//       existingFile.createSync();
//       existingFile.writeAsStringSync(content);
//       return true;
//     }
//   }
//
//   @override
//   String read({required String filename}) {
//     File existingFile = File('$_fullPath/$filename');
//     // Only if file exists, read the string
//     if (existingFile.existsSync()) {
//       return existingFile.readAsStringSync();
//     } else {
//       // Throw this specific exception that we can catch in case we need to
//       // fetch from API at this point
//       throw FileNotFound('File not found at this path: ${existingFile.path}');
//     }
//   }
//
//   @override
//   // Sync call to see if file exists
//   bool fileExists(String filename) {
//     return File('$_fullPath/$filename').existsSync();
//   }
//
//   @override
//   // Provides fileInfo for given file
//   // If file does not exist, look for FileStat.type == .notFound
//   FileStat fileInfo(String filename) {
//     return File('$_fullPath/$filename').statSync();
//   }
//
//   @override
//   // deletes file based on filename
//   removeFile(String filename) {
//     File file = File('$_fullPath/$filename');
//     file.deleteSync();
//   }
//
//   // default constructor - only should be used in static CREATE func
//   FlutterStorage._(this._folderName, this._location);
// }
