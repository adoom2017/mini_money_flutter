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
            backgroundColor: const Color(0xFFF8F9FA),
            navigationBar: CupertinoNavigationBar(
              backgroundColor:
                  CupertinoColors.systemBackground.withOpacity(0.8),
              middle: const Text(
                '我的资产',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minSize: 0,
                  child: const Icon(
                    CupertinoIcons.refresh,
                    color: Color(0xFF1976D2),
                    size: 18,
                  ),
                  onPressed: () => provider.fetchData(),
                ),
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
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1976D2),
                                  Color(0xFF1565C0),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: FloatingActionButton(
                              onPressed: () =>
                                  _showAddAssetDialog(context, provider),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const CircleBorder(),
                              child: const Icon(Icons.add, size: 28),
                            ),
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
      return Column(
        children: [
          // 固定的总览部分
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSummaryCard(context, provider),
          ),
          // 空状态展示
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar_circle,
                      size: 60,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '暂无资产',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击右下角的 + 按钮开始添加您的第一个资产',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.placeholderText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 固定的总览部分
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildSummaryCard(context, provider),
        ),
        const SizedBox(height: 24),
        // 资产列表标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                size: 20,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 8),
              const Text(
                '我的资产',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${provider.assets.length} 项',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.placeholderText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 可滚动的资产列表部分
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: provider.assets.length,
            itemBuilder: (context, index) {
              final asset = provider.assets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAssetTile(context, provider, asset),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, AssetProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_pie,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '净资产',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '总览',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              NumberFormat.currency(symbol: '¥').format(provider.netWorth),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up,
                                color: CupertinoColors.systemGreen,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '资产',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(symbol: '¥')
                              .format(provider.totalAssets),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                    CupertinoColors.systemRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_down,
                                color: CupertinoColors.systemRed,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '负债',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(symbol: '¥')
                              .format(provider.totalLiabilities),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
    );
  }

  Widget _buildAssetTile(
      BuildContext context, AssetProvider provider, Asset asset) {
    final category = provider.getCategoryById(asset.categoryId);
    final isAsset = category?.type == 'asset';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Dismissible(
        key: Key(asset.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // 显示确认对话框
          return await showCupertinoDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: const Text('删除资产'),
                    content: Text('确定要删除资产 "${asset.name}" 吗？此操作无法撤销。'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('取消'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('删除'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        },
        onDismissed: (direction) async {
          // 执行删除操作
          final success = await provider.deleteAsset(asset.id);
          if (!success) {
            // 删除失败，显示错误消息
            if (context.mounted) {
              // 检查widget是否仍然mounted
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: const Text('删除失败'),
                    content: const Text('无法删除该资产，请稍后再试。'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('确定'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            }
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CupertinoColors.systemRed, Color(0xFFE53E3E)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.white,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                '删除',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.separator.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => AssetDetailScreen(asset: asset),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 资产图标
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAsset
                              ? [
                                  CupertinoColors.systemGreen.withOpacity(0.8),
                                  CupertinoColors.systemGreen,
                                ]
                              : [
                                  CupertinoColors.systemRed.withOpacity(0.8),
                                  CupertinoColors.systemRed,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAsset
                            ? CupertinoIcons.arrow_up_circle_fill
                            : CupertinoIcons.arrow_down_circle_fill,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 资产信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAsset
                                  ? CupertinoColors.systemGreen.withOpacity(0.1)
                                  : CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isAsset
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 金额和操作按钮
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '¥')
                              .format(asset.latestAmount),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAsset
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minSize: 0,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.add,
                                  size: 16,
                                  color: Color(0xFF1976D2),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '记录',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () =>
                                _showAddRecordDialog(context, provider, asset),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context, AssetProvider provider) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => _AddAssetPage(provider: provider),
        fullscreenDialog: true,
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

class _AddAssetPage extends StatefulWidget {
  final AssetProvider provider;

  const _AddAssetPage({required this.provider});

  @override
  State<_AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<_AddAssetPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedCategoryId = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _selectedCategoryName {
    if (_selectedCategoryId.isEmpty) return '';
    final category = widget.provider.getCategoryById(_selectedCategoryId);
    return category?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('添加资产'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : const Text('保存'),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // 资产名称输入
              const Text(
                '资产名称',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: '请输入资产名称',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  border: Border.all(color: CupertinoColors.separator),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 24),

              // 分类选择
              const Text(
                '资产分类',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    border: Border.all(color: CupertinoColors.separator),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryName.isEmpty
                            ? '请选择资产分类'
                            : _selectedCategoryName,
                        style: TextStyle(
                          fontSize: 17,
                          color: _selectedCategoryName.isEmpty
                              ? CupertinoColors.placeholderText
                              : CupertinoColors.label,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.forward,
                        color: CupertinoColors.placeholderText,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 帮助信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: CupertinoColors.systemBlue,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '添加资产后，您可以记录该资产的变动情况',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemBlue,
                        ),
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

  void _showCategoryPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('选择资产分类'),
        message: const Text('请选择适合的资产分类'),
        actions: widget.provider.categories.map((category) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedCategoryId = category.id.toString();
              });
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.name),
                if (category.type == 'asset')
                  const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: CupertinoColors.systemGreen,
                    size: 16,
                  )
                else
                  const Icon(
                    CupertinoIcons.arrow_down_circle_fill,
                    color: CupertinoColors.systemRed,
                    size: 16,
                  ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _handleSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('请输入资产名称');
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      _showErrorDialog('请选择资产分类');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success =
        await widget.provider.createAsset(name, _selectedCategoryId);

    if (mounted) {
      // 检查widget是否仍然mounted
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pop();
      } else {
        _showErrorDialog('添加资产失败，请稍后重试');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
