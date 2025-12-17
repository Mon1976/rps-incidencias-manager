import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/incidencia.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import 'editar_incidencia_screen.dart';

class IncidenciaDetailScreen extends StatefulWidget {
  final Incidencia incidencia;

  const IncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  State<IncidenciaDetailScreen> createState() => _IncidenciaDetailScreenState();
}

class _IncidenciaDetailScreenState extends State<IncidenciaDetailScreen> {
  late Incidencia _incidencia;

  @override
  void initState() {
    super.initState();
    _incidencia = widget.incidencia;
  }

  Future<void> _generarPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando orden de trabajo PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      await PDFService.generateOrdenTrabajo(_incidencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orden de trabajo descargada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enviarWhatsApp() async {
    if (_incidencia.proveedorTelefono == null || _incidencia.proveedorTelefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El proveedor no tiene teléfono registrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Limpiar teléfono (quitar espacios, guiones, paréntesis)
      String telefono = _incidencia.proveedorTelefono!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Si no empieza con +, agregar código de país (España +34)
      if (!telefono.startsWith('+')) {
        telefono = '+34$telefono';
      }

      // Obtener prioridad en texto español
      String urgenciaTexto = 'Media';
      switch (_incidencia.prioridad) {
        case Prioridad.baja:
          urgenciaTexto = 'Baja';
          break;
        case Prioridad.normal:
          urgenciaTexto = 'Media';
          break;
        case Prioridad.alta:
          urgenciaTexto = 'Alta';
          break;
        case Prioridad.urgente:
          urgenciaTexto = 'Urgente';
          break;
      }

      // Crear mensaje de WhatsApp en el formato solicitado
      final mensaje = '''
📋 Número de incidencia: ${_incidencia.numeroOrden}
${_incidencia.reportadoPor != null ? '👤 Comunicante: ${_incidencia.reportadoPor}' : ''}
${_incidencia.reportadoTelefono != null ? '📞 Teléfono: ${_incidencia.reportadoTelefono}' : ''}
⚙️ Tipo de incidencia: ${_incidencia.getTipoText()}
📝 Descripción: ${_incidencia.descripcionDetallada}
📍 Ubicación: ${_incidencia.comunidadNombre}, ${_incidencia.comunidadDireccion} - ${_incidencia.comunidadCiudad}
⚡ Urgencia: $urgenciaTexto

(Fecha de notificación: ${DateFormat('dd/MM/yyyy').format(_incidencia.fechaIncidencia)})

🔧 Responsable asignado: ${_incidencia.proveedorNombre ?? 'Por asignar'}
📊 Estado: ${_incidencia.getEstadoText()}

---
RPS Administración de Fincas
C/ Juan XXIII, 13
30850 Totana (Murcia)
      ''';

      final url = Uri.parse('https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarEstado(EstadoIncidencia nuevoEstado) async {
    try {
      _incidencia.estado = nuevoEstado;
      
      // Agregar nota al historial
      final nota = '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} - Estado cambiado a: ${_incidencia.getEstadoText()}';
      _incidencia.notasHistorial.add(nota);
      
      await FirebaseService.updateIncidencia(_incidencia);
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: ${_incidencia.getEstadoText()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarIncidencia() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Incidencia'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la incidencia ${_incidencia.numeroOrden}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      try {
        await FirebaseService.deleteIncidencia(_incidencia.id);

        if (mounted) {
          Navigator.pop(context); // Volver a la lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incidencia eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar incidencia: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_incidencia.numeroOrden),
        actions: [
          // Botón editar
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar incidencia',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarIncidenciaScreen(incidencia: _incidencia),
                ),
              );
              
              // Recargar datos si se guardaron cambios
              if (result == true && mounted) {
                // Obtener incidencia actualizada
                final incidenciaActualizada = await FirebaseService.getIncidencia(_incidencia.id);
                if (incidenciaActualizada != null) {
                  setState(() {
                    _incidencia = incidenciaActualizada;
                  });
                }
              }
            },
          ),
          // Botón WhatsApp
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Enviar WhatsApp',
            onPressed: _incidencia.proveedorNombre != null ? _enviarWhatsApp : null,
          ),
          // Botón PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
            onPressed: _generarPDF,
          ),
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value == 'eliminar') {
                _eliminarIncidencia();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'estado',
                enabled: false,
                child: Text(
                  'CAMBIAR ESTADO:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'pendiente',
                child: const Text('🟠 Pendiente'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.pendiente),
                ),
              ),
              PopupMenuItem(
                value: 'asignada',
                child: const Text('🔵 Asignada'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.asignada),
                ),
              ),
              PopupMenuItem(
                value: 'enProceso',
                child: const Text('🟣 En Proceso'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.enProceso),
                ),
              ),
              PopupMenuItem(
                value: 'enEspera',
                child: const Text('🟡 En Espera'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.enEspera),
                ),
              ),
              PopupMenuItem(
                value: 'resuelta',
                child: const Text('🟢 Resuelta'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.resuelta),
                ),
              ),
              PopupMenuItem(
                value: 'cerrada',
                child: const Text('⚫ Cerrada'),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _cambiarEstado(EstadoIncidencia.cerrada),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar incidencia',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado y prioridad
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPrioridadColor(_incidencia.prioridad),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _incidencia.getPrioridadText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(_incidencia.estado).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getEstadoColor(_incidencia.estado),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _incidencia.getEstadoText(),
                    style: TextStyle(
                      color: _getEstadoColor(_incidencia.estado),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Datos generales
            _buildSection(
              'Información General',
              [
                _buildInfoRow(Icons.calendar_today, 'Fecha de Incidencia',
                    DateFormat('dd/MM/yyyy').format(_incidencia.fechaIncidencia)),
                _buildInfoRow(Icons.category, 'Tipo', _incidencia.getTipoText()),
                if (_incidencia.ubicacionEspecifica != null)
                  _buildInfoRow(Icons.location_on, 'Ubicación', _incidencia.ubicacionEspecifica!),
              ],
            ),

            // Descripción
            _buildSection(
              'Descripción del Trabajo',
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _incidencia.descripcionDetallada,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),

            // Datos de la comunidad
            _buildSection(
              'Comunidad',
              [
                _buildInfoRow(Icons.business, 'Nombre', _incidencia.comunidadNombre),
                _buildInfoRow(Icons.location_city, 'Dirección', _incidencia.comunidadDireccion),
                _buildInfoRow(Icons.place, 'Ciudad',
                    '${_incidencia.comunidadCiudad} - ${_incidencia.comunidadCodigoPostal}'),
                if (_incidencia.personaContacto != null)
                  _buildInfoRow(Icons.person, 'Contacto', _incidencia.personaContacto!),
                if (_incidencia.telefonoContacto != null)
                  _buildInfoRow(Icons.phone, 'Teléfono', _incidencia.telefonoContacto!),
              ],
            ),

            // Proveedor
            if (_incidencia.proveedorNombre != null)
              _buildSection(
                'Proveedor Asignado',
                [
                  _buildInfoRow(Icons.engineering, 'Nombre', _incidencia.proveedorNombre!),
                  if (_incidencia.proveedorTelefono != null)
                    _buildInfoRow(Icons.phone, 'Teléfono', _incidencia.proveedorTelefono!),
                  if (_incidencia.proveedorEmail != null)
                    _buildInfoRow(Icons.email, 'Email', _incidencia.proveedorEmail!),
                ],
              ),

            // Presupuesto
            if (_incidencia.presupuestoLimite != null)
              _buildSection(
                'Presupuesto',
                [
                  _buildInfoRow(Icons.euro, 'Límite', _incidencia.presupuestoLimite!),
                ],
              ),

            // Notas / Anotaciones
            _buildNotasSection(),

            // Historial (solo cambios de estado)
            _buildHistorialSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildNotasSection() {
    final TextEditingController notaController = TextEditingController();
    
    // Usar solo el campo 'notas' (anotaciones manuales)
    final notasUsuario = _incidencia.notas;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas y Anotaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        
        // Campo para añadir nueva nota
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Añadir nueva anotación:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notaController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Proveedor confirma visita para el jueves...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (notaController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escribe una nota antes de guardar'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      final nuevaNota = '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} - ${notaController.text.trim()}';
                      _incidencia.notas.add(nuevaNota);
                      
                      await FirebaseService.updateIncidencia(_incidencia);
                      
                      notaController.clear();
                      setState(() {});
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Nota añadida correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al añadir nota: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Nota'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Mostrar solo notas de usuario
        if (notasUsuario.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...notasUsuario.map((nota) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nota,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No hay notas registradas',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHistorialSection() {
    // Usar solo el campo 'notasHistorial' (cambios de estado automáticos)
    final historialCambios = _incidencia.notasHistorial;
    
    if (historialCambios.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Cambios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...historialCambios.map((cambio) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cambio,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
