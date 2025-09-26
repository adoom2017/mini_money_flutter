import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/transaction_category.dart';
import '../utils/app_logger.dart';

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({super.key});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String _type = 'expense';
  double _amount = 0.0;
  String? _selectedCategoryKey;
  String _description = '';
  DateTime _selectedDate = DateTime.now();

  List<TransactionCategory> _expenseCategories = [];
  List<TransactionCategory> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    AppLogger.info('开始获取交易分类数据');
    try {
      final response = await _apiService.getCategories();
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          // 确保数据不为空且为列表类型，过滤掉可能的空值
          _expenseCategories = (data['expense'] as List? ?? [])
              .where((c) => c != null)
              .map((c) => TransactionCategory.fromJson(c))
              .toList();
          _incomeCategories = (data['income'] as List? ?? [])
              .where((c) => c != null)
              .map((c) => TransactionCategory.fromJson(c))
              .toList();
          _isLoading = false;
        });
        AppLogger.info(
            '分类数据获取成功 - 支出分类: ${_expenseCategories.length}, 收入分类: ${_incomeCategories.length}');
      } else {
        AppLogger.warning(
            '获取分类数据失败', 'HTTP ${response.statusCode}: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('加载失败'),
              content: const Text('加载分类失败'),
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
    } catch (e, stackTrace) {
      AppLogger.error('获取分类数据时发生异常', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('错误'),
            content: const Text('加载分类时发生错误'),
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
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final transactionData = {
        'amount': _amount,
        'type': _type,
        'categoryKey': _selectedCategoryKey,
        'description': _description,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      AppLogger.info('提交交易数据', transactionData);

      final response = await _apiService.createTransaction(transactionData);
      if (response.statusCode == 200 && mounted) {
        AppLogger.info('交易创建成功，返回首页');
        context.go('/'); // Navigate to home screen
      } else {
        AppLogger.warning(
            '交易创建失败', 'HTTP ${response.statusCode}: ${response.body}');
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('保存失败'),
            content: const Text('保存交易失败'),
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
      AppLogger.warning('表单验证失败 - 无法提交交易数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _type == 'expense' ? _expenseCategories : _incomeCategories;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('添加交易'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // 交易类型选择
                            CupertinoSlidingSegmentedControl<String>(
                              groupValue: _type,
                              onValueChanged: (value) {
                                setState(() {
                                  _type = value!;
                                  _selectedCategoryKey = null;
                                });
                              },
                              children: const {
                                'expense': Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('支出'),
                                ),
                                'income': Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('收入'),
                                ),
                              },
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CupertinoFormSection.insetGrouped(
                        header: const Text('交易详情'),
                        children: [
                          // 金额输入
                          CupertinoTextFormFieldRow(
                            prefix: const Icon(CupertinoIcons.money_dollar,
                                color: CupertinoColors.systemGrey),
                            placeholder: '金额',
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? '请输入金额' : null,
                            onSaved: (value) => _amount = double.parse(value!),
                          ),
                          // 分类选择
                          CupertinoFormRow(
                            prefix: const Icon(CupertinoIcons.tag,
                                color: CupertinoColors.systemGrey),
                            child: Row(
                              children: [
                                const Text('分类'),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showCategoryPicker(categories),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedCategoryKey ?? '请选择',
                                        style: TextStyle(
                                          color: _selectedCategoryKey != null
                                              ? CupertinoColors.label
                                              : CupertinoColors.placeholderText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(CupertinoIcons.forward,
                                          size: 16,
                                          color: CupertinoColors.systemGrey),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 描述输入
                          CupertinoTextFormFieldRow(
                            prefix: const Icon(CupertinoIcons.textformat,
                                color: CupertinoColors.systemGrey),
                            placeholder: '描述（可选）',
                            onSaved: (value) => _description = value ?? '',
                          ),
                          // 日期选择
                          CupertinoFormRow(
                            prefix: const Icon(CupertinoIcons.calendar,
                                color: CupertinoColors.systemGrey),
                            child: Row(
                              children: [
                                const Text('日期'),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showDatePicker(),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat.yMMMd('zh_CN')
                                            .format(_selectedDate),
                                        style: const TextStyle(
                                            color: CupertinoColors.label),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(CupertinoIcons.forward,
                                          size: 16,
                                          color: CupertinoColors.systemGrey),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showCategoryPicker(List<TransactionCategory> categories) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择分类'),
        actions: categories.map((category) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedCategoryKey = category.key;
              });
              Navigator.of(context).pop();
            },
            child: Text(category.key),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(2020),
                  onDateTimeChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
