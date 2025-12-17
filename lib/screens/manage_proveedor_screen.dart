import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/proveedor.dart';
import '../services/firebase_service.dart';

class ManageProveedorScreen extends StatefulWidget {
  final Proveedor? proveedor;

  const ManageProveedorScreen({super.key, this.proveedor});

  @override
  State<ManageProveedorScreen> createState() => _ManageProveedorScreenState();
}

class _ManageProveedorScreenState extends State<ManageProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nombreController;
  late TextEditingController _especialidadController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;
  late TextEditingController _cuentaBancariaController;

  bool get isEditing => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.proveedor?.nombre ?? '');
    _especialidadController = TextEditingController(text: widget.proveedor?.especialidad ?? '');
    _telefonoController = TextEditingController(text: widget.proveedor?.telefono ?? '');
    _emailController = TextEditingController(text: widget.proveedor?.email ?? '');
    _direccionController = TextEditingController(text: widget.proveedor?.direccion ?? '');
    _cuentaBancariaController = TextEditingController(text: widget.proveedor?.cuentaBancaria ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especialidadController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _cuentaBancariaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final proveedor = Proveedor(
        id: widget.proveedor?.id ?? const Uuid().v4(),
        nombre: _nombreController.text.trim(),
        especialidad: _especialidadController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty 
            ? null 
            : _direccionController.text.trim(),
        cuentaBancaria: _cuentaBancariaController.text.trim().isEmpty 
            ? null 
            : _cuentaBancariaController.text.trim(),
      );

      if (isEditing) {
        await FirebaseService.updateProveedor(proveedor);
      } else {
        await FirebaseService.addProveedor(proveedor);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Proveedor actualizado correctamente'
                  : 'Proveedor creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar proveedor: $e'),
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

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${_nombreController.text}?\n\nEsta acción no se puede deshacer.',
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
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseService.deleteProveedor(widget.proveedor!.id);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proveedor eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar proveedor: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Eliminar proveedor',
              onPressed: _isLoading ? null : _eliminar,
            ),
        ],
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
                    _buildSectionTitle('Datos Básicos'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Proveedor *',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Ej: Juan García',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _especialidadController,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad *',
                        prefixIcon: Icon(Icons.engineering),
                        hintText: 'Ej: Fontanería, Electricidad, Cerrajería',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La especialidad es obligatoria';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Contacto'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono *',
                        prefixIcon: Icon(Icons.phone),
                        hintText: '666 777 888',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El teléfono es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        hintText: 'proveedor@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Calle, número, ciudad',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Datos Bancarios'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _cuentaBancariaController,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta Bancaria (IBAN)',
                        prefixIcon: Icon(Icons.account_balance),
                        hintText: 'ES00 0000 0000 00 0000000000',
                      ),
                      keyboardType: TextInputType.text,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(
                          isEditing ? 'Guardar Cambios' : 'Crear Proveedor',
                          style: const TextStyle(fontSize: 16),
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
        color: Color(0xFF1565C0),
      ),
    );
  }
}
