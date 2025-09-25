import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : user == null
                    ? const Center(child: Text('Could not load user profile.'))
                    : ListView(
                        children: [
                          const SizedBox(height: 20),
                          _buildAvatar(context, userProvider),
                          const SizedBox(height: 20),
                          Text(user.username, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                          Text(user.email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 30),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            onTap: () => _showPasswordDialog(context, userProvider),
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Change Email'),
                            onTap: () => _showEmailDialog(context, userProvider),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Logout', style: TextStyle(color: Colors.red)),
                            onTap: () {
                              Provider.of<AuthProvider>(context, listen: false).logout();
                            },
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserProvider provider) {
    final avatarUrl = provider.user?.avatar;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20),
                onPressed: () => provider.pickAndUpdateAvatar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, UserProvider provider) {
    final formKey = GlobalKey<FormState>();
    String currentPassword = '';
    String newPassword = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => currentPassword = v!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              onSaved: (v) => newPassword = v!,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await provider.updateUserPassword(currentPassword, newPassword);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Password updated.' : 'Failed to update password.')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context, UserProvider provider) {
    final formKey = GlobalKey<FormState>();
    String email = provider.user?.email ?? '';
    String password = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              initialValue: email,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
              onSaved: (v) => email = v!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => password = v!,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await provider.updateUserEmail(email, password);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Email updated.' : 'Failed to update email.')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
