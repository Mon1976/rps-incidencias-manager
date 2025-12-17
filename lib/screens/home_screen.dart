import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/incidencia.dart';
import '../services/firebase_service.dart';
import '../services/backup_service.dart';
import 'incidencia_detail_screen.dart';
import 'nueva_incidencia_screen.dart';
import 'proveedores_screen.dart';
import 'comunidades_screen.dart';
import 'listados_screen.dart';
// dart:html removido - no compatible con compilación APK

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isKanbanView = true; // Vista por defecto: Kanban (columnas por estado)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RPS Incidencias',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Gestión de Órdenes de Trabajo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Botón para cambiar vista
          IconButton(
            icon: Icon(_isKanbanView ? Icons.view_list : Icons.view_column),
            tooltip: _isKanbanView ? 'Vista Lista' : 'Vista Columnas',
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
            },
          ),
          // Botón de listados
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Listados y Filtros',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListadosScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Incidencia>>(
        stream: FirebaseService.getIncidenciasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final incidencias = snapshot.data ?? [];

          if (incidencias.isEmpty) {
            return _buildEmptyState();
          }

          return _isKanbanView
              ? _buildKanbanView(incidencias)
              : _buildListView(incidencias);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NuevaIncidenciaScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Incidencia'),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildKanbanView(List<Incidencia> incidencias) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstadoColumn(
            'PENDIENTE',
            EstadoIncidencia.pendiente,
            Colors.orange,
            incidencias,
          ),
          _buildEstadoColumn(
            'ASIGNADA',
            EstadoIncidencia.asignada,
            Colors.blue,
            incidencias,
          ),
          _buildEstadoColumn(
            'EN PROCESO',
            EstadoIncidencia.enProceso,
            Colors.purple,
            incidencias,
          ),
          _buildEstadoColumn(
            'EN ESPERA',
            EstadoIncidencia.enEspera,
            Colors.amber,
            incidencias,
          ),
          _buildEstadoColumn(
            'RESUELTA',
            EstadoIncidencia.resuelta,
            Colors.green,
            incidencias,
          ),
          _buildEstadoColumn(
            'CERRADA',
            EstadoIncidencia.cerrada,
            Colors.grey,
            incidencias,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoColumn(
    String titulo,
    EstadoIncidencia estado,
    Color color,
    List<Incidencia> todasIncidencias,
  ) {
    final incidenciasFiltradas = todasIncidencias
        .where((inc) => inc.estado == estado)
        .toList();

    return Container(
      width: 320,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la columna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${incidenciasFiltradas.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenedor de tarjetas
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 200,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: incidenciasFiltradas.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sin incidencias',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: incidenciasFiltradas.length,
                    itemBuilder: (context, index) {
                      return _buildKanbanCard(
                        incidenciasFiltradas[index],
                        color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(Incidencia incidencia, Color estadoColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidenciaDetailScreen(incidencia: incidencia),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: estadoColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número de orden
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incidencia.numeroOrden,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _getPrioridadIcon(incidencia.prioridad),
                ],
              ),
              const SizedBox(height: 8),
              // Tipo de incidencia
              Text(
                incidencia.getTipoText(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Descripción de la incidencia
              Text(
                incidencia.descripcionDetallada,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Comunidad
              Row(
                children: [
                  Icon(Icons.apartment, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incidencia.comunidadNombre,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Fecha
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(incidencia.fechaIncidencia),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Proveedor (si existe)
              if (incidencia.proveedorNombre != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incidencia.proveedorNombre!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Incidencia> incidencias) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: incidencias.length,
      itemBuilder: (context, index) {
        final incidencia = incidencias[index];
        return _buildListCard(incidencia);
      },
    );
  }

  Widget _buildListCard(Incidencia incidencia) {
    final estadoColor = _getEstadoColor(incidencia.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estadoColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidenciaDetailScreen(incidencia: incidencia),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incidencia.numeroOrden,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _getPrioridadIcon(incidencia.prioridad),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incidencia.getEstadoText(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incidencia.getTipoText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 6),
              // Descripción de la incidencia
              Text(
                incidencia.descripcionDetallada,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      incidencia.comunidadNombre,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(incidencia.fechaIncidencia),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (incidencia.proveedorNombre != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        incidencia.proveedorNombre!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay incidencias registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulsa el botón + para crear la primera',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPrioridadIcon(Prioridad prioridad) {
    switch (prioridad) {
      case Prioridad.urgente:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case Prioridad.alta:
        return const Icon(Icons.warning, color: Colors.orange, size: 20);
      case Prioridad.normal:
        return const Icon(Icons.info, color: Colors.green, size: 20);
      case Prioridad.baja:
        return const Icon(Icons.circle, color: Colors.grey, size: 20);
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'RPS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Incidencias Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Color(0xFF1976D2)),
            title: const Text('Órdenes de Trabajo'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Color(0xFF1976D2)),
            title: const Text('Listados y Filtros'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListadosScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.apartment, color: Color(0xFF1976D2)),
            title: const Text('Comunidades'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComunidadesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business, color: Color(0xFF1976D2)),
            title: const Text('Proveedores'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProveedoresScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup, color: Color(0xFF1976D2)),
            title: const Text('Exportar Backup'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await BackupService.exportarBackup();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Backup exportado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al exportar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Importar Backup deshabilitado (requiere dart:html no compatible con APK)
          // ListTile(
          //   leading: const Icon(Icons.upload_file, color: Color(0xFF1976D2)),
          //   title: const Text('Importar Backup'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     _importarBackup(context);
          //   },
          // ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'RPS Administración de Fincas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'C/ Juan XXIII, 13\n30850 Totana (Murcia)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función deshabilitada - dart:html no compatible con APK
  // void _importarBackup(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Importar backup solo disponible en versión web'),
  //       backgroundColor: Colors.orange,
  //     ),
  //   );
  // }
}
