import 'dart:convert';
import 'package:flutter/material.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加载分类失败')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('获取分类数据时发生异常', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载分类时发生错误')),
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
        'date': _selectedDate.toIso8601String(),
      };

      AppLogger.info('提交交易数据', transactionData);

      final response = await _apiService.createTransaction(transactionData);
      if (response.statusCode == 200 && mounted) {
        AppLogger.info('交易创建成功，返回首页');
        context.go('/'); // Navigate to home screen
      } else {
        AppLogger.warning(
            '交易创建失败', 'HTTP ${response.statusCode}: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction.')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _type = newSelection.first;
                        _selectedCategoryKey =
                            null; // Reset category on type change
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an amount.' : null,
                    onSaved: (value) => _amount = double.parse(value!),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: _selectedCategoryKey,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                            value: cat.key, child: Text(cat.key)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategoryKey = value),
                    validator: (value) =>
                        value == null ? 'Please select a category.' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onSaved: (value) => _description = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
