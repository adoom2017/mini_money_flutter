import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../utils/category_utils.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedDates = <String>{}; // 跟踪展开的日期

  @override
  void initState() {
    super.initState();
    // 默认展开今天的日期
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _expandedDates.add(today);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('交易明细'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.refresh),
                onPressed: () => provider.fetchTransactions(),
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16), // 添加顶部padding
                    child: provider.isLoading
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 12),
                          )
                        : _buildTransactionListView(context, provider),
                  ),
                ),
                // 浮动按钮
                Positioned(
                  bottom: 70,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => context.go('/add-transaction'),
                    backgroundColor: const Color(0xFF1976D2), // 更亮的蓝色
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: const CircleBorder(), // 明确设置为圆形
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionListView(
      BuildContext context, TransactionProvider provider) {
    if (provider.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.doc_text,
                size: 50,
                color: CupertinoColors.systemBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无交易记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '开始记录您的第一笔交易吧！',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.placeholderText,
              ),
            ),
          ],
        ),
      );
    }

    // 按日期分组交易
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (final transaction in provider.transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (groupedTransactions[dateKey] == null) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // 按日期倒序排列
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return CupertinoScrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final transactions = groupedTransactions[dateKey]!;
          final date = DateTime.parse(dateKey);

          return _buildDateGroup(context, date, transactions, provider);
        },
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, DateTime date,
      List<Transaction> transactions, TransactionProvider provider) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final isExpanded = _expandedDates.contains(dateKey);

    // 计算当日收支
    double dayIncome = 0;
    double dayExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        dayIncome += transaction.amount;
      } else {
        dayExpense += transaction.amount;
      }
    }

    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
        DateFormat('yyyy-MM-dd').format(date);
    final isYesterday = DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(const Duration(days: 1))) ==
        DateFormat('yyyy-MM-dd').format(date);

    String dateLabel;
    if (isToday) {
      dateLabel = '今天';
    } else if (isYesterday) {
      dateLabel = '昨天';
    } else {
      dateLabel = DateFormat('MM月dd日').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 可点击的日期标题栏
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDates.remove(dateKey);
                } else {
                  _expandedDates.add(dateKey);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.systemBlue.withOpacity(0.1),
                    CupertinoColors.systemBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 展开/收起指示图标
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      CupertinoIcons.forward,
                      color: CupertinoColors.systemBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.calendar,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('E').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.placeholderText,
                    ),
                  ),
                  const Spacer(),
                  // 交易数量提示
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${transactions.length}笔',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (dayExpense > 0)
                    Text(
                      '-¥${dayExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  if (dayExpense > 0 && dayIncome > 0)
                    const SizedBox(width: 12),
                  if (dayIncome > 0)
                    Text(
                      '+¥${dayIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 动画展开/收起的交易列表
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isExpanded ? 1.0 : 0.0,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.separator.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 68),
                      color: CupertinoColors.separator,
                    ),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionTile(
                          context, transaction, provider);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction,
      TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 图标容器 - 优化设计
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: transaction.type == 'expense'
                    ? [
                        CupertinoColors.systemRed.withOpacity(0.2),
                        CupertinoColors.systemRed.withOpacity(0.1),
                      ]
                    : [
                        CupertinoColors.systemGreen.withOpacity(0.2),
                        CupertinoColors.systemGreen.withOpacity(0.1),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: transaction.type == 'expense'
                    ? CupertinoColors.systemRed.withOpacity(0.3)
                    : CupertinoColors.systemGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              CategoryUtils.getCategoryIcon(transaction.categoryKey),
              color: transaction.type == 'expense'
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // 交易信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? CategoryUtils.getCategoryName(transaction.categoryKey)
                      : transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.tag,
                      size: 12,
                      color: CupertinoColors.placeholderText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CategoryUtils.getCategoryName(transaction.categoryKey),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.placeholderText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      CupertinoIcons.clock,
                      size: 12,
                      color: CupertinoColors.placeholderText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(transaction.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.placeholderText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 金额和操作按钮
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == 'expense' ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'expense'
                      ? CupertinoColors.systemRed
                      : CupertinoColors.systemGreen,
                ),
              ),
              const SizedBox(height: 4),
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                minSize: 0,
                child: Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed.withOpacity(0.7),
                  size: 16,
                ),
                onPressed: () =>
                    _showDeleteDialog(context, transaction, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Transaction transaction,
      TransactionProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => context.pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              context.pop();
              final success = await provider.deleteTransaction(transaction.id);
              if (context.mounted && !success) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: const Text('Failed to delete transaction.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                );
                provider.fetchTransactions();
              }
            },
          ),
        ],
      ),
    );
  }
}
