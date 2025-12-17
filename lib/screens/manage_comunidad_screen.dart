import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/comunidad.dart';
import '../services/firebase_service.dart';

class ManageComunidadScreen extends StatefulWidget {
  final Comunidad? comunidad;

  const ManageComunidadScreen({super.key, this.comunidad});

  @override
  State<ManageComunidadScreen> createState() => _ManageComunidadScreenState();
}

class _ManageComunidadScreenState extends State<ManageComunidadScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _codigoPostalController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _companiaAseguradoraController;
  late TextEditingController _numeroPolizaController;

  final _uuid = const Uuid();
  DateTime? _fechaVencimientoSeguro;

  bool get _isEditing => widget.comunidad != null;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.comunidad?.nombre ?? '');
    _direccionController =
        TextEditingController(text: widget.comunidad?.direccion ?? '');
    _ciudadController =
        TextEditingController(text: widget.comunidad?.ciudad ?? '');
    _codigoPostalController =
        TextEditingController(text: widget.comunidad?.codigoPostal ?? '');
    _telefonoController =
        TextEditingController(text: widget.comunidad?.telefono ?? '');
    _emailController =
        TextEditingController(text: widget.comunidad?.email ?? '');
    _companiaAseguradoraController =
        TextEditingController(text: widget.comunidad?.companiaAseguradora ?? '');
    _numeroPolizaController =
        TextEditingController(text: widget.comunidad?.numeroPoliza ?? '');
    _fechaVencimientoSeguro = widget.comunidad?.fechaVencimientoSeguro;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _companiaAseguradoraController.dispose();
    _numeroPolizaController.dispose();
    super.dispose();
  }

  Future<void> _saveComunidad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (_isEditing) {
        // Actualizar comunidad existente
        final updatedComunidad = Comunidad(
          id: widget.comunidad!.id,
          nombre: _nombreController.text,
          direccion: _direccionController.text,
          ciudad: _ciudadController.text,
          codigoPostal: _codigoPostalController.text,
          telefono: _telefonoController.text.isEmpty
              ? null
              : _telefonoController.text,
          email:
              _emailController.text.isEmpty ? null : _emailController.text,
          companiaAseguradora: _companiaAseguradoraController.text.isEmpty
              ? null
              : _companiaAseguradoraController.text,
          numeroPoliza: _numeroPolizaController.text.isEmpty
              ? null
              : _numeroPolizaController.text,
          fechaVencimientoSeguro: _fechaVencimientoSeguro,
        );

        await FirebaseService.updateComunidad(updatedComunidad);
      } else {
        // Crear nueva comunidad
        final comunidad = Comunidad(
          id: _uuid.v4(),
          nombre: _nombreController.text,
          direccion: _direccionController.text,
          ciudad: _ciudadController.text,
          codigoPostal: _codigoPostalController.text,
          telefono: _telefonoController.text.isEmpty
              ? null
              : _telefonoController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          companiaAseguradora: _companiaAseguradoraController.text.isEmpty
              ? null
              : _companiaAseguradoraController.text,
          numeroPoliza: _numeroPolizaController.text.isEmpty
              ? null
              : _numeroPolizaController.text,
          fechaVencimientoSeguro: _fechaVencimientoSeguro,
        );

        await FirebaseService.addComunidad(comunidad);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Comunidad actualizada correctamente'
                : 'Comunidad creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComunidad() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Comunidad'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar esta comunidad?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseService.deleteComunidad(widget.comunidad!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comunidad eliminada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Comunidad' : 'Nueva Comunidad',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteComunidad,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              const Text(
                'Información Básica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Comunidad *',
                  hintText: 'Ej: Residencial Los Pinos',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce el nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección *',
                  hintText: 'Ej: Calle Mayor, 45',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce la dirección';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Ciudad y Código Postal
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ciudadController,
                      decoration: InputDecoration(
                        labelText: 'Ciudad *',
                        hintText: 'Totana',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoPostalController,
                      decoration: InputDecoration(
                        labelText: 'C.P. *',
                        hintText: '30850',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Datos de contacto
              const Text(
                'Datos de Contacto (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej: 968 123 456',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'contacto@comunidad.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              // Información del seguro
              const Text(
                'Información del Seguro (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Compañía aseguradora
              TextFormField(
                controller: _companiaAseguradoraController,
                decoration: InputDecoration(
                  labelText: 'Compañía Aseguradora',
                  hintText: 'Ej: MAPFRE, AXA, etc.',
                  prefixIcon: const Icon(Icons.shield),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Número de póliza
              TextFormField(
                controller: _numeroPolizaController,
                decoration: InputDecoration(
                  labelText: 'Número de Póliza',
                  hintText: 'Ej: POL-2024-001',
                  prefixIcon: const Icon(Icons.assignment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fecha de vencimiento del seguro
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaVencimientoSeguro ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('es', 'ES'),
                    helpText: 'Selecciona fecha de vencimiento',
                    cancelText: 'Cancelar',
                    confirmText: 'Aceptar',
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaVencimientoSeguro = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Vencimiento del Seguro',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: _fechaVencimientoSeguro != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _fechaVencimientoSeguro = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _fechaVencimientoSeguro != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaVencimientoSeguro!)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _fechaVencimientoSeguro != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveComunidad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Guardar Cambios' : 'Crear Comunidad',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botón cancelar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
