import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incidencia.dart';
import '../models/proveedor.dart';
import '../models/comunidad.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== GENERADOR DE NÚMEROS DE ORDEN ====================

  /// Genera el siguiente número de orden en formato M-OTYYYYMM-NNN
  /// Reinicia el contador cada año (enero = 001)
  static Future<String> generateOrderNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final yearKey = year.toString();
    
    final counterRef = _firestore.collection('_config').doc('order_counter');
    
    return _firestore.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);
      
      Map<String, dynamic> data = counterDoc.exists 
          ? counterDoc.data()! 
          : {};
      
      // Verificar si es un año nuevo y reiniciar
      final lastYear = data['lastYear'] as int?;
      if (lastYear != null && lastYear != year) {
        // Nuevo año - reiniciar contador
        data = {
          'lastYear': year,
          yearKey: 0,
        };
      }
      
      // Obtener el último número del año actual
      // Para diciembre 2025, empezar en 186 (siguiente será 187)
      int currentNumber = data[yearKey] ?? 186;
      int nextNumber = currentNumber + 1;
      
      // Actualizar contador
      data[yearKey] = nextNumber;
      data['lastYear'] = year;
      transaction.set(counterRef, data);
      
      // Generar número formateado: M-OT202512-185
      return 'M-OT$year$month-${nextNumber.toString().padLeft(3, '0')}';
    });
  }

  // ==================== INCIDENCIAS ====================

  /// Obtener todas las incidencias en tiempo real
  static Stream<List<Incidencia>> getIncidenciasStream() {
    return _firestore
        .collection('incidencias')
        .orderBy('fechaIncidencia', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Incidencia.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener una incidencia específica
  static Future<Incidencia?> getIncidencia(String id) async {
    final doc = await _firestore.collection('incidencias').doc(id).get();
    if (doc.exists) {
      return Incidencia.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar una nueva incidencia
  static Future<String> addIncidencia(Incidencia incidencia) async {
    final docRef = await _firestore
        .collection('incidencias')
        .add(incidencia.toFirestore());
    return docRef.id;
  }

  /// Actualizar una incidencia existente
  static Future<void> updateIncidencia(Incidencia incidencia) async {
    await _firestore
        .collection('incidencias')
        .doc(incidencia.id)
        .update(incidencia.toFirestore());
  }

  /// Eliminar una incidencia
  static Future<void> deleteIncidencia(String id) async {
    await _firestore.collection('incidencias').doc(id).delete();
  }

  // ==================== PROVEEDORES ====================

  /// Obtener todos los proveedores en tiempo real
  static Stream<List<Proveedor>> getProveedoresStream() {
    return _firestore
        .collection('proveedores')
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Proveedor.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener un proveedor específico
  static Future<Proveedor?> getProveedor(String id) async {
    final doc = await _firestore.collection('proveedores').doc(id).get();
    if (doc.exists) {
      return Proveedor.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar un nuevo proveedor
  static Future<String> addProveedor(Proveedor proveedor) async {
    final docRef = await _firestore
        .collection('proveedores')
        .add(proveedor.toFirestore());
    return docRef.id;
  }

  /// Actualizar un proveedor existente
  static Future<void> updateProveedor(Proveedor proveedor) async {
    await _firestore
        .collection('proveedores')
        .doc(proveedor.id)
        .update(proveedor.toFirestore());
  }

  /// Eliminar un proveedor
  static Future<void> deleteProveedor(String id) async {
    await _firestore.collection('proveedores').doc(id).delete();
  }

  // ==================== COMUNIDADES (compartidas con Claim Manager) ====================

  /// Obtener todas las comunidades en tiempo real
  static Stream<List<Comunidad>> getComunidadesStream() {
    return _firestore
        .collection('comunidades')
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comunidad.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener una comunidad específica
  static Future<Comunidad?> getComunidad(String id) async {
    final doc = await _firestore.collection('comunidades').doc(id).get();
    if (doc.exists) {
      return Comunidad.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar una nueva comunidad
  static Future<String> addComunidad(Comunidad comunidad) async {
    final docRef = await _firestore
        .collection('comunidades')
        .add(comunidad.toFirestore());
    return docRef.id;
  }

  /// Actualizar una comunidad existente
  static Future<void> updateComunidad(Comunidad comunidad) async {
    await _firestore
        .collection('comunidades')
        .doc(comunidad.id)
        .update(comunidad.toFirestore());
  }

  /// Eliminar una comunidad
  static Future<void> deleteComunidad(String id) async {
    await _firestore.collection('comunidades').doc(id).delete();
  }

  // ==================== UTILIDADES ====================

  /// Verificar conexión con Firestore
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtener estadísticas del dashboard
  static Future<Map<String, dynamic>> getEstadisticas() async {
    final incidencias = await getIncidenciasStream().first;
    
    final pendientes = incidencias.where((i) => i.estado == EstadoIncidencia.pendiente).length;
    final urgentes = incidencias.where((i) => i.prioridad == Prioridad.urgente).length;
    final enProceso = incidencias.where((i) => i.estado == EstadoIncidencia.enProceso).length;
    
    // Calcular coste total del mes
    final now = DateTime.now();
    final incidenciasMes = incidencias.where((i) => 
      i.fechaIncidencia.year == now.year && 
      i.fechaIncidencia.month == now.month
    );
    
    double costeTotalMes = 0;
    for (var inc in incidenciasMes) {
      if (inc.costeReal != null) {
        costeTotalMes += inc.costeReal!;
      }
    }
    
    return {
      'pendientes': pendientes,
      'urgentes': urgentes,
      'enProceso': enProceso,
      'costeTotalMes': costeTotalMes,
      'totalIncidencias': incidencias.length,
    };
  }
}
