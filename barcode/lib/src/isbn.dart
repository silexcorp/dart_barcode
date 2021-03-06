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

import 'barcode_operations.dart';
import 'ean13.dart';

class BarcodeIsbn extends BarcodeEan13 {
  const BarcodeIsbn(bool drawEndChar, this.drawIsbn) : super(drawEndChar);

  final bool drawIsbn;

  @override
  double marginTop(
      bool drawText, double width, double height, double fontHeight) {
    if (!drawText || !drawIsbn) {
      return super.marginTop(drawText, width, height, fontHeight);
    }

    return fontHeight;
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
    yield* super.makeText(data, width, height, fontHeight, lineWidth);

    if (drawIsbn) {
      final double top = marginTop(true, width, height, fontHeight);
      final String isbn = data.substring(0, 3) +
          '-' +
          data.substring(3, 12) +
          '-' +
          data.substring(12, 13);

      yield BarcodeText(
        left: 0,
        top: 0,
        width: width,
        height: top,
        text: 'ISBN $isbn',
        align: BarcodeTextAlign.center,
      );
    }
  }

  @override
  String get name => 'ISBN';
}
