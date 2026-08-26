import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import '../../cart_wishlist/data/app_database.dart';
import '../../checkout/domain/order_status_tracker.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final AppDatabase database;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.database,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  bool _isCodeSent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Profile & Auth'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                        child: user.photoURL == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user.displayName ?? 'Authenticated User'),
                      subtitle: Text(user.email ?? user.phoneNumber ?? user.uid),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Linked Credentials:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...user.providerData.map(
                    (p) => ListTile(
                      leading: Icon(
                        p.providerId == 'google.com'
                            ? Icons.g_mobiledata
                            : p.providerId == 'phone'
                                ? Icons.phone
                                : Icons.security,
                      ),
                      title: Text(p.providerId),
                      subtitle: Text(p.email ?? p.phoneNumber ?? p.uid),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!user.providerData.any((p) => p.providerId == 'phone')) ...[
                    const Text('Link Phone Number (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (!_isCodeSent) ...[
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (with country code, e.g. +1234567890)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendPhoneCode,
                        child: const Text('Send Verification Code'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _smsCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Enter 6-digit SMS Code',
                          prefixIcon: Icon(Icons.pin),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifySMSCode,
                        child: const Text('Link Phone Credential'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  FutureBuilder<List<OrderRecord>>(
                    future: widget.database.select(widget.database.orderRecords).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return const Text('No orders placed yet.', style: TextStyle(color: Colors.grey));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                              title: Text('Order #${order.orderId}'),
                              subtitle: Text('\$${order.totalAmount.toStringAsFixed(2)} via ${order.paymentMethod.toUpperCase()}'),
                              trailing: Chip(
                                label: Text(order.status, style: const TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green.shade100,
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Order Details #${order.orderId}'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ${order.status}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        const Text('Order Progress Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        ...OrderStatusTracker.getMilestones(order.status).map((m) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                                  size: 16,
                                                  color: m.isCompleted ? Colors.green : Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  m.title,
                                                  style: TextStyle(
                                                    fontWeight: m.isCurrent ? FontWeight.bold : FontWeight.normal,
                                                    color: m.isCompleted ? Colors.black87 : Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 8),
                                        Text('Total Amount: \$${order.totalAmount.toStringAsFixed(2)}'),
                                        Text('Payment Method: ${order.paymentMethod.toUpperCase()}'),
                                        Text('Date: ${order.createdAt.toIso8601String().split('T').first}'),
                                        const SizedBox(height: 8),
                                        const Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(order.shippingAddressJson),
                                        const SizedBox(height: 8),
                                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(order.itemsJson),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    onPressed: () async {
                      await widget.authService.signOut();
                    },
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Sign in to save wishlist and manage orders',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Sign in with Google'),
                          onPressed: () async {
                            try {
                              await widget.authService.signInWithGoogle();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sign in failed: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendPhoneCode() async {
    setState(() => _isLoading = true);
    try {
      await widget.authService.verifyPhone(
        phoneNumber: _phoneController.text.trim(),
        onVerificationCompleted: (cred) async {
          await widget.authService.linkPhoneCredential(cred);
          if (mounted) setState(() => _isLoading = false);
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone verification failed: $e')));
          }
        },
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isCodeSent = true;
              _isLoading = false;
            });
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifySMSCode() async {
    if (_verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );
      await widget.authService.linkPhoneCredential(credential);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCodeSent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone linked successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to link phone: $e')));
      }
    }
  }
}
