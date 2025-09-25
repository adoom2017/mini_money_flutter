import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('All Transactions'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchTransactions(),
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTransactionListView(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildTransactionListView(BuildContext context, TransactionProvider provider) {
    if (provider.transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = provider.transactions[index];
        return Dismissible(
          key: ValueKey(transaction.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) async {
            final success = await provider.deleteTransaction(transaction.id);
            if (context.mounted && !success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete transaction.')),
              );
              // Optionally, re-fetch to restore the item visually
              provider.fetchTransactions();
            }
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildTransactionTile(transaction),
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final amountStyle = TextStyle(
      color: isExpense ? Colors.red : Colors.green,
      fontWeight: FontWeight.bold,
    );
    final amountString = '${isExpense ? '-' : '+'}${NumberFormat.currency(symbol: '¥').format(transaction.amount)}';

    return ListTile(
      leading: const Icon(Icons.category), // Placeholder, ideally we'd have category icons
      title: Text(transaction.description.isEmpty ? transaction.categoryKey : transaction.description),
      subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
      trailing: Text(amountString, style: amountStyle),
    );
  }
}
