import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/auto_transaction.dart';
import '../utils/category_utils.dart';

class AutoTransactionsScreen extends StatefulWidget {
  const AutoTransactionsScreen({super.key});

  @override
  State<AutoTransactionsScreen> createState() => _AutoTransactionsScreenState();
}

class _AutoTransactionsScreenState extends State<AutoTransactionsScreen> {
  final ApiService _apiService = ApiService();
  List<AutoTransaction> _autoTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAutoTransactions();
  }

  Future<void> _loadAutoTransactions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAutoTransactions();
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _autoTransactions =
              data.map((json) => AutoTransaction.fromJson(json)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('加载失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoTransaction(AutoTransaction autoTx) async {
    try {
      final response = await _apiService.toggleAutoTransaction(autoTx.id!);
      if (response.statusCode == 200) {
        _loadAutoTransactions();
        if (mounted) {
          _showSuccess('状态已更新');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('操作失败: $e');
      }
    }
  }

  Future<void> _deleteAutoTransaction(AutoTransaction autoTx) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content:
            Text('确定要删除定时记账"${autoTx.description ?? autoTx.categoryKey}"吗？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _apiService.deleteAutoTransaction(autoTx.id!);
        if (response.statusCode == 200) {
          _loadAutoTransactions();
          if (mounted) {
            _showSuccess('删除成功');
          }
        }
      } catch (e) {
        if (mounted) {
          _showError('删除失败: $e');
        }
      }
    }
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text('定时记账管理'),
        previousPageTitle: '设置',
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _autoTransactions.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 64,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无定时记账任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在添加交易时可以设置定时记账',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _loadAutoTransactions,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final autoTx = _autoTransactions[index];
                return _buildAutoTransactionCard(autoTx);
              },
              childCount: _autoTransactions.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoTransactionCard(AutoTransaction autoTx) {
    final isIncome = autoTx.type == 'income';
    final categoryName =
        CategoryUtils.getBuiltInCategoryName(autoTx.categoryKey);
    final amountColor =
        isIncome ? CupertinoColors.systemGreen : CupertinoColors.systemRed;

    return Dismissible(
      key: Key('auto_tx_${autoTx.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除定时记账"${autoTx.description ?? categoryName}"吗？'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteAutoTransaction(autoTx);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showAutoTransactionOptions(autoTx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧图标和状态
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isIncome
                          ? [
                              CupertinoColors.systemGreen.withOpacity(0.2),
                              CupertinoColors.systemGreen.withOpacity(0.1),
                            ]
                          : [
                              CupertinoColors.systemRed.withOpacity(0.2),
                              CupertinoColors.systemRed.withOpacity(0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          isIncome
                              ? CupertinoIcons.arrow_down_circle_fill
                              : CupertinoIcons.arrow_up_circle_fill,
                          color: amountColor,
                          size: 28,
                        ),
                      ),
                      if (!autoTx.isActive)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemGrey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 中间信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              autoTx.description ?? categoryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!autoTx.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '已暂停',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: CupertinoColors.tertiaryLabel
                                .resolveFrom(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            autoTx.executionDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                      if (autoTx.nextExecutionDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '下次: ${DateFormat('MM月dd日 HH:mm').format(autoTx.nextExecutionDate!.toLocal())}',
                            style: TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 右侧金额
                Text(
                  '${isIncome ? '+' : '-'}¥${NumberFormat('#,##0.00').format(autoTx.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // GestureDetector
    ); // Dismissible
  }

  // 显示操作选项
  void _showAutoTransactionOptions(AutoTransaction autoTx) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleAutoTransaction(autoTx);
            },
            child: Text(autoTx.isActive ? '暂停' : '启用'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmAndDeleteAutoTransaction(autoTx);
            },
            isDestructiveAction: true,
            child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text('取消'),
        ),
      ),
    );
  }

  // 确认并删除
  Future<void> _confirmAndDeleteAutoTransaction(AutoTransaction autoTx) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个定时记账任务吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAutoTransaction(autoTx);
    }
  }
}
