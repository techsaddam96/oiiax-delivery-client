import 'dart:io';

import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:excel_community/excel_community.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ShipmentExportException implements Exception {
  const ShipmentExportException(this.message);

  final String message;
}

class ShipmentExportResult {
  const ShipmentExportResult({required this.file, required this.wasOpened});

  final File file;
  final bool wasOpened;
}

/// Exports operational shipment data only. Private recipient, address,
/// driver, notes and location information must never be added here.
class ShipmentExportService {
  const ShipmentExportService._();

  static Future<ShipmentExportResult> exportAndOpen({
    required List<Shipment> shipments,
    required bool isArabic,
  }) async {
    if (shipments.isEmpty) {
      throw ShipmentExportException(
        isArabic
            ? 'لا توجد شحنات لتصديرها.'
            : 'There are no shipments to export.',
      );
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Shipments'];
      excel.setDefaultSheet('Shipments');

      final headers = isArabic
          ? const [
              'رقم الشحنة',
              'نوع الشحنة',
              'الحالة',
              'تاريخ الإنشاء',
              'قيمة الشحنة الإجمالية (JOD)',
              'حالة تعيين السائق',
              'حالة الإرجاع',
              'الحالة المحاسبية',
            ]
          : const [
              'Shipment number',
              'Shipment type',
              'Status',
              'Created at',
              'Total shipment value (JOD)',
              'Driver assignment',
              'Return status',
              'Accounting status',
            ];

      sheet.appendRow(headers.map(TextCellValue.new).toList());
      for (final shipment in shipments) {
        sheet.appendRow([
          TextCellValue(_safeCell(shipment.policyNum)),
          TextCellValue(_safeCell(_shipmentType(shipment, isArabic))),
          TextCellValue(_safeCell(_shipmentStatus(shipment, isArabic))),
          TextCellValue(_safeCell(_formatDate(shipment.createdAt, isArabic))),
          DoubleCellValue(shipment.totalCost),
          TextCellValue(_safeCell(_driverAssignment(shipment, isArabic))),
          TextCellValue(_safeCell(_returnStatus(shipment, isArabic))),
          TextCellValue(_safeCell(_accountingStatus(shipment, isArabic))),
        ]);
      }

      for (var columnIndex = 0; columnIndex < headers.length; columnIndex++) {
        sheet.setColumnWidth(columnIndex, columnIndex == 0 ? 22 : 25);
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: 0,
        ));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('FFFF751F'),
          fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw const ShipmentExportException('encode_failed');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(
        '${directory.path}${Platform.pathSeparator}shipments_$timestamp.xlsx',
      );
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(
        file.path,
        type:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      return ShipmentExportResult(
        file: file,
        wasOpened: result.type == ResultType.done,
      );
    } on ShipmentExportException catch (error) {
      if (error.message == 'encode_failed') {
        throw ShipmentExportException(
          isArabic
              ? 'تعذر إنشاء ملف الشحنات. حاول مرة أخرى.'
              : 'Unable to create the shipments file. Please try again.',
        );
      }
      rethrow;
    } catch (_) {
      throw ShipmentExportException(
        isArabic
            ? 'تعذر تصدير الشحنات حاليًا. حاول مرة أخرى.'
            : 'Unable to export shipments right now. Please try again.',
      );
    }
  }

  static String _shipmentType(Shipment shipment, bool isArabic) {
    final localizedName = isArabic ? shipment.typeNameAr : shipment.typeNameEn;
    if (localizedName != null && localizedName.trim().isNotEmpty) {
      return localizedName.trim();
    }
    if (!isArabic && shipment.deliveryTypeNameEn.trim().isNotEmpty) {
      return shipment.deliveryTypeNameEn.trim();
    }
    const arabicTypes = {
      1: 'فوري',
      2: 'مجدول',
      3: 'نفس اليوم',
      4: 'اليوم التالي',
      5: 'اقتصادي',
      6: 'سريع',
      7: 'بدون تلامس',
    };
    const englishTypes = {
      1: 'Instant',
      2: 'Scheduled',
      3: 'Same day',
      4: 'Next day',
      5: 'Economy',
      6: 'Express',
      7: 'Contactless',
    };
    return (isArabic ? arabicTypes : englishTypes)[shipment.deliveryTypeId] ??
        (isArabic ? 'غير متوفر' : 'Not available');
  }

  static String _shipmentStatus(Shipment shipment, bool isArabic) {
    final localizedName =
        isArabic ? shipment.statusNameAr : shipment.statusNameEn;
    if (localizedName != null && localizedName.trim().isNotEmpty) {
      return localizedName.trim();
    }
    const arabicStatuses = {
      1: 'قيد الانتظار',
      2: 'قيد التجهيز',
      3: 'تم الشحن',
      4: 'في الطريق',
      5: 'في انتظار التسليم',
      6: 'تم التسليم',
      7: 'تم الإلغاء',
      8: 'تم الإرجاع',
      9: 'فشل التسليم',
      10: 'في انتظار الاستلام',
      11: 'مكتمل',
    };
    const englishStatuses = {
      1: 'Pending',
      2: 'Processing',
      3: 'Dispatched',
      4: 'In transit',
      5: 'Out for delivery',
      6: 'Delivered',
      7: 'Cancelled',
      8: 'Returned',
      9: 'Failed delivery',
      10: 'Awaiting pickup',
      11: 'Completed',
    };
    final statusId = shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;
    return (isArabic ? arabicStatuses : englishStatuses)[statusId] ??
        (isArabic ? 'غير متوفر' : 'Not available');
  }

  static String _driverAssignment(Shipment shipment, bool isArabic) {
    final assigned = shipment.driverId != null && shipment.driverId! > 0;
    if (isArabic) return assigned ? 'تم التعيين' : 'بانتظار التعيين';
    return assigned ? 'Assigned' : 'Waiting for assignment';
  }

  static String _returnStatus(Shipment shipment, bool isArabic) {
    final returned = shipment.returnedShipment == 1 ||
        shipment.shipmentStatusId == 8 ||
        shipment.shipmentStatus == 8;
    if (isArabic) return returned ? 'مرتجع' : 'غير مرتجع';
    return returned ? 'Returned' : 'Not returned';
  }

  static String _accountingStatus(Shipment shipment, bool isArabic) {
    final settled = shipment.accountingShipment == 1;
    if (isArabic) return settled ? 'تمت المحاسبة' : 'قيد المحاسبة';
    return settled ? 'Settled' : 'Pending accounting';
  }

  static String _formatDate(String value, bool isArabic) {
    final parsed = JordanTime.parse(value);
    if (parsed == null) return value.trim().isEmpty ? '-' : value.trim();
    return DateFormat(
      'yyyy-MM-dd HH:mm',
      isArabic ? 'ar' : 'en',
    ).format(parsed);
  }

  static String _safeCell(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '-';
    return RegExp(r'^[=+@-]').hasMatch(trimmed) ? "'$trimmed" : trimmed;
  }
}
