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
  // 原始输入（用于表达式支持）
  String _rawInput = '';

  // 备注输入控制器
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _descriptionController.addListener(() {
      _description = _descriptionController.text;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
      // 如果当前为表达式模式（包含运算符），则直接把数字追加到原始输入
      if (RegExp(r'[+\-*/×÷]').hasMatch(_rawInput)) {
        if (_rawInput.isEmpty) _rawInput = '';
        _rawInput += number;
      } else {
        // 原有的数字输入逻辑
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
        _rawInput = _displayAmount.replaceAll(',', '');
        _amount = double.parse(_displayAmount);
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      // 表达式模式下直接在原始输入追加小数点
      if (RegExp(r'[+\-*/×÷]').hasMatch(_rawInput)) {
        // 在当前操作数中只允许一个小数点
        final parts = _rawInput.split(RegExp(r'[+\-*/×÷×÷]'));
        final last = parts.isNotEmpty ? parts.last : '';
        if (!last.contains('.')) {
          _rawInput += '.';
        }
      } else if (!_hasDecimal) {
        _hasDecimal = true;
        _decimalPlaces = 0;
        _displayAmount =
            '${_displayAmount.substring(0, _displayAmount.length - 3)}.00';
        _rawInput = _displayAmount.replaceAll(',', '');
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      // 如果为表达式模式，删除原始输入最后一个字符
      if (RegExp(r'[+\-*/×÷]').hasMatch(_rawInput)) {
        if (_rawInput.isNotEmpty) {
          _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        }
        // 保持为空字符串而不是 '0'
        if (_rawInput.isEmpty) _rawInput = '';
      } else {
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
        _rawInput = _displayAmount.replaceAll(',', '');
        _amount = double.parse(_displayAmount);
      }
    });
  }

  bool get _isExpressionMode =>
      _rawInput.isNotEmpty && RegExp(r'[+\-*/×÷]').hasMatch(_rawInput);

  // 评估简单算术表达式（支持 + - * /, 小数）
  double? _evaluateMathExpression(String expr) {
    try {
      // 替换可视化乘除符号
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
      // 移除空格
      expr = expr.replaceAll(' ', '');
      // 使用逆波兰（Shunting Yard）算法
      final outputQueue = <String>[];
      final opStack = <String>[];

      int i = 0;
      String numberBuffer() {
        final sb = StringBuffer();
        while (i < expr.length && (RegExp(r'[0-9\.]').hasMatch(expr[i]))) {
          sb.write(expr[i]);
          i++;
        }
        return sb.toString();
      }

      String precedence(String op) {
        if (op == '+' || op == '-') return '1';
        if (op == '*' || op == '/') return '2';
        return '0';
      }

      while (i < expr.length) {
        final ch = expr[i];
        if (RegExp(r'[0-9\.]').hasMatch(ch)) {
          final num = numberBuffer();
          outputQueue.add(num);
          continue;
        }
        if (ch == '+' || ch == '-' || ch == '*' || ch == '/') {
          while (opStack.isNotEmpty &&
              precedence(opStack.last).compareTo(precedence(ch)) >= 0) {
            outputQueue.add(opStack.removeLast());
          }
          opStack.add(ch);
          i++;
          continue;
        }
        // 未知字符，跳过
        i++;
      }

      while (opStack.isNotEmpty) {
        outputQueue.add(opStack.removeLast());
      }

      // 计算 RPN
      final evalStack = <double>[];
      for (final token in outputQueue) {
        if (token == '+' || token == '-' || token == '*' || token == '/') {
          if (evalStack.length < 2) return null;
          final b = evalStack.removeLast();
          final a = evalStack.removeLast();
          double res = 0;
          if (token == '+') res = a + b;
          if (token == '-') res = a - b;
          if (token == '*') res = a * b;
          if (token == '/') {
            if (b == 0) return null;
            res = a / b;
          }
          evalStack.add(res);
        } else {
          evalStack.add(double.parse(token));
        }
      }

      if (evalStack.length != 1) return null;
      return evalStack.first;
    } catch (e) {
      AppLogger.error('表达式解析错误: $e');
      return null;
    }
  }

  void _onEvaluatePressed() {
    final result = _evaluateMathExpression(_rawInput);
    if (result == null || result.isNaN) {
      _showAlert('表达式错误');
      return;
    }
    setState(() {
      _amount = result;
      _displayAmount = result.toStringAsFixed(2);
      _rawInput = _displayAmount;
      _hasDecimal = _displayAmount.contains('.');
      if (_hasDecimal) {
        final parts = _displayAmount.split('.');
        _decimalPlaces = parts[1].length;
      } else {
        _decimalPlaces = 0;
      }
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
          childAspectRatio: 0.85, // 调整为 0.85，给文字更多垂直空间
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
              mainAxisSize: MainAxisSize.min, // 使用最小尺寸
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)])
                        : const LinearGradient(colors: [
                            CupertinoColors.systemGrey6,
                            CupertinoColors.systemGrey5
                          ]),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      CategoryUtils.getCategoryIcon(category),
                      style: CategoryUtils.getEmojiTextStyle(
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CategoryUtils.getCategoryName(category),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? color : CupertinoColors.label,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          // 表达式显示（仅在表达式模式时显示）
          if (_rawInput.isNotEmpty && _isExpressionMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _rawInput,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'RobotoMono',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // 日期和备注
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showDateTimePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MM/dd HH:mm').format(_selectedDate),
                          style: const TextStyle(
                            color: CupertinoColors.label,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CupertinoTextField(
                    controller: _descriptionController,
                    placeholder: '请输入备注',
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        CupertinoIcons.pencil,
                        color: Color(0xFF667EEA),
                        size: 20,
                      ),
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
          _buildKeyboardRow(['1', '2', '3', '+']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['4', '5', '6', '-']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['7', '8', '9', '×']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['.', '0', '⌫', '÷']),
          const SizedBox(height: 12),
          _buildKeyboardRow(['完成']),
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
        final isExpr = _isExpressionMode;
        child = Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              isExpr ? '=' : '完成',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        onPressed = isExpr ? _onEvaluatePressed : _saveTransaction;
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
        } else if (key == '+' || key == '-' || key == '×' || key == '÷') {
          // 运算符处理：如果当前已是表达式且最后一个是运算符则替换，否则追加
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
                  fontSize: 20,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          );
          onPressed = () {
            setState(() {
              // 若 raw 为空且当前 display 有值，则以当前显示为起始
              if (_rawInput.isEmpty && _displayAmount != '0.00') {
                _rawInput = _displayAmount;
              }
              // 如果仍为空，不允许直接以运算符开始
              if (_rawInput.isEmpty) return;
              final lastChar = _rawInput[_rawInput.length - 1];
              if (lastChar == '+' ||
                  lastChar == '-' ||
                  lastChar == '*' ||
                  lastChar == '/' ||
                  lastChar == '×' ||
                  lastChar == '÷') {
                // 替换最后一个运算符
                _rawInput = _rawInput.substring(0, _rawInput.length - 1) + key;
              } else {
                _rawInput += key;
              }
            });
          };
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
