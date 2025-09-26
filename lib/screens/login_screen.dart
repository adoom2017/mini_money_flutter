import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../api/api_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLogin = true;
  bool _isLoading = false;

  String _username = '';
  String _password = '';
  String _email = '';

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid != true) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final response = await _apiService.login(_username, _password);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await Provider.of<AuthProvider>(context, listen: false)
              .login(data['token']);
        } else {
          // Handle login error
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('登录失败'),
              content: const Text('请检查您的登录凭据'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      } else {
        final response =
            await _apiService.register(_username, _password, _email);
        if (response.statusCode == 201) {
          // Automatically log in after successful registration
          final loginResponse = await _apiService.login(_username, _password);
          if (loginResponse.statusCode == 200) {
            final data = jsonDecode(loginResponse.body);
            await Provider.of<AuthProvider>(context, listen: false)
                .login(data['token']);
          }
        } else {
          // Handle registration error
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('注册失败'),
              content: const Text('请重试'),
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
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: Text('发生了错误: $e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? '欢迎回来!' : '创建账户',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CupertinoTextFormFieldRow(
                          prefix: const Icon(CupertinoIcons.person,
                              color: CupertinoColors.systemGrey),
                          placeholder: '用户名',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                          onSaved: (value) => _username = value!,
                        ),
                        if (!_isLogin)
                          CupertinoTextFormFieldRow(
                            prefix: const Icon(CupertinoIcons.mail,
                                color: CupertinoColors.systemGrey),
                            placeholder: '邮箱',
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return '请输入有效的邮箱地址';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value!,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        CupertinoTextFormFieldRow(
                          prefix: const Icon(CupertinoIcons.lock,
                              color: CupertinoColors.systemGrey),
                          placeholder: '密码',
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return '密码至少需要6个字符';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CupertinoActivityIndicator()
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: _trySubmit,
                          child: Text(_isLogin ? '登录' : '注册'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? '创建新账户' : '我已有账户',
                          style: const TextStyle(
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
