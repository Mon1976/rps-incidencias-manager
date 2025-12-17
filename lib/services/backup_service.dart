import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/incidencia.dart';
import '../models/proveedor.dart';
import 'firebase_service.dart';
// dart:html removido - no compatible con APK

class BackupService {
  /// Exportar todas las incidencias a JSON (deshabilitado para APK)
  static Future<void> exportarBackup() async {
    throw UnsupportedError('Backup export requires dart:html (web only)');
    // Funcionalidad deshabilitada para compilación APK
    // Requiere dart:html para crear y descargar archivos en navegador
  }

  /// Importar incidencias desde archivo JSON (formato antiguo)
  static Future<ImportResult> importarBackupLegacy(String jsonContent) async {
    try {
      final data = json.decode(jsonContent);
      final items = data['items'] as List;
      
      int importadas = 0;
      int errores = 0;
      List<String> mensajesError = [];
      
      for (var item in items) {
        try {
          // Convertir formato antiguo a nuevo
          final incidencia = _convertirFormatoLegacy(item);
          
          // Guardar en Firebase
          await FirebaseService.addIncidencia(incidencia);
          importadas++;
        } catch (e) {
          errores++;
          mensajesError.add('Error en ${item['nOrden']}: $e');
        }
      }
      
      return ImportResult(
        total: items.length,
        importadas: importadas,
        errores: errores,
        mensajesError: mensajesError,
      );
    } catch (e) {
      throw Exception('Error al procesar archivo: $e');
    }
  }

  /// Convertir formato legacy al formato actual
  static Incidencia _convertirFormatoLegacy(Map<String, dynamic> item) {
    // Mapear estados
    EstadoIncidencia estado = EstadoIncidencia.pendiente;
    final estadoTexto = item['estado']?.toString().toLowerCase() ?? '';
    if (estadoTexto.contains('cerrada') || estadoTexto.contains('cerrado')) {
      estado = EstadoIncidencia.cerrada;
    } else if (estadoTexto.contains('proceso')) {
      estado = EstadoIncidencia.enProceso;
    } else if (estadoTexto.contains('asignada')) {
      estado = EstadoIncidencia.asignada;
    } else if (estadoTexto.contains('resuelta')) {
      estado = EstadoIncidencia.resuelta;
    }

    // Mapear urgencia a prioridad
    Prioridad prioridad = Prioridad.normal;
    final urgenciaTexto = item['urgencia']?.toString().toLowerCase() ?? '';
    if (urgenciaTexto.contains('urgente') || urgenciaTexto.contains('alta')) {
      prioridad = Prioridad.urgente;
    } else if (urgenciaTexto.contains('media')) {
      prioridad = Prioridad.normal;
    } else if (urgenciaTexto.contains('baja')) {
      prioridad = Prioridad.baja;
    }

    // Mapear tipo
    TipoIncidencia tipo = TipoIncidencia.otros;
    final tipoTexto = item['tipo']?.toString().toLowerCase() ?? '';
    if (tipoTexto.contains('electricidad') || tipoTexto.contains('eléctric')) {
      tipo = TipoIncidencia.electricidad;
    } else if (tipoTexto.contains('fontaner') || tipoTexto.contains('agua') || tipoTexto.contains('presión')) {
      tipo = TipoIncidencia.fontaneria;
    } else if (tipoTexto.contains('cerrajería') || tipoTexto.contains('cerraje')) {
      tipo = TipoIncidencia.cerrajeria;
    } else if (tipoTexto.contains('ascensor')) {
      tipo = TipoIncidencia.ascensor;
    } else if (tipoTexto.contains('limpieza')) {
      tipo = TipoIncidencia.limpieza;
    } else if (tipoTexto.contains('jardín') || tipoTexto.contains('jardinería')) {
      tipo = TipoIncidencia.jardineria;
    } else if (tipoTexto.contains('mantenimiento')) {
      tipo = TipoIncidencia.mantenimientoPreventivo;
    } else if (tipoTexto.contains('aver') || tipoTexto.contains('urgente')) {
      tipo = TipoIncidencia.averiaUrgente;
    }

    // Parsear fecha
    DateTime fechaIncidencia = DateTime.now();
    try {
      if (item['fecha'] != null) {
        fechaIncidencia = DateTime.parse(item['fecha'].toString());
      }
    } catch (e) {
      // Si falla el parse, usar fecha actual
    }

    // Extraer datos de comunidad
    final comunidadNombre = item['comunidad']?.toString() ?? 'Sin especificar';
    final ubicacion = item['ubicacion']?.toString() ?? '';
    
    // Crear nota de historial si hay notas internas
    List<String> notasHistorial = [];
    if (item['notasInternas'] != null && item['notasInternas'].toString().isNotEmpty) {
      notasHistorial.add('${DateFormat('dd/MM/yyyy HH:mm').format(fechaIncidencia)} - ${item['notasInternas']}');
    }
    if (item['notaUrgencia'] != null && item['notaUrgencia'].toString().isNotEmpty) {
      notasHistorial.add('Nota de urgencia: ${item['notaUrgencia']}');
    }

    return Incidencia(
      id: item['id']?.toString() ?? '',
      numeroOrden: item['nOrden']?.toString() ?? '',
      fechaIncidencia: fechaIncidencia,
      prioridad: prioridad,
      estado: estado,
      tipo: tipo,
      comunidadNombre: comunidadNombre,
      comunidadDireccion: ubicacion,
      comunidadCiudad: 'Totana',
      comunidadCodigoPostal: '30850',
      descripcionDetallada: item['descripcion']?.toString() ?? '',
      ubicacionEspecifica: ubicacion.isNotEmpty ? ubicacion : null,
      proveedorNombre: item['responsable']?.toString(),
      reportadoPor: item['comunicante']?.toString(),
      reportadoTelefono: item['telefono']?.toString(),
      presupuestoLimite: item['coste']?.toString().isNotEmpty == true 
          ? item['coste'].toString() 
          : 'A presupuestar',
      notas: [], // Inicializar campo de notas
      notasHistorial: notasHistorial,
    );
  }

  /// Importar incidencias desde archivo JSON (formato nuevo)
  static Future<ImportResult> importarBackup(String jsonContent) async {
    if (!kIsWeb) {
      throw UnsupportedError('Backup import is only supported on web platform');
    }
    try {
      final data = json.decode(jsonContent);
      
      // Detectar formato
      if (data.containsKey('items')) {
        // Formato legacy
        return await importarBackupLegacy(jsonContent);
      }
      
      // Formato nuevo
      final incidenciasData = data['incidencias'] as List;
      
      int importadas = 0;
      int errores = 0;
      List<String> mensajesError = [];
      
      for (var incData in incidenciasData) {
        try {
          final incidencia = Incidencia.fromFirestore(
            incData as Map<String, dynamic>,
            incData['id'] ?? '',
          );
          
          await FirebaseService.addIncidencia(incidencia);
          importadas++;
        } catch (e) {
          errores++;
          mensajesError.add('Error: $e');
        }
      }
      
      return ImportResult(
        total: incidenciasData.length,
        importadas: importadas,
        errores: errores,
        mensajesError: mensajesError,
      );
    } catch (e) {
      throw Exception('Error al procesar archivo: $e');
    }
  }
}

class ImportResult {
  final int total;
  final int importadas;
  final int errores;
  final List<String> mensajesError;

  ImportResult({
    required this.total,
    required this.importadas,
    required this.errores,
    required this.mensajesError,
  });
}
