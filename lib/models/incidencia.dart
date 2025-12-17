import 'package:cloud_firestore/cloud_firestore.dart';

enum Prioridad {
  baja,
  normal,
  alta,
  urgente,
}

enum EstadoIncidencia {
  pendiente,
  asignada,
  enProceso,
  enEspera,
  resuelta,
  cerrada,
}

enum TipoIncidencia {
  mantenimientoPreventivo,
  averiaUrgente,
  reparacionProgramada,
  limpieza,
  jardineria,
  ascensor,
  fontaneria,
  electricidad,
  cerrajeria,
  otros,
}

class Incidencia {
  String id;
  String numeroOrden; // M-OT202512-185
  DateTime fechaIncidencia;
  DateTime? fechaEntrega;
  Prioridad prioridad;
  EstadoIncidencia estado;
  TipoIncidencia tipo;
  
  // Datos del cliente (comunidad)
  String comunidadNombre;
  String comunidadDireccion;
  String comunidadCiudad;
  String comunidadCodigoPostal;
  String? personaContacto;
  String? telefonoContacto;
  
  // Descripción del trabajo
  String descripcionDetallada;
  String? ubicacionEspecifica; // Ej: "Portal A, Planta 3"
  
  // Proveedor
  String? proveedorNombre;
  String? proveedorTelefono;
  String? proveedorEmail;
  DateTime? fechaAsignacion;
  
  // Presupuesto y costes
  String? presupuestoLimite; // "A presupuestar" o cantidad
  double? costeEstimado;
  double? costeReal;
  String? numeroFactura;
  DateTime? fechaFactura;
  
  // Documentación
  List<String> fotosUrls;
  List<String> notas; // Anotaciones manuales del usuario
  List<String> notasHistorial; // Historial automático de cambios de estado
  
  // Reportado por
  String? reportadoPor;
  String? reportadoEmail;
  String? reportadoTelefono;
  
  // Autorización
  String autorizadoPor;
  
  Incidencia({
    required this.id,
    required this.numeroOrden,
    required this.fechaIncidencia,
    this.fechaEntrega,
    required this.prioridad,
    required this.estado,
    required this.tipo,
    required this.comunidadNombre,
    required this.comunidadDireccion,
    required this.comunidadCiudad,
    required this.comunidadCodigoPostal,
    this.personaContacto,
    this.telefonoContacto,
    required this.descripcionDetallada,
    this.ubicacionEspecifica,
    this.proveedorNombre,
    this.proveedorTelefono,
    this.proveedorEmail,
    this.fechaAsignacion,
    this.presupuestoLimite,
    this.costeEstimado,
    this.costeReal,
    this.numeroFactura,
    this.fechaFactura,
    List<String>? fotosUrls,
    List<String>? notas,
    List<String>? notasHistorial,
    this.reportadoPor,
    this.reportadoEmail,
    this.reportadoTelefono,
    this.autorizadoPor = 'RPS Administración de Fincas',
  })  : fotosUrls = fotosUrls ?? [],
        notas = notas ?? [],
        notasHistorial = notasHistorial ?? [];

  // Métodos helper para obtener texto
  String getPrioridadText() {
    switch (prioridad) {
      case Prioridad.baja:
        return 'Baja';
      case Prioridad.normal:
        return 'Normal';
      case Prioridad.alta:
        return 'Alta';
      case Prioridad.urgente:
        return 'Urgente';
    }
  }

  String getEstadoText() {
    switch (estado) {
      case EstadoIncidencia.pendiente:
        return 'Pendiente';
      case EstadoIncidencia.asignada:
        return 'Asignada';
      case EstadoIncidencia.enProceso:
        return 'En Proceso';
      case EstadoIncidencia.enEspera:
        return 'En Espera';
      case EstadoIncidencia.resuelta:
        return 'Resuelta';
      case EstadoIncidencia.cerrada:
        return 'Cerrada';
    }
  }

  String getTipoText() {
    switch (tipo) {
      case TipoIncidencia.mantenimientoPreventivo:
        return 'Mantenimiento Preventivo';
      case TipoIncidencia.averiaUrgente:
        return 'Avería Urgente';
      case TipoIncidencia.reparacionProgramada:
        return 'Reparación Programada';
      case TipoIncidencia.limpieza:
        return 'Limpieza';
      case TipoIncidencia.jardineria:
        return 'Jardinería';
      case TipoIncidencia.ascensor:
        return 'Ascensor';
      case TipoIncidencia.fontaneria:
        return 'Fontanería';
      case TipoIncidencia.electricidad:
        return 'Electricidad';
      case TipoIncidencia.cerrajeria:
        return 'Cerrajería';
      case TipoIncidencia.otros:
        return 'Otros';
    }
  }

