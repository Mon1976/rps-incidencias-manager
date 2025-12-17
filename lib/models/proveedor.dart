import 'package:cloud_firestore/cloud_firestore.dart';

class Proveedor {
  String id;
  String nombre;
  String especialidad; // Fontanero, Electricista, etc.
  String telefono;
  String email;
  String? direccion;
  String? cuentaBancaria;
  String? horarioContacto;
  double valoracion; // 0-5 estrellas
  String? notas;
  int trabajosRealizados;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.especialidad,
    this.telefono = '',
    this.email = '',
    this.direccion,
    this.cuentaBancaria,
    this.horarioContacto,
    this.valoracion = 0.0,
    this.notas,
    this.trabajosRealizados = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'especialidad': especialidad,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'cuentaBancaria': cuentaBancaria,
      'horarioContacto': horarioContacto,
      'valoracion': valoracion,
      'notas': notas,
      'trabajosRealizados': trabajosRealizados,
    };
  }

  factory Proveedor.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Proveedor(
      id: documentId,
      nombre: data['nombre'] as String,
      especialidad: data['especialidad'] as String,
      telefono: data['telefono'] as String? ?? '',
      email: data['email'] as String? ?? '',
      direccion: data['direccion'] as String?,
      cuentaBancaria: data['cuentaBancaria'] as String?,
      horarioContacto: data['horarioContacto'] as String?,
      valoracion: (data['valoracion'] as num?)?.toDouble() ?? 0.0,
      notas: data['notas'] as String?,
      trabajosRealizados: data['trabajosRealizados'] as int? ?? 0,
    );
  }
}
