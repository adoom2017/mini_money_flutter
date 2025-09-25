import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../models/asset.dart';
import 'package:intl/intl.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssetProvider(),
      child: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Assets'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchData(),
                )
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAssetList(context, provider),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddAssetDialog(context, provider),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetList(BuildContext context, AssetProvider provider) {
    if (provider.assets.isEmpty && !provider.isLoading) {
      return const Center(child: Text('No assets yet. Tap + to add one!'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding for FAB
      children: [
        _buildSummaryCard(context, provider),
        const SizedBox(height: 16),
        ...provider.assets
            .map((asset) => _buildAssetTile(context, provider, asset)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, AssetProvider provider) {
    final currencyFormat = NumberFormat.currency(symbol: '¥');
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Net Worth', style: Theme.of(context).textTheme.titleMedium),
            Text(currencyFormat.format(provider.netWorth),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Assets'),
                    Text(currencyFormat.format(provider.totalAssets),
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Total Liabilities'),
                    Text(currencyFormat.format(provider.totalLiabilities),
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTile(
      BuildContext context, AssetProvider provider, Asset asset) {
    final category = provider.getCategoryById(asset.categoryId);
    final currencyFormat = NumberFormat.currency(symbol: '¥');
    return Card(
      child: ListTile(
        leading:
            Text(category?.icon ?? '❓', style: const TextStyle(fontSize: 24)),
        title: Text(asset.name),
        subtitle: Text(category?.name ?? 'Uncategorized'),
        trailing: Text(currencyFormat.format(asset.latestAmount)),
        onTap: () => _showAddRecordDialog(context, provider, asset),
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context, AssetProvider provider) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Asset'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Asset Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name.' : null,
                onSaved: (value) => name = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: provider.categories
                    .map((cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)))
                    .toList(),
                onChanged: (value) => selectedCategoryId = value,
                validator: (value) =>
                    value == null ? 'Please select a category.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success =
                    await provider.createAsset(name, selectedCategoryId!);
                Navigator.of(ctx).pop();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add asset.')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog(
      BuildContext context, AssetProvider provider, Asset asset) {
    final formKey = GlobalKey<FormState>();
    double amount = asset.latestAmount;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Record for ${asset.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Amount'),
            initialValue: amount.toString(),
            keyboardType: TextInputType.number,
            validator: (value) =>
                value!.isEmpty ? 'Please enter an amount.' : null,
            onSaved: (value) => amount = double.parse(value!),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await provider.createAssetRecord(
                    asset.id, selectedDate, amount);
                Navigator.of(ctx).pop();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add record.')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
