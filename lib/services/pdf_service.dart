import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/incidencia.dart';

class PDFService {
  /// Genera la Orden de Trabajo en formato PDF exacto al modelo proporcionado
  static Future<void> generateOrdenTrabajo(Incidencia incidencia) async {
    final pdf = pw.Document();

    // Crear el documento PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header con logo y datos RPS
              _buildHeader(),
              
              pw.SizedBox(height: 20),
              
              // Título ORDEN DE TRABAJO
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    'ORDEN DE TRABAJO',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              // Número de orden y fecha
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nº Orden: ${incidencia.numeroOrden}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(incidencia.fechaIncidencia)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              
              // DATOS DEL CLIENTE
              _buildSectionTitle('DATOS DEL CLIENTE'),
              pw.SizedBox(height: 8),
              _buildTableRow('Nombre:', incidencia.comunidadNombre),
              _buildTableRow('Dirección:', incidencia.comunidadDireccion),
              _buildTableRow('Ciudad:', '${incidencia.comunidadCiudad} - ${incidencia.comunidadCodigoPostal}'),
              if (incidencia.personaContacto != null)
                _buildTableRow('Persona de contacto:', incidencia.personaContacto!),
              if (incidencia.telefonoContacto != null)
                _buildTableRow('Teléfono:', incidencia.telefonoContacto!),
              
              pw.SizedBox(height: 15),
              
              // DESCRIPCIÓN DEL TRABAJO
              _buildSectionTitle('DESCRIPCIÓN DEL TRABAJO'),
              pw.SizedBox(height: 8),
              _buildTableRow('Tipo:', incidencia.getTipoText()),
              _buildTableRow('Prioridad:', incidencia.getPrioridadText()),
              if (incidencia.ubicacionEspecifica != null)
                _buildTableRow('Ubicación:', incidencia.ubicacionEspecifica!),
              
              pw.SizedBox(height: 10),
              
              // Descripción detallada en caja
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Detalle:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      incidencia.descripcionDetallada,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              // DATOS DEL PROVEEDOR (si está asignado)
              if (incidencia.proveedorNombre != null) ...[
                _buildSectionTitle('PROVEEDOR ASIGNADO'),
                pw.SizedBox(height: 8),
                _buildTableRow('Nombre:', incidencia.proveedorNombre!),
                if (incidencia.proveedorTelefono != null)
                  _buildTableRow('Teléfono:', incidencia.proveedorTelefono!),
                if (incidencia.proveedorEmail != null)
                  _buildTableRow('Email:', incidencia.proveedorEmail!),
                pw.SizedBox(height: 15),
              ],
              
              // PRESUPUESTO
              _buildSectionTitle('PRESUPUESTO'),
              pw.SizedBox(height: 8),
              _buildTableRow('Límite de gasto:', incidencia.presupuestoLimite ?? 'A presupuestar'),
              
              pw.SizedBox(height: 15),
              
              // OBSERVACIONES
              _buildSectionTitle('OBSERVACIONES'),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 60,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  incidencia.notasHistorial.isNotEmpty 
                      ? incidencia.notasHistorial.join('\n') 
                      : '',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              
              pw.Spacer(),
              
              // FIRMAS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildFirmaBox('Firma del Cliente'),
                  _buildFirmaBox('Firma del Proveedor'),
                ],
              ),
              
              pw.SizedBox(height: 10),
              
              // Fecha de generación
              pw.Center(
                child: pw.Text(
                  'Documento generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Generar y descargar PDF usando printing package
    final bytes = await pdf.save();
    
    // Usar printing package para descarga en web (compatible)
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Orden_Trabajo_${incidencia.numeroOrden}.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue700, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RPS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Administración de Fincas',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blue800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'C/ Juan XXIII, 13',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                '30850 Totana (Murcia)',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Tel: 647 461 140',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Email: info@rpsaf.es',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFirmaBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 180,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
