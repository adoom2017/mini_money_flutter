import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../models/asset.dart';
import 'package:intl/intl.dart';
import 'asset_detail_screen.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssetProvider(),
      child: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Assets'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.refresh),
                onPressed: () => provider.fetchData(),
              ),
            ),
            child: SafeArea(
              child: provider.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    )
                  : Stack(
                      children: [
                        _buildAssetList(context, provider),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: FloatingActionButton(
                            onPressed: () =>
                                _showAddAssetDialog(context, provider),
                            backgroundColor: const Color(0xFF1976D2), // 更亮的蓝色
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: const CircleBorder(), // 明确设置为圆形
                            child: const Icon(Icons.add, size: 28),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetList(BuildContext context, AssetProvider provider) {
    if (provider.assets.isEmpty && !provider.isLoading) {
      return const Center(
        child: Text(
          'No assets yet. Tap + to add one!',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.placeholderText,
          ),
        ),
      );
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
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Net Worth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '¥').format(provider.netWorth),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text(
                    'Assets',
                    style: TextStyle(color: CupertinoColors.placeholderText),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '¥')
                        .format(provider.totalAssets),
                    style: const TextStyle(
                      color: CupertinoColors.systemGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Liabilities',
                    style: TextStyle(color: CupertinoColors.placeholderText),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '¥')
                        .format(provider.totalLiabilities),
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTile(
      BuildContext context, AssetProvider provider, Asset asset) {
    final category = provider.getCategoryById(asset.categoryId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: CupertinoListTile(
        title: Text(asset.name),
        subtitle: Text(asset.category),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => AssetDetailScreen(asset: asset),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumberFormat.currency(symbol: '¥').format(asset.latestAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: category?.type == 'asset'
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: const Icon(CupertinoIcons.add_circled),
              onPressed: () => _showAddRecordDialog(context, provider, asset),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context, AssetProvider provider) {
    String assetName = '';
    String selectedCategoryId = '';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              placeholder: 'Asset Name',
              onChanged: (value) => assetName = value,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.separator),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  selectedCategoryId.isEmpty
                      ? 'Select Category'
                      : 'Category Selected',
                  style: TextStyle(
                    color: selectedCategoryId.isEmpty
                        ? CupertinoColors.placeholderText
                        : CupertinoColors.label,
                  ),
                ),
                onPressed: () {
                  // Show category picker
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Select Category'),
                      actions: provider.categories
                          .map((category) => CupertinoActionSheetAction(
                                child: Text(category.name),
                                onPressed: () {
                                  selectedCategoryId = category.id.toString();
                                  Navigator.of(context).pop();
                                },
                              ))
                          .toList(),
                      cancelButton: CupertinoActionSheetAction(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Add'),
            onPressed: () async {
              if (assetName.isNotEmpty && selectedCategoryId.isNotEmpty) {
                Navigator.of(context).pop();
                final success =
                    await provider.createAsset(assetName, selectedCategoryId);
                if (!success && context.mounted) {
                  _showErrorDialog(context, 'Failed to add asset.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog(
      BuildContext context, AssetProvider provider, Asset asset) {
    String amount = '';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Add Record for ${asset.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              placeholder: 'Amount',
              keyboardType: TextInputType.number,
              onChanged: (value) => amount = value,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Add'),
            onPressed: () async {
              if (amount.isNotEmpty) {
                Navigator.of(context).pop();
                final success = await provider.createAssetRecord(
                  asset.id.toString(),
                  DateTime.now(),
                  double.tryParse(amount) ?? 0.0,
                );
                if (!success && context.mounted) {
                  _showErrorDialog(context, 'Failed to add record.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
