import 'package:flutter/cupertino.dart';
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
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('设置'),
            ),
            child: SafeArea(
              child: userProvider.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : user == null
                      ? const Center(child: Text('无法加载用户资料'))
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  _buildAvatar(context, userProvider),
                                  const SizedBox(height: 20),
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: CupertinoFormSection.insetGrouped(
                                header: const Text('账户设置'),
                                children: [
                                  CupertinoFormRow(
                                    prefix: const Icon(CupertinoIcons.lock,
                                        color: CupertinoColors.systemGrey),
                                    child: GestureDetector(
                                      onTap: () => _showPasswordDialog(
                                          context, userProvider),
                                      child: const Row(
                                        children: [
                                          Text('修改密码'),
                                          Spacer(),
                                          Icon(CupertinoIcons.forward,
                                              color:
                                                  CupertinoColors.systemGrey),
                                        ],
                                      ),
                                    ),
                                  ),
                                  CupertinoFormRow(
                                    prefix: const Icon(CupertinoIcons.mail,
                                        color: CupertinoColors.systemGrey),
                                    child: GestureDetector(
                                      onTap: () => _showEmailDialog(
                                          context, userProvider),
                                      child: const Row(
                                        children: [
                                          Text('修改邮箱'),
                                          Spacer(),
                                          Icon(CupertinoIcons.forward,
                                              color:
                                                  CupertinoColors.systemGrey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 20),
                                child: CupertinoButton.filled(
                                  onPressed: () {
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoAlertDialog(
                                        title: const Text('退出登录'),
                                        content: const Text('确定要退出登录吗？'),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('取消'),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Provider.of<AuthProvider>(context,
                                                      listen: false)
                                                  .logout();
                                            },
                                            child: const Text('退出'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    '退出登录',
                                    style:
                                        TextStyle(color: CupertinoColors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey5,
              border: Border.all(color: CupertinoColors.systemGrey4, width: 2),
            ),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(CupertinoIcons.person_fill,
                            size: 60, color: CupertinoColors.systemGrey);
                      },
                    ),
                  )
                : const Icon(CupertinoIcons.person_fill,
                    size: 60, color: CupertinoColors.systemGrey),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => provider.pickAndUpdateAvatar(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.camera,
                  color: CupertinoColors.white,
                  size: 18,
                ),
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

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('修改密码'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextFormFieldRow(
                  placeholder: '当前密码',
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? '必填' : null,
                  onSaved: (v) => currentPassword = v!,
                ),
                const SizedBox(height: 8),
                CupertinoTextFormFieldRow(
                  placeholder: '新密码',
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? '至少6个字符' : null,
                  onSaved: (v) => newPassword = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await provider.updateUserPassword(
                    currentPassword, newPassword);
                Navigator.of(ctx).pop();
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text(success ? '成功' : '失败'),
                    content: Text(success ? '密码已更新' : '更新密码失败'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context, UserProvider provider) {
    final formKey = GlobalKey<FormState>();
    String email = provider.user?.email ?? '';
    String password = '';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('修改邮箱'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextFormFieldRow(
                  initialValue: email,
                  placeholder: '新邮箱',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? '无效邮箱' : null,
                  onSaved: (v) => email = v!,
                ),
                const SizedBox(height: 8),
                CupertinoTextFormFieldRow(
                  placeholder: '确认密码',
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? '必填' : null,
                  onSaved: (v) => password = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await provider.updateUserEmail(email, password);
                Navigator.of(ctx).pop();
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text(success ? '成功' : '失败'),
                    content: Text(success ? '邮箱已更新' : '更新邮箱失败'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
}
