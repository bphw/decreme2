import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../../services/invoice_service.dart';
import 'order_success_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  bool _isStore = false;
  Client? _selectedStore;

  @override
  void initState() {
    super.initState();
    _loadDeliveryFee();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryFee() async {
    try {
      final response = await Supabase.instance.client
          .from('settings')
          .select('setting_value')
          .eq('name', 'invoice_delivery_fee')
          .single();
      
      if (response != null && mounted) {
        setState(() {
          _deliveryFeeController.text = response['setting_value'] ?? '0';
          ref.read(cartProvider.notifier).setDeliveryFee(_deliveryFeeController.text);
        });
      }
    } catch (e) {
      print('Error fetching delivery fee: $e');
    }
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    try {
      // Get current user using currentUser
      final user = Supabase.instance.client.auth.currentUser;
      print('Current User: ${user?.email}');
      
      // Check auth state from provider
      final authState = ref.read(authProvider);
      print('Auth Provider State:');
      print('- Status: ${authState.status}');
      print('- User Email: ${authState.user?.email}');
      print('- Is Authenticated: ${authState.status == AuthStatus.authenticated}');
      
      // Verify both auth checks
      if (user == null || authState.status != AuthStatus.authenticated) {
        print('Authentication check failed:');
        print('- Supabase User exists: ${user != null}');
        print('- Auth State authenticated: ${authState.status == AuthStatus.authenticated}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to place an order'),
              backgroundColor: Colors.red,
            ),
          );
          print('Redirecting to login screen');
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      print('Authentication verified, proceeding with order...');
      print('User ID: ${user.id}');
      print('User Email: ${user.email}');
      
      await ref.read(orderProvider.notifier).createOrder(
            buyerName: _isStore ? _selectedStore!.name : _nameController.text,
            buyerPhone: _isStore ? _selectedStore!.phone : _phoneController.text,
            notes: _notesController.text,
            clientId: _isStore ? _selectedStore!.id : null,
          );

      print('Order created successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error during checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndShareInvoice() async {
    final cartState = ref.read(cartProvider);
    final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    
    if (cartState.items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart is empty'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final file = await InvoiceService.generateInvoice(
        orderNumber: orderNumber,
        buyerName: _isStore ? _selectedStore!.name : _nameController.text,
        buyerPhone: _isStore ? _selectedStore!.phone : _phoneController.text,
        items: List<CartItem>.from(cartState.items),
        subtotal: cartState.subtotal,
        tax: cartState.tax,
        deliveryFee: cartState.deliveryFee,
        total: cartState.total,
        notes: _notesController.text,
        clientId: _isStore ? _selectedStore?.id : null,
      );

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice $orderNumber',
        text: 'Here is your invoice for order $orderNumber',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: orderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Order items summary with thumbnails
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Cake thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.cake.images ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.cake),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Cake details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.cake.name,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Text(
                                          '${item.quantity}x @ Rp ${item.cake.price}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Price
                                  Text(
                                    'Rp ${item.total}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      // Price summary with formatted values and consistent styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(
                            'Rp ${cart.formattedSubtotal}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (10%)'),
                          Text('Rp ${cart.formattedTax}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee'),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _deliveryFeeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                              onChanged: (value) {
                                ref.read(cartProvider.notifier).setDeliveryFee(value.isEmpty ? '0' : value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Rp ${cart.formattedTotal}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Buyer Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Order for Store'),
                        value: _isStore,
                        onChanged: (value) {
                          setState(() {
                            _isStore = value;
                            _selectedStore = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isStore) ...[
                        clientsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) {
                            print('Error in UI: $error'); // Debug log
                            return Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Error loading stores: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(clientsProvider.notifier).loadClients();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          },
                          data: (clients) {
                            if (clients.isEmpty) {
                              return const Center(
                                child: Text('No stores available'),
                              );
                            }
                            
                            return DropdownButtonFormField<Client>(
                              decoration: const InputDecoration(
                                labelText: 'Select Store',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedStore,
                              items: clients.map((client) {
                                return DropdownMenuItem(
                                  value: client,
                                  child: Text(client.name),
                                );
                              }).toList(),
                              onChanged: (Client? value) {
                                setState(() {
                                  _selectedStore = value;
                                  if (value != null) {
                                    _nameController.text = value.name;
                                    _phoneController.text = value.phone;
                                    if (value.deliveryFee != null) {
                                      _deliveryFeeController.text = value.deliveryFee.toString();
                                      ref.read(cartProvider.notifier).setDeliveryFee(value.deliveryFee.toString());
                                    }
                                  }
                                });
                              },
                              validator: (value) {
                                if (_isStore && value == null) {
                                  return 'Please select a store';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Show store details if selected
                        if (_selectedStore != null) ...[
                          Text(
                            'Store Details:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Contact: ${_selectedStore!.contact}'),
                          Text('Address: ${_selectedStore!.address}'),
                          Text('City: ${_selectedStore!.city}'),
                          if (_selectedStore!.deliveryFee != null)
                            Text('Delivery Fee: Rp ${_selectedStore!.deliveryFee}'),
                        ],
                      ] else ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      if (orderState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Error: ${orderState.error.toString()}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _generateAndShareInvoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Generate & Share Invoice'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: orderState.isLoading ? null : _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 