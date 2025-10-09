import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            backgroundColor: const Color(0xFFF8F9FA),
            navigationBar: CupertinoNavigationBar(
              backgroundColor:
                  CupertinoColors.systemBackground.withOpacity(0.8),
              middle: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: const SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Center(
                    child: Text(
                      '⚙️ 设置',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: SafeArea(
              child: userProvider.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : user == null
                      ? const Center(child: Text('无法加载用户资料'))
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Container(
                                margin:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA)
                                          .withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      _buildAvatar(context, userProvider),
                                      const SizedBox(height: 20),
                                      Text(
                                        user.username,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          '个人资料',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(left: 4, bottom: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.settings,
                                            size: 18,
                                            color: Color(0xFF667EEA),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '账户设置',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors.label,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildSettingCard(
                                      icon: CupertinoIcons.lock_shield,
                                      iconColor: const Color(0xFF667EEA),
                                      title: '修改密码',
                                      subtitle: '更改您的登录密码',
                                      onTap: () => _showPasswordDialog(
                                          context, userProvider),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSettingCard(
                                      icon: CupertinoIcons.mail,
                                      iconColor: const Color(0xFF764BA2),
                                      title: '修改邮箱',
                                      subtitle: '更新您的邮箱地址',
                                      onTap: () => _showEmailDialog(
                                          context, userProvider),
                                    ),
                                    const SizedBox(height: 24),
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(left: 4, bottom: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.clock,
                                            size: 18,
                                            color: Color(0xFF667EEA),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '自动记账',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors.label,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildSettingCard(
                                      icon: CupertinoIcons.repeat,
                                      iconColor: const Color(0xFF4ECDC4),
                                      title: '定时记账管理',
                                      subtitle: '管理您的定时记账任务',
                                      onTap: () =>
                                          context.push('/auto-transactions'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 32, 16, 32),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        CupertinoColors.systemRed,
                                        Color(0xFFE53E3E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.systemRed
                                            .withOpacity(0.3),
                                        spreadRadius: 0,
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
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
                                                Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false)
                                                    .logout();
                                              },
                                              child: const Text('退出'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.square_arrow_right,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '退出登录',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(CupertinoIcons.person_fill,
                            size: 50, color: Colors.white70);
                      },
                    ),
                  )
                : const Icon(CupertinoIcons.person_fill,
                    size: 50, color: Colors.white70),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: () => provider.pickAndUpdateAvatar(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: Color(0xFF667EEA),
                  size: 16,
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
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  showCupertinoDialog(
                    context: ctx,
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

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  showCupertinoDialog(
                    context: ctx,
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
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.separator.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.1),
                        iconColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
