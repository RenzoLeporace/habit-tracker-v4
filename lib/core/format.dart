import 'package:intl/intl.dart';

/// Formatos de la app, siempre en español de Argentina.
const localeApp = 'es_AR';

final _numero = NumberFormat('#,##0.00', localeApp);

/// Importe con separadores argentinos: `$ 1.234,50`. Nunca muestra `-0`.
String formatoMoneda(double importe) {
  final valor = importe.abs() < 0.005 ? 0.0 : importe;
  final texto = '\$ ${_numero.format(valor.abs())}';
  return valor < 0 ? '−$texto' : texto;
}

/// Convierte texto escrito por el usuario (`1.234,50`, `1234.5`, `1234`) a número.
double? leerImporte(String texto) {
  var limpio = texto.trim().replaceAll(r'$', '').replaceAll(' ', '');
  if (limpio.isEmpty) return null;
  final ultimaComa = limpio.lastIndexOf(',');
  final ultimoPunto = limpio.lastIndexOf('.');
  if (ultimaComa > ultimoPunto) {
    limpio = limpio.replaceAll('.', '').replaceAll(',', '.');
  } else if (ultimoPunto > ultimaComa && ultimaComa >= 0) {
    limpio = limpio.replaceAll(',', '');
  } else if (ultimoPunto >= 0 &&
      (limpio.split('.').length > 2 || limpio.length - ultimoPunto - 1 == 3)) {
    // Solo puntos: si separan miles (1.234 o 1.234.567), se quitan.
    limpio = limpio.replaceAll('.', '');
  }
  return double.tryParse(limpio);
}

String formatoFecha(DateTime fecha) =>
    DateFormat('dd/MM/yyyy', localeApp).format(fecha);

String formatoPorcentaje(double valor) => '${(valor * 100).round()} %';