  // Métodos para Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'numeroOrden': numeroOrden,
      'fechaIncidencia': Timestamp.fromDate(fechaIncidencia),
      'fechaEntrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega!) : null,
      'prioridad': prioridad.name,
      'estado': estado.name,
      'tipo': tipo.name,
      'comunidadNombre': comunidadNombre,
      'comunidadDireccion': comunidadDireccion,
      'comunidadCiudad': comunidadCiudad,
      'comunidadCodigoPostal': comunidadCodigoPostal,
      'personaContacto': personaContacto,
      'telefonoContacto': telefonoContacto,
      'descripcionDetallada': descripcionDetallada,
      'ubicacionEspecifica': ubicacionEspecifica,
      'proveedorNombre': proveedorNombre,
      'proveedorTelefono': proveedorTelefono,
      'proveedorEmail': proveedorEmail,
      'fechaAsignacion': fechaAsignacion != null ? Timestamp.fromDate(fechaAsignacion!) : null,
      'presupuestoLimite': presupuestoLimite,
      'costeEstimado': costeEstimado,
      'costeReal': costeReal,
      'numeroFactura': numeroFactura,
      'fechaFactura': fechaFactura != null ? Timestamp.fromDate(fechaFactura!) : null,
      'fotosUrls': fotosUrls,
      'notas': notas,
      'notasHistorial': notasHistorial,
      'reportadoPor': reportadoPor,
      'reportadoEmail': reportadoEmail,
      'reportadoTelefono': reportadoTelefono,
      'autorizadoPor': autorizadoPor,
    };
  }

  factory Incidencia.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Incidencia(
      id: documentId,
      numeroOrden: data['numeroOrden'] as String,
      fechaIncidencia: (data['fechaIncidencia'] as Timestamp).toDate(),
      fechaEntrega: data['fechaEntrega'] != null
          ? (data['fechaEntrega'] as Timestamp).toDate()
          : null,
      prioridad: Prioridad.values.firstWhere(
        (e) => e.name == data['prioridad'],
        orElse: () => Prioridad.normal,
      ),
      estado: EstadoIncidencia.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoIncidencia.pendiente,
      ),
      tipo: TipoIncidencia.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => TipoIncidencia.otros,
      ),
      comunidadNombre: data['comunidadNombre'] as String,
      comunidadDireccion: data['comunidadDireccion'] as String,
      comunidadCiudad: data['comunidadCiudad'] as String,
      comunidadCodigoPostal: data['comunidadCodigoPostal'] as String,
      personaContacto: data['personaContacto'] as String?,
      telefonoContacto: data['telefonoContacto'] as String?,
      descripcionDetallada: data['descripcionDetallada'] as String,
      ubicacionEspecifica: data['ubicacionEspecifica'] as String?,
      proveedorNombre: data['proveedorNombre'] as String?,
      proveedorTelefono: data['proveedorTelefono'] as String?,
      proveedorEmail: data['proveedorEmail'] as String?,
      fechaAsignacion: data['fechaAsignacion'] != null
          ? (data['fechaAsignacion'] as Timestamp).toDate()
          : null,
      presupuestoLimite: data['presupuestoLimite'] as String?,
      costeEstimado: data['costeEstimado'] as double?,
      costeReal: data['costeReal'] as double?,
      numeroFactura: data['numeroFactura'] as String?,
      fechaFactura: data['fechaFactura'] != null
          ? (data['fechaFactura'] as Timestamp).toDate()
          : null,
      fotosUrls: (data['fotosUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      notas: (data['notas'] as List<dynamic>?)?.cast<String>() ?? [],
      notasHistorial: (data['notasHistorial'] as List<dynamic>?)?.cast<String>() ?? [],
      reportadoPor: data['reportadoPor'] as String?,
      reportadoEmail: data['reportadoEmail'] as String?,
      reportadoTelefono: data['reportadoTelefono'] as String?,
      autorizadoPor: data['autorizadoPor'] as String? ?? 'RPS Administración de Fincas',
    );
  }
}
