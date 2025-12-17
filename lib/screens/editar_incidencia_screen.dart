import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incidencia.dart';
import '../models/comunidad.dart';
import '../models/proveedor.dart';
import '../services/firebase_service.dart';

class EditarIncidenciaScreen extends StatefulWidget {
  final Incidencia incidencia;
  
  const EditarIncidenciaScreen({super.key, required this.incidencia});

  @override
  State<EditarIncidenciaScreen> createState() => _EditarIncidenciaScreenState();
}

class _EditarIncidenciaScreenState extends State<EditarIncidenciaScreen> {
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
  late TipoIncidencia _selectedTipo;
  late Prioridad _selectedPrioridad;
  late DateTime _selectedFecha;
  late EstadoIncidencia _selectedEstado;
  DateTime? _selectedFechaEntrega;

  @override
  void initState() {
    super.initState();
    // Inicializar con datos de la incidencia
    _descripcionController.text = widget.incidencia.descripcionDetallada;
    _ubicacionController.text = widget.incidencia.ubicacionEspecifica ?? '';
    _presupuestoController.text = widget.incidencia.presupuestoLimite == 'A presupuestar' ? '' : (widget.incidencia.presupuestoLimite ?? '');
    _personaContactoController.text = widget.incidencia.personaContacto ?? '';
    _telefonoContactoController.text = widget.incidencia.telefonoContacto ?? '';
    _reportadoPorController.text = widget.incidencia.reportadoPor ?? '';
    _reportadoEmailController.text = widget.incidencia.reportadoEmail ?? '';
    _reportadoTelefonoController.text = widget.incidencia.reportadoTelefono ?? '';
    
    _selectedTipo = widget.incidencia.tipo;
    _selectedPrioridad = widget.incidencia.prioridad;
    _selectedFecha = widget.incidencia.fechaIncidencia;
    _selectedEstado = widget.incidencia.estado;
    _selectedFechaEntrega = widget.incidencia.fechaEntrega;
  }

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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // La comunidad no se puede cambiar en edición

    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar incidencia existente
      final incidenciaActualizada = Incidencia(
        id: widget.incidencia.id,
        numeroOrden: widget.incidencia.numeroOrden,
        fechaIncidencia: _selectedFecha,
        fechaEntrega: _selectedFechaEntrega,
        prioridad: _selectedPrioridad,
        estado: _selectedEstado,
        tipo: _selectedTipo,
        comunidadNombre: widget.incidencia.comunidadNombre,
        comunidadDireccion: widget.incidencia.comunidadDireccion,
        comunidadCiudad: widget.incidencia.comunidadCiudad,
        comunidadCodigoPostal: widget.incidencia.comunidadCodigoPostal,
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
        fotosUrls: widget.incidencia.fotosUrls,
        notas: widget.incidencia.notas, // Preservar notas manuales
        notasHistorial: widget.incidencia.notasHistorial,
        costeEstimado: widget.incidencia.costeEstimado,
        costeReal: widget.incidencia.costeReal,
        numeroFactura: widget.incidencia.numeroFactura,
        fechaFactura: widget.incidencia.fechaFactura,
        fechaAsignacion: widget.incidencia.fechaAsignacion,
      );

      // Añadir nota al historial
      final nota = '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} - Incidencia editada';
      incidenciaActualizada.notasHistorial.add(nota);
      
      await FirebaseService.updateIncidencia(incidenciaActualizada);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incidencia actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar incidencia: $e'),
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
        title: Text('Editar ${widget.incidencia.numeroOrden}'),
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

                    const SizedBox(height: 12),

                    // Estado
                    DropdownButtonFormField<EstadoIncidencia>(
                      initialValue: _selectedEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado *',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: EstadoIncidencia.values.map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: _getEstadoColor(estado),
                              ),
                              const SizedBox(width: 8),
                              Text(_getEstadoText(estado)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEstado = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Datos de la comunidad
                    _buildSectionTitle('Datos de la Comunidad'),
                    const SizedBox(height: 12),

                    // Comunidad (solo lectura en edición)
                    TextFormField(
                      initialValue: widget.incidencia.comunidadNombre,
                      decoration: const InputDecoration(
                        labelText: 'Comunidad',
                        prefixIcon: Icon(Icons.business),
                      ),
                      enabled: false,
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

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _guardarCambios,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Guardar Cambios',
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

  String _getEstadoText(EstadoIncidencia estado) {
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

  Color _getEstadoColor(EstadoIncidencia estado) {
    switch (estado) {
      case EstadoIncidencia.pendiente:
        return Colors.orange;
      case EstadoIncidencia.asignada:
        return Colors.blue;
      case EstadoIncidencia.enProceso:
        return Colors.purple;
      case EstadoIncidencia.enEspera:
        return Colors.amber;
      case EstadoIncidencia.resuelta:
        return Colors.green;
      case EstadoIncidencia.cerrada:
        return Colors.grey;
    }
  }
}
