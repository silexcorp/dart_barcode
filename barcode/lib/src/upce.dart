/*
 * Copyright (C) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: omit_local_variable_types

import 'barcode_exception.dart';
import 'barcode_maps.dart';
import 'barcode_operations.dart';
import 'ean.dart';
import 'upca.dart';

class BarcodeUpcE extends BarcodeEan {
  const BarcodeUpcE(this.fallback);

  /// Fallback to UPC-A if the code cannot be converted to UPC-E
  final bool fallback;

  @override
  String get name => 'UPC E';

  @override
  int get minLength => 11;

  @override
  int get maxLength => 12;

  @override
  void verify(String data) {
    final String upca = checkLength(data, maxLength);
    if (!fallback) {
      _upcaToUpce(upca);
    }
    super.verify(data);
  }

  String _upcaToUpce(String data) {
    final RegExp exp = RegExp(r'^[01](\d\d+)([0-2]000[05-9])(\d*)\d$');
    final RegExpMatch match = exp.firstMatch(data);

    if (match == null) {
      throw BarcodeException('Unable to convert "$data" to $name Barcode');
    }

    final String left = match.group(1);
    final String right = match.group(3);
    String last;

    switch (match.group(2)) {
      case '00000':
        if (left.length == 2) {
          last = '0';
        } else if (left.length == 3) {
          last = '3';
        } else if (left.length == 4) {
          last = '4';
        }
        break;
      case '10000':
        last = '1';
        break;
      case '20000':
        last = '2';
        break;
      case '00005':
        last = '5';
        break;
      case '00006':
        last = '6';
        break;
      case '00007':
        last = '7';
        break;
      case '00008':
        last = '8';
        break;
      case '00009':
        last = '9';
        break;
    }

    if (last == null) {
      throw BarcodeException('Unable to convert "$data" to $name Barcode');
    }

    return left + right + last;
  }

  @override
  Iterable<bool> convert(String data) sync* {
    data = checkLength(data, maxLength);
    final int first = data.codeUnitAt(0);
    final int last = data.codeUnitAt(11);

    try {
      data = _upcaToUpce(data);
    } on BarcodeException {
      if (fallback) {
        yield* const BarcodeUpcA().convert(data);
        return;
      }
      rethrow;
    }

    // Start
    yield* add(BarcodeMaps.eanStartEnd, 3);

    final int parityRow = BarcodeMaps.upce[last];
    final int parity = first == 0x30 ? parityRow : parityRow ^ 0x3f;

    int index = 0;
    for (int code in data.codeUnits) {
      final List<int> codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException(
            'Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      yield* add(codes[(parity >> index) & 1 == 0 ? 1 : 0], 7);
      index++;
    }

    // Stop
    yield* add(BarcodeMaps.eanEndUpcE, 6);
  }

  @override
  double marginLeft(
      bool drawText, double width, double height, double fontHeight) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double marginRight(
      bool drawText, double width, double height, double fontHeight) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    bool drawText,
  ) {
    if (!drawText) {
      return super.getHeight(index, count, width, height, fontHeight, drawText);
    }

    final double h = height - fontHeight;

    if (index + count < 4 || index > 44) {
      return h + fontHeight / 2;
    }

    return h;
  }

  @override
  Iterable<BarcodeText> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double lineWidth,
  ) sync* {
    data = checkLength(data, maxLength);
    final String first = data.substring(0, 1);
    final String last = data.substring(11, 12);

    try {
      data = _upcaToUpce(data);
    } on BarcodeException {
      if (fallback) {
        yield* const BarcodeUpcA()
            .makeText(data, width, height, fontHeight, lineWidth);
        return;
      }
      rethrow;
    }

    final double w = lineWidth * 7;
    final double left = marginLeft(true, width, height, fontHeight);
    final double right = marginRight(true, width, height, fontHeight);

    yield BarcodeText(
      left: 0,
      top: height - fontHeight,
      width: left - lineWidth,
      height: fontHeight,
      text: first,
      align: BarcodeTextAlign.right,
    );

    double offset = left + lineWidth * 3;

    for (int i = 0; i < data.length; i++) {
      yield BarcodeText(
        left: offset,
        top: height - fontHeight,
        width: w,
        height: fontHeight,
        text: data[i],
        align: BarcodeTextAlign.center,
      );

      offset += w;
    }

    yield BarcodeText(
      left: width - right + lineWidth,
      top: height - fontHeight,
      width: right - lineWidth,
      height: fontHeight,
      text: last,
      align: BarcodeTextAlign.left,
    );
  }
}
