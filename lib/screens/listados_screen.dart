import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/incidencia.dart';
import '../services/firebase_service.dart';
import 'incidencia_detail_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// dart:html removido - no compatible con APK

class ListadosScreen extends StatefulWidget {
  const ListadosScreen({super.key});

  @override
  State<ListadosScreen> createState() => _ListadosScreenState();
}

class _ListadosScreenState extends State<ListadosScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  EstadoIncidencia? _estadoFiltro;
  Prioridad? _prioridadFiltro;
  String? _comunidadFiltro;
  String? _proveedorFiltro;
  
  List<Incidencia> _incidenciasFiltradas = [];
  List<String> _comunidadesDisponibles = [];
  List<String> _proveedoresDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final incidencias = await FirebaseService.getIncidenciasStream().first;
    
    final comunidades = incidencias
        .map((i) => i.comunidadNombre)
        .toSet()
        .toList()
      ..sort();
    
    final proveedores = incidencias
        .where((i) => i.proveedorNombre != null)
        .map((i) => i.proveedorNombre!)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _incidenciasFiltradas = incidencias;
      _comunidadesDisponibles = comunidades;
      _proveedoresDisponibles = proveedores;
    });
  }

  void _aplicarFiltros(List<Incidencia> todasIncidencias) {
    var filtradas = todasIncidencias;

    // Filtro por fecha desde
    if (_fechaDesde != null) {
      filtradas = filtradas.where((inc) => 
        inc.fechaIncidencia.isAfter(_fechaDesde!) || 
        inc.fechaIncidencia.isAtSameMomentAs(_fechaDesde!)
      ).toList();
    }

    // Filtro por fecha hasta
    if (_fechaHasta != null) {
      final fechaHastaFin = DateTime(
        _fechaHasta!.year,
        _fechaHasta!.month,
        _fechaHasta!.day,
        23,
        59,
        59,
      );
      filtradas = filtradas.where((inc) => 
        inc.fechaIncidencia.isBefore(fechaHastaFin) || 
        inc.fechaIncidencia.isAtSameMomentAs(fechaHastaFin)
      ).toList();
    }

    // Filtro por estado
    if (_estadoFiltro != null) {
      filtradas = filtradas.where((inc) => inc.estado == _estadoFiltro).toList();
    }

    // Filtro por prioridad
    if (_prioridadFiltro != null) {
      filtradas = filtradas.where((inc) => inc.prioridad == _prioridadFiltro).toList();
    }

    // Filtro por comunidad
    if (_comunidadFiltro != null) {
      filtradas = filtradas.where((inc) => inc.comunidadNombre == _comunidadFiltro).toList();
    }

    // Filtro por proveedor
    if (_proveedorFiltro != null) {
      filtradas = filtradas.where((inc) => inc.proveedorNombre == _proveedorFiltro).toList();
    }

    // Ordenar por fecha descendente
    filtradas.sort((a, b) => b.fechaIncidencia.compareTo(a.fechaIncidencia));

    setState(() {
      _incidenciasFiltradas = filtradas;
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _estadoFiltro = null;
      _prioridadFiltro = null;
      _comunidadFiltro = null;
      _proveedorFiltro = null;
    });
    _cargarDatos();
  }

  Future<void> _exportarPDF() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportar PDF solo disponible en versión web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_incidenciasFiltradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay incidencias para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      // Agrupar incidencias en páginas de 15
      final pageSize = 15;
      for (var i = 0; i < _incidenciasFiltradas.length; i += pageSize) {
        final pageIncidencias = _incidenciasFiltradas.skip(i).take(pageSize).toList();
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildPDFHeader(),
                  pw.SizedBox(height: 20),
                  
                  // Información de filtros
                  _buildFiltrosInfo(),
                  pw.SizedBox(height: 20),
                  
                  // Tabla de incidencias
                  _buildIncidenciasTable(pageIncidencias),
                  
                  pw.Spacer(),
                  
                  // Footer
                  pw.Center(
                    child: pw.Text(
                      'Página ${(i ~/ pageSize) + 1} de ${(_incidenciasFiltradas.length / pageSize).ceil()} - Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Descargar PDF (deshabilitado para APK)
      // Descarga de PDF requiere dart:html (solo Web)
      throw UnsupportedError('PDF download requires dart:html (web only)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Listado PDF exportado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue700, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RPS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Listado de Incidencias',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.blue800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total: ${_incidenciasFiltradas.length} incidencias',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFiltrosInfo() {
    final filtrosActivos = <String>[];
    
    if (_fechaDesde != null) {
      filtrosActivos.add('Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}');
    }
    if (_fechaHasta != null) {
      filtrosActivos.add('Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}');
    }
    if (_estadoFiltro != null) {
      filtrosActivos.add('Estado: ${_getEstadoText(_estadoFiltro!)}');
    }
    if (_prioridadFiltro != null) {
      filtrosActivos.add('Prioridad: ${_getPrioridadText(_prioridadFiltro!)}');
    }
    if (_comunidadFiltro != null) {
      filtrosActivos.add('Comunidad: $_comunidadFiltro');
    }
    if (_proveedorFiltro != null) {
      filtrosActivos.add('Proveedor: $_proveedorFiltro');
    }

    if (filtrosActivos.isEmpty) {
      return pw.Text(
        'Filtros: Ninguno (mostrando todas las incidencias)',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Filtros aplicados:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            filtrosActivos.join(' • '),
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIncidenciasTable(List<Incidencia> incidencias) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableCell('Nº Orden', true),
            _buildTableCell('Tipo', true),
            _buildTableCell('Comunidad', true),
            _buildTableCell('Fecha', true),
            _buildTableCell('Estado', true),
            _buildTableCell('Prioridad', true),
          ],
        ),
        // Rows
        ...incidencias.map((inc) => pw.TableRow(
          children: [
            _buildTableCell(inc.numeroOrden, false),
            _buildTableCell(inc.getTipoText(), false),
            _buildTableCell(inc.comunidadNombre, false),
            _buildTableCell(DateFormat('dd/MM/yy').format(inc.fechaIncidencia), false),
            _buildTableCell(_getEstadoText(inc.estado), false),
            _buildTableCell(_getPrioridadText(inc.prioridad), false),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listados y Filtros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: _exportarPDF,
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final todasIncidencias = snapshot.data ?? [];

          return Column(
            children: [
              // Panel de filtros
              _buildFiltrosPanel(todasIncidencias),
              
              // Resultados
              Expanded(
                child: _incidenciasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : _buildResultados(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltrosPanel(List<Incidencia> todasIncidencias) {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fila 1: Fechas
          Row(
            children: [
              Expanded(
                child: _buildFechaSelector(
                  'Desde',
                  _fechaDesde,
                  (fecha) {
                    setState(() {
                      _fechaDesde = fecha;
                    });
                    _aplicarFiltros(todasIncidencias);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaSelector(
                  'Hasta',
                  _fechaHasta,
                  (fecha) {
                    setState(() {
                      _fechaHasta = fecha;
                    });
                    _aplicarFiltros(todasIncidencias);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fila 2: Estado y Prioridad
          Row(
            children: [
              Expanded(
                child: _buildEstadoDropdown(todasIncidencias),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPrioridadDropdown(todasIncidencias),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fila 3: Comunidad y Proveedor
          Row(
            children: [
              Expanded(
                child: _buildComunidadDropdown(todasIncidencias),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProveedorDropdown(todasIncidencias),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _aplicarFiltros(todasIncidencias),
                icon: const Icon(Icons.search),
                label: const Text('Aplicar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector(String label, DateTime? fecha, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(selectedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: fecha != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Seleccionar',
          style: TextStyle(
            fontSize: 14,
            color: fecha != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown(List<Incidencia> todasIncidencias) {
    return DropdownButtonFormField<EstadoIncidencia?>(
      initialValue: _estadoFiltro,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        ...EstadoIncidencia.values.map((estado) => DropdownMenuItem(
          value: estado,
          child: Text(_getEstadoText(estado)),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _estadoFiltro = value;
        });
        _aplicarFiltros(todasIncidencias);
      },
    );
  }

  Widget _buildPrioridadDropdown(List<Incidencia> todasIncidencias) {
    return DropdownButtonFormField<Prioridad?>(
      initialValue: _prioridadFiltro,
      decoration: const InputDecoration(
        labelText: 'Prioridad',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        ...Prioridad.values.map((prioridad) => DropdownMenuItem(
          value: prioridad,
          child: Text(_getPrioridadText(prioridad)),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _prioridadFiltro = value;
        });
        _aplicarFiltros(todasIncidencias);
      },
    );
  }

  Widget _buildComunidadDropdown(List<Incidencia> todasIncidencias) {
    return DropdownButtonFormField<String?>(
      initialValue: _comunidadFiltro,
      decoration: const InputDecoration(
        labelText: 'Comunidad',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        ..._comunidadesDisponibles.map((comunidad) => DropdownMenuItem(
          value: comunidad,
          child: Text(
            comunidad,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _comunidadFiltro = value;
        });
        _aplicarFiltros(todasIncidencias);
      },
    );
  }

  Widget _buildProveedorDropdown(List<Incidencia> todasIncidencias) {
    return DropdownButtonFormField<String?>(
      initialValue: _proveedorFiltro,
      decoration: const InputDecoration(
        labelText: 'Proveedor',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        ..._proveedoresDisponibles.map((proveedor) => DropdownMenuItem(
          value: proveedor,
          child: Text(
            proveedor,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _proveedorFiltro = value;
        });
        _aplicarFiltros(todasIncidencias);
      },
    );
  }

  Widget _buildResultados() {
    return Column(
      children: [
        // Header con contador
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[200],
          child: Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                'Resultados: ${_incidenciasFiltradas.length} incidencias',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de resultados
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _incidenciasFiltradas.length,
            itemBuilder: (context, index) {
              final incidencia = _incidenciasFiltradas[index];
              return _buildIncidenciaCard(incidencia);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncidenciaCard(Incidencia incidencia) {
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
                      _getEstadoText(incidencia.estado),
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
              const SizedBox(height: 8),
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
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron incidencias',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba ajustando los filtros',
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
}
