import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';
import '../../models/models.dart';
import '../../providers/cake_provider.dart';
import '../../config/supabase_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CakeManagementScreen extends ConsumerStatefulWidget {
  const CakeManagementScreen({super.key});

  @override
  ConsumerState<CakeManagementScreen> createState() => _CakeManagementScreenState();
}

class _CakeManagementScreenState extends ConsumerState<CakeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _variantController = TextEditingController();
  String? _selectedType;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _variantController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final fileName = 'cake_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await SupabaseConfig.client.storage
          .from('decreme')
          .upload(fileName, _imageFile!);
      
      return response;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveCake({Cake? existingCake}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imagePath;
      if (_imageFile != null) {
        imagePath = await _uploadImage();
      } else if (existingCake != null) {
        imagePath = existingCake.images;
      }

      final cake = Cake(
        id: existingCake?.id ?? 0, // Temporary ID for new cakes
        name: _nameController.text,
        price: Decimal.parse(_priceController.text),
        variant: _variantController.text,
        cakeTypes: _selectedType!,
        images: imagePath,
        createdAt: existingCake?.createdAt ?? DateTime.now(),
        isAvailable: existingCake?.isAvailable ?? true,
      );

      if (existingCake == null) {
        await ref.read(cakesProvider.notifier).addCake(cake);
      } else {
        await ref.read(cakesProvider.notifier).updateCake(cake);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingCake == null ? 'Cake added successfully' : 'Cake updated successfully'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCake(Cake cake) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cake'),
        content: const Text('Are you sure you want to delete this cake?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(cakesProvider.notifier).deleteCake(cake.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cake deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting cake: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCakeForm({Cake? cake}) {
    if (cake != null) {
      _nameController.text = cake.name;
      _priceController.text = cake.price.toString();
      _variantController.text = cake.variant;
      _selectedType = cake.cakeTypes;
      _imageUrl = cake.images;
    } else {
      _nameController.clear();
      _priceController.clear();
      _variantController.clear();
      _selectedType = null;
      _imageUrl = null;
      _imageFile = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    cake == null ? 'Add New Cake' : 'Edit Cake',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cake Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cake name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Cake Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Birthday', 'Wedding', 'Special Occasion']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select cake type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _variantController,
                    decoration: const InputDecoration(
                      labelText: 'Variant',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter variant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imageFile != null || _imageUrl != null
                        ? 'Change Image'
                        : 'Add Image'),
                  ),
                  if (_imageFile != null || _imageUrl != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: Image.file(
                        _imageFile ?? File(_imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : () => _saveCake(existingCake: cake),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(cake == null ? 'Add Cake' : 'Update Cake'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String formatPrice(Decimal price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(price.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final cakesAsync = ref.watch(cakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCakeForm(),
          ),
        ],
      ),
      body: cakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (cakes) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cakes.length,
          itemBuilder: (context, index) {
            final cake = cakes[index];
            return Card(
              child: ListTile(
                leading: cake.images != null
                    ? Image.network(
                        cake.images!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.cake),
                      )
                    : const Icon(Icons.cake),
                title: Text(cake.name),
                subtitle: Text('Rp ${formatPrice(cake.price)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showCakeForm(cake: cake),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCake(cake),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 