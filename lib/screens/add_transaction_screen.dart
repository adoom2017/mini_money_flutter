import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/transaction_category.dart';
import '../utils/app_logger.dart';
import '../utils/category_utils.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _apiService = ApiService();

  String _type = 'expense'; // 默认为支出
  double _amount = 0.0;
  String? _selectedCategoryKey;
  String _description = '';
  DateTime _selectedDate = DateTime.now();

  List<TransactionCategory> _expenseCategories = [];
  List<TransactionCategory> _incomeCategories = [];
  bool _isLoading = true;

  // 计算器状态
  String _displayAmount = '0.00';
  bool _hasDecimal = false;
  int _decimalPlaces = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.getCategories();
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
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
      }
    } catch (error) {
      AppLogger.error('获取分类失败: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<TransactionCategory> get _currentCategories {
    return _type == 'expense' ? _expenseCategories : _incomeCategories;
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_displayAmount == '0.00') {
        _displayAmount = '$number.00';
      } else if (_hasDecimal && _decimalPlaces < 2) {
        _displayAmount = _displayAmount.substring(
                0, _displayAmount.length - (2 - _decimalPlaces)) +
            number +
            '0' * (1 - _decimalPlaces);
        _decimalPlaces++;
      } else if (!_hasDecimal) {
        String integerPart = _displayAmount.split('.')[0];
        if (integerPart.length < 8) {
          // 限制整数部分最多8位
          _displayAmount = '$integerPart$number.00';
        }
      }
      _amount = double.parse(_displayAmount);
    });
  }

  void _onDecimalPressed() {
    if (!_hasDecimal) {
      setState(() {
        _hasDecimal = true;
        _decimalPlaces = 0;
        _displayAmount =
            '${_displayAmount.substring(0, _displayAmount.length - 3)}.00';
      });
    }
  }

  void _onDeletePressed() {
    setState(() {
      if (_hasDecimal && _decimalPlaces > 0) {
        _decimalPlaces--;
        if (_decimalPlaces == 0) {
          _displayAmount =
              '${_displayAmount.substring(0, _displayAmount.length - 2)}00';
        } else {
          _displayAmount =
              '${_displayAmount.substring(0, _displayAmount.length - 1)}0';
        }
      } else if (_hasDecimal && _decimalPlaces == 0) {
        _hasDecimal = false;
        _displayAmount =
            '${_displayAmount.substring(0, _displayAmount.length - 1)}00';
      } else {
        String integerPart = _displayAmount.split('.')[0];
        if (integerPart.length > 1) {
          integerPart = integerPart.substring(0, integerPart.length - 1);
        } else {
          integerPart = '0';
        }
        _displayAmount = '$integerPart.00';
      }
      _amount = double.parse(_displayAmount);
    });
  }

  void _handleNavigation() {
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_amount <= 0) {
      _showAlert('请输入金额');
      return;
    }

    if (_selectedCategoryKey == null) {
      _showAlert('请选择分类');
      return;
    }

    try {
      final transactionData = {
        'type': _type,
        'amount': _amount,
        'categoryKey': _selectedCategoryKey,
        'description': _description,
        'date': _selectedDate.toUtc().toIso8601String(),
      };

      final response = await _apiService.createTransaction(transactionData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _handleNavigation();
      } else {
        _showAlert('保存失败，请重试');
      }
    } catch (error) {
      AppLogger.error('保存交易失败: $error');
      _showAlert('保存失败，请重试');
    }
  }

  Future<void> _showDateTimePicker() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 顶部控制栏
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('确定'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              // 日期时间选择器
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: _selectedDate,
                    maximumDate: DateTime.now(),
                    minimumDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    onDateTimeChanged: (DateTime newDateTime) {
                      setState(() {
                        _selectedDate = newDateTime;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDescriptionInput() async {
    final TextEditingController controller =
        TextEditingController(text: _description);

    await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('添加备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '请输入备注信息',
            maxLines: 3,
            maxLength: 100,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () {
              setState(() {
                _description = controller.text;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildTopBar(),
              // 类型选择器（收入/支出）
              _buildTypeSelector(),
              // 分类选择网格
              Expanded(
                child: _buildCategoryGrid(),
              ),
              // 底部计算器区域
              _buildCalculatorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _handleNavigation,
            child: const Row(
              children: [
                Icon(CupertinoIcons.left_chevron,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.money_dollar_circle,
                    color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('添加交易',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.separator.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _type,
        children: const {
          'expense': Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.minus_circle_fill,
                    color: CupertinoColors.systemRed, size: 18),
                SizedBox(width: 6),
                Text('支出'),
              ],
            ),
          ),
          'income': Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.plus_circle_fill,
                    color: CupertinoColors.systemGreen, size: 18),
                SizedBox(width: 6),
                Text('收入'),
              ],
            ),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _type = value;
              _selectedCategoryKey = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.separator.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _currentCategories.length,
        itemBuilder: (context, index) {
          final category = _currentCategories[index];
          final isSelected = _selectedCategoryKey == category.key;
          final color = _type == 'expense'
              ? CupertinoColors.systemRed
              : CupertinoColors.systemGreen;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryKey = category.key;
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)])
                        : LinearGradient(colors: [
                            CupertinoColors.systemGrey6,
                            CupertinoColors.systemGrey5
                          ]),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Icon(
                    CategoryUtils.getCategoryIcon(category.key),
                    color: isSelected ? Colors.white : color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CategoryUtils.getCategoryName(category.key),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? color : CupertinoColors.label,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculatorSection() {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.separator,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 金额显示
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: _type == 'expense'
                      ? CupertinoColors.systemRed
                      : CupertinoColors.systemGreen,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '¥$_displayAmount',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: _type == 'expense'
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
          // 日期和备注
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showDateTimePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            color: Color(0xFFFF9800),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MM/dd HH:mm').format(_selectedDate),
                            style: const TextStyle(
                              color: CupertinoColors.label,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showDescriptionInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.pencil,
                          color: Color(0xFF667EEA),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _description.isEmpty ? '点击填写备注' : _description,
                          style: TextStyle(
                            color: _description.isEmpty
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.label,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 计算器键盘
          _buildCalculatorKeyboard(),
        ],
      ),
    );
  }

  Widget _buildCalculatorKeyboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKeyboardRow(['1', '2', '3', '+×']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['4', '5', '6', '-÷']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['7', '8', '9', '保存再记']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['.', '0', '⌫', '完成']),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      children: keys.map((key) => _buildKeyboardButton(key)).toList(),
    );
  }

  Widget _buildKeyboardButton(String key) {
    Widget child;
    VoidCallback? onPressed;
    switch (key) {
      case '+×':
      case '-÷':
      case '保存再记':
        child = Container(
          height: 50,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        );
        onPressed = null;
        break;
      case '⌫':
        child = Container(
          height: 50,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.delete_left,
              color: CupertinoColors.systemRed,
            ),
          ),
        );
        onPressed = _onDeletePressed;
        break;
      case '完成':
        child = Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '完成',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        onPressed = _saveTransaction;
        break;
      case '.':
        child = Container(
          height: 50,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '.',
              style: TextStyle(
                fontSize: 24,
                color: CupertinoColors.label,
              ),
            ),
          ),
        );
        onPressed = _onDecimalPressed;
        break;
      default:
        if (RegExp(r'[0-9]').hasMatch(key)) {
          child = Container(
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 24,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          );
          onPressed = () => _onNumberPressed(key);
        } else {
          child = Container(
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          );
          onPressed = null;
        }
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onPressed,
          child: child,
        ),
      ),
    );
  }
}
