import 'package:cloud_firestore/cloud_firestore.dart';

class Comunidad {
  String id;
  String nombre;
  String direccion;
  String ciudad;
  String codigoPostal;
  String? telefono;
  String? email;
  String? companiaAseguradora;
  String? numeroPoliza;
  DateTime? fechaVencimientoSeguro;

  Comunidad({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.codigoPostal,
    this.telefono,
    this.email,
    this.companiaAseguradora,
    this.numeroPoliza,
    this.fechaVencimientoSeguro,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'ciudad': ciudad,
      'codigoPostal': codigoPostal,
      'telefono': telefono,
      'email': email,
      'companiaAseguradora': companiaAseguradora,
      'numeroPoliza': numeroPoliza,
      'fechaVencimientoSeguro': fechaVencimientoSeguro?.toIso8601String(),
    };
  }

  factory Comunidad.fromJson(Map<String, dynamic> json) {
    return Comunidad(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      ciudad: json['ciudad'] as String,
      codigoPostal: json['codigoPostal'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      companiaAseguradora: json['companiaAseguradora'] as String?,
      numeroPoliza: json['numeroPoliza'] as String?,
      fechaVencimientoSeguro: json['fechaVencimientoSeguro'] != null
          ? DateTime.parse(json['fechaVencimientoSeguro'] as String)
          : null,
    );
  }

  // Métodos para Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'ciudad': ciudad,
      'codigoPostal': codigoPostal,
      'telefono': telefono,
      'email': email,
      'companiaAseguradora': companiaAseguradora,
      'numeroPoliza': numeroPoliza,
      'fechaVencimientoSeguro': fechaVencimientoSeguro != null
          ? Timestamp.fromDate(fechaVencimientoSeguro!)
          : null,
    };
  }

  factory Comunidad.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Comunidad(
      id: documentId,
      nombre: data['nombre'] as String? ?? 'Sin nombre',
      direccion: data['direccion'] as String? ?? '',
      ciudad: data['ciudad'] as String? ?? '',
      codigoPostal: data['codigoPostal'] as String? ?? '',
      telefono: data['telefono'] as String?,
      email: data['email'] as String?,
      companiaAseguradora: data['companiaAseguradora'] as String?,
      numeroPoliza: data['numeroPoliza'] as String?,
      fechaVencimientoSeguro: data['fechaVencimientoSeguro'] != null
          ? (data['fechaVencimientoSeguro'] as Timestamp).toDate()
          : null,
    );
  }
}
