import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../utils/category_utils.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('All Transactions'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.refresh),
                onPressed: () => provider.fetchTransactions(),
              ),
            ),
            child: SafeArea(
              child: provider.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    )
                  : _buildTransactionListView(context, provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionListView(
      BuildContext context, TransactionProvider provider) {
    if (provider.transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found.',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.placeholderText,
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      child: ListView.separated(
        itemCount: provider.transactions.length,
        separatorBuilder: (context, index) => Container(
          height: 0.5,
          margin: const EdgeInsets.only(left: 68),
          color: CupertinoColors.separator,
        ),
        itemBuilder: (ctx, index) {
          final transaction = provider.transactions[index];
          return _buildTransactionTile(context, transaction, provider);
        },
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction,
      TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 图标容器
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: transaction.type == 'expense'
                  ? CupertinoColors.systemRed.withOpacity(0.1)
                  : CupertinoColors.systemGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CategoryUtils.getCategoryIcon(transaction.categoryKey),
              color: transaction.type == 'expense'
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGreen,
              size: 18,
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
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, y').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          // 金额
          Text(
            '${transaction.type == 'expense' ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: transaction.type == 'expense'
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGreen,
            ),
          ),
          const SizedBox(width: 8),
          // 删除按钮
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            minSize: 0,
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.destructiveRed,
              size: 18,
            ),
            onPressed: () => _showDeleteDialog(context, transaction, provider),
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
