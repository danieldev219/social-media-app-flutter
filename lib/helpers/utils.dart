import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/constants/colors.dart';
import 'package:social_media_app/constants/dimens.dart';
import 'package:social_media_app/constants/strings.dart';

abstract class AppUtils {
  static final storage = GetStorage();

  static void showLoadingDialog() {
    closeDialog();
    Get.dialog<void>(
      WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SizedBox(
              height: Dimens.hundred,
              child: CupertinoTheme(
                data: CupertinoTheme.of(Get.context!).copyWith(
                  brightness: Brightness.dark,
                  primaryColor: Colors.white,
                ),
                child: const CupertinoActivityIndicator(),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void showError(String message) {
    closeSnackBar();
    closeDialog();
    closeBottomSheet();
    if (message.isEmpty) return;
    Get.rawSnackbar(
      messageText: Text(
        message,
      ),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) {
            Get.back<void>();
          }
        },
        child: const Text(
          StringValues.okay,
        ),
      ),
      backgroundColor: const Color(0xFF503E9D),
      margin: Dimens.edgeInsets16,
      borderRadius: Dimens.fifteen,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  static void showBottomSheet(List<Widget> children) {
    closeBottomSheet();
    Get.bottomSheet(
      Padding(
        padding: Dimens.edgeInsets8_16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
      barrierColor:
          Theme.of(Get.context!).textTheme.bodyText1!.color!.withAlpha(90),
      backgroundColor: Theme.of(Get.context!).bottomSheetTheme.backgroundColor,
    );
  }

  static void showOverlay(Function func) {
    Get.showOverlay(
      loadingWidget: const CupertinoActivityIndicator(),
      opacityColor: Theme.of(Get.context!).bottomSheetTheme.backgroundColor!,
      opacity: 0.5,
      asyncFunction: () async {
        await func();
      },
    );
  }

  static void showSnackBar(String message, String type, {int? duration}) {
    closeSnackBar();
    Get.showSnackbar(
      GetSnackBar(
        margin: Dimens.edgeInsets16,
        borderRadius: Dimens.twentyFour,
        messageText: Text(
          message,
          style: TextStyle(
            color: (type == StringValues.error ||
                    type == StringValues.success ||
                    type == StringValues.warning)
                ? ColorValues.whiteColor
                : ThemeData().textTheme.bodyText1!.color,
          ),
        ),
        icon: Icon(
          type == StringValues.error
              ? CupertinoIcons.clear_circled_solid
              : type == StringValues.success
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.info_circle_fill,
          color: (type == StringValues.error ||
                  type == StringValues.success ||
                  type == StringValues.warning)
              ? ColorValues.whiteColor
              : ThemeData().iconTheme.color,
        ),
        shouldIconPulse: false,
        backgroundColor: type == StringValues.error
            ? ColorValues.errorColor
            : type == StringValues.warning
                ? ColorValues.warningColor
                : type == StringValues.success
                    ? ColorValues.successColor
                    : ThemeData().snackBarTheme.backgroundColor!,
        duration: Duration(seconds: duration ?? 3),
      ),
    );
  }

  /// Close any open snack bar.
  static void closeSnackBar() {
    if (Get.isSnackbarOpen) Get.back<void>();
  }

  /// Close any open dialog.
  static void closeDialog() {
    if (Get.isDialogOpen ?? false) Get.back<void>();
  }

  /// Close any open bottom sheet.
  static void closeBottomSheet() {
    if (Get.isBottomSheetOpen ?? false) Get.back<void>();
  }

  static void closeFocus() {
    if (FocusManager.instance.primaryFocus!.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  static Future<void> saveLoginDataToLocalStorage(_token, _expiresAt) async {
    if (_token!.isNotEmpty && _expiresAt!.isNotEmpty) {
      final data = jsonEncode({
        StringValues.token: _token,
        StringValues.expiresAt: _expiresAt,
      });

      await storage.write(StringValues.loginData, data);
      debugPrint('Auth details saved.');
    } else {
      debugPrint('Auth details could not saved.');
    }
  }

  static Future<dynamic> readLoginDataFromLocalStorage() async {
    if (storage.hasData(StringValues.loginData)) {
      final data = await storage.read(StringValues.loginData);
      var decodedData = jsonDecode(data) as Map<String, dynamic>;
      debugPrint('Auth details found.');
      return decodedData;
    }
    return null;
  }

  static Future<void> clearLoginDataFromLocalStorage() async {
    await storage.remove(StringValues.loginData);
    debugPrint('Auth details removed.');
  }

  static final androidUiSettings = AndroidUiSettings(
    toolbarColor: Theme.of(Get.context!).scaffoldBackgroundColor,
    toolbarTitle: StringValues.cropImage,
    toolbarWidgetColor: Theme.of(Get.context!).colorScheme.primary,
    backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
  );
  static const iOsUiSettings = IOSUiSettings(
    title: StringValues.cropImage,
    minimumAspectRatio: 1.0,
  );

  static void printLog(message) {
    debugPrint(
        "---------------------------------------------------------------");
    debugPrint(message.toString());
    debugPrint(
        "---------------------------------------------------------------");
  }

  static Future<dynamic> selectSingleImage({ImageSource? imageSource}) async {
    final _imagePicker = ImagePicker();
    final _imageCropper = ImageCropper();
    final pickedImage = await _imagePicker.pickImage(
      source: imageSource ?? ImageSource.gallery,
    );

    if (pickedImage != null) {
      var croppedFile = await _imageCropper.cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        cropStyle: CropStyle.circle,
        androidUiSettings: androidUiSettings,
        iosUiSettings: iOsUiSettings,
        compressQuality: 70,
        compressFormat: ImageCompressFormat.png,
      );

      return croppedFile;
    }

    return null;
  }

  static Future<dynamic> selectMultipleImage() async {
    final _imagePicker = ImagePicker();
    final _imageCropper = ImageCropper();
    var imageList = <File>[];
    final pickedImages = await _imagePicker.pickMultiImage();

    if (pickedImages != null) {
      for (var pickedImage in pickedImages) {
        var croppedFile = await _imageCropper.cropImage(
          sourcePath: pickedImage.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          androidUiSettings: androidUiSettings,
          iosUiSettings: iOsUiSettings,
          compressQuality: 70,
          compressFormat: ImageCompressFormat.png,
        );
        imageList.add(croppedFile!);
      }
    }

    return imageList;
  }
}
