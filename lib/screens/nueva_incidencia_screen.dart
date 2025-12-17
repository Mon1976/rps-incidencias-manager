import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incidencia.dart';
import '../models/comunidad.dart';
import '../models/proveedor.dart';
import '../services/firebase_service.dart';

class NuevaIncidenciaScreen extends StatefulWidget {
  const NuevaIncidenciaScreen({super.key});

  @override
  State<NuevaIncidenciaScreen> createState() => _NuevaIncidenciaScreenState();
}

class _NuevaIncidenciaScreenState extends State<NuevaIncidenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _presupuestoController = TextEditingController();
  final _personaContactoController = TextEditingController();
  final _telefonoContactoController = TextEditingController();
  final _reportadoPorController = TextEditingController();
  final _reportadoEmailController = TextEditingController();
  final _reportadoTelefonoController = TextEditingController();

  // Selecciones
  Comunidad? _selectedComunidad;
  Proveedor? _selectedProveedor;
  TipoIncidencia _selectedTipo = TipoIncidencia.electricidad;
  Prioridad _selectedPrioridad = Prioridad.normal;
  DateTime _selectedFecha = DateTime.now();
  DateTime? _selectedFechaEntrega;

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _presupuestoController.dispose();
    _personaContactoController.dispose();
    _telefonoContactoController.dispose();
    _reportadoPorController.dispose();
    _reportadoEmailController.dispose();
    _reportadoTelefonoController.dispose();
    super.dispose();
  }

  Future<void> _crearIncidencia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedComunidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una comunidad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generar número de orden automáticamente
      final numeroOrden = await FirebaseService.generateOrderNumber();

      // Crear incidencia
      final incidencia = Incidencia(
        id: '',
        numeroOrden: numeroOrden,
        fechaIncidencia: _selectedFecha,
        fechaEntrega: _selectedFechaEntrega,
        prioridad: _selectedPrioridad,
        estado: EstadoIncidencia.pendiente,
        tipo: _selectedTipo,
        comunidadNombre: _selectedComunidad!.nombre,
        comunidadDireccion: _selectedComunidad!.direccion,
        comunidadCiudad: _selectedComunidad!.ciudad,
        comunidadCodigoPostal: _selectedComunidad!.codigoPostal,
        personaContacto: _personaContactoController.text.isEmpty 
            ? null 
            : _personaContactoController.text,
        telefonoContacto: _telefonoContactoController.text.isEmpty 
            ? null 
            : _telefonoContactoController.text,
        descripcionDetallada: _descripcionController.text,
        ubicacionEspecifica: _ubicacionController.text.isEmpty 
            ? null 
            : _ubicacionController.text,
        proveedorNombre: _selectedProveedor?.nombre,
        proveedorTelefono: _selectedProveedor?.telefono,
        proveedorEmail: _selectedProveedor?.email,
        presupuestoLimite: _presupuestoController.text.isEmpty 
            ? 'A presupuestar' 
            : _presupuestoController.text,
        reportadoPor: _reportadoPorController.text.isEmpty 
            ? null 
            : _reportadoPorController.text,
        reportadoEmail: _reportadoEmailController.text.isEmpty 
            ? null 
            : _reportadoEmailController.text,
        reportadoTelefono: _reportadoTelefonoController.text.isEmpty 
            ? null 
            : _reportadoTelefonoController.text,
      );

      await FirebaseService.addIncidencia(incidencia);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incidencia $numeroOrden creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear incidencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Incidencia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información general
                    _buildSectionTitle('Información General'),
                    const SizedBox(height: 12),

                    // Fecha de incidencia
                    ListTile(
                      title: const Text('Fecha de Incidencia'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedFecha)),
                      leading: const Icon(Icons.calendar_today),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _selectedFecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (fecha != null) {
                          setState(() {
                            _selectedFecha = fecha;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Tipo de incidencia
                    DropdownButtonFormField<TipoIncidencia>(
                      initialValue: _selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Incidencia *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: TipoIncidencia.values.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(_getTipoText(tipo)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTipo = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Prioridad
                    DropdownButtonFormField<Prioridad>(
                      initialValue: _selectedPrioridad,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad *',
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: Prioridad.values.map((prioridad) {
                        return DropdownMenuItem(
                          value: prioridad,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: _getPrioridadColor(prioridad),
                              ),
                              const SizedBox(width: 8),
                              Text(_getPrioridadText(prioridad)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrioridad = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Datos de la comunidad
                    _buildSectionTitle('Datos de la Comunidad'),
                    const SizedBox(height: 12),

                    StreamBuilder<List<Comunidad>>(
                      stream: FirebaseService.getComunidadesStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final comunidades = snapshot.data!;

                        if (comunidades.isEmpty) {
                          return const Text(
                            'No hay comunidades disponibles. Créelas en Claim Manager.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        return DropdownButtonFormField<Comunidad>(
                          initialValue: _selectedComunidad,
                          decoration: const InputDecoration(
                            labelText: 'Comunidad *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: comunidades.map((comunidad) {
                            return DropdownMenuItem(
                              value: comunidad,
                              child: Text(comunidad.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedComunidad = value;
                              // Auto-completar datos de contacto si existen
                              if (value?.telefono != null) {
                                _telefonoContactoController.text = value!.telefono!;
                              }
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Debe seleccionar una comunidad' : null,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _personaContactoController,
                      decoration: const InputDecoration(
                        labelText: 'Persona de Contacto',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _telefonoContactoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de Contacto',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    // Descripción del trabajo
                    _buildSectionTitle('Descripción del Trabajo'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _ubicacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación Específica',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Ej: Portal A, Planta 3',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción Detallada *',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),

                    const SizedBox(height: 24),

                    // Datos del proveedor
                    _buildSectionTitle('Proveedor (Opcional)'),
                    const SizedBox(height: 12),

                    StreamBuilder<List<Proveedor>>(
                      stream: FirebaseService.getProveedoresStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        final proveedores = snapshot.data!;

                        return DropdownButtonFormField<Proveedor>(
                          initialValue: _selectedProveedor,
                          decoration: const InputDecoration(
                            labelText: 'Asignar Proveedor',
                            prefixIcon: Icon(Icons.engineering),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin asignar'),
                            ),
                            ...proveedores.map((proveedor) {
                              return DropdownMenuItem(
                                value: proveedor,
                                child: Text('${proveedor.nombre} - ${proveedor.especialidad}'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedProveedor = value;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Presupuesto
                    _buildSectionTitle('Presupuesto'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _presupuestoController,
                      decoration: const InputDecoration(
                        labelText: 'Límite de Gasto',
                        prefixIcon: Icon(Icons.euro),
                        hintText: 'Dejar vacío para "A presupuestar"',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reportado por
                    _buildSectionTitle('Reportado Por'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _reportadoPorController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _reportadoTelefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _reportadoEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 32),

                    // Botón crear
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _crearIncidencia,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Crear Incidencia',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1976D2),
      ),
    );
  }

  String _getTipoText(TipoIncidencia tipo) {
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

  String _getPrioridadText(Prioridad prioridad) {
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

  Color _getPrioridadColor(Prioridad prioridad) {
    switch (prioridad) {
      case Prioridad.baja:
        return Colors.grey;
      case Prioridad.normal:
        return Colors.green;
      case Prioridad.alta:
        return Colors.orange;
      case Prioridad.urgente:
        return Colors.red;
    }
  }
}
