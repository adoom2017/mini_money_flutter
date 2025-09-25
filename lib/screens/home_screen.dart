import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_calendar.dart';
import '../widgets/bar_chart.dart';
import '../widgets/pie_chart.dart';
import '../models/transaction.dart';
import '../api/api_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum ChartView { expense, income }

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _selectedDayTransactions = [];
  final ApiService _apiService = ApiService();
  ChartView _chartView = ChartView.expense;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HomeProvider>(context, listen: false);
      provider.fetchData().then((_) {
        _fetchTransactionsForDay(DateTime.now());
      });
    });
  }

  Future<void> _fetchTransactionsForDay(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final response = await _apiService.getTransactions(d: dateStr);
    if (response.statusCode == 200 && mounted) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _selectedDayTransactions =
            data.map((item) => Transaction.fromJson(item)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(),
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchData(),
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.fetchData(),
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildSummaryCards(provider),
                        const SizedBox(height: 24),
                        const Text('Daily Summary',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        DailyBarChart(transactions: provider.transactions),
                        const SizedBox(height: 24),
                        const Text('Category Breakdown',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        _buildPieChartToggle(),
                        CategoryPieChart(
                          categoryStats: _chartView == ChartView.expense
                              ? provider.expenseStats
                              : provider.incomeStats,
                        ),
                        const SizedBox(height: 24),
                        const Text('Monthly Transactions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 500,
                          child: HomeCalendar(
                            transactions: provider.transactions,
                            onDaySelected: _fetchTransactionsForDay,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Selected Day Transactions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        _buildTransactionList(_selectedDayTransactions),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPieChartToggle() {
    return Center(
      child: SegmentedButton<ChartView>(
        segments: const <ButtonSegment<ChartView>>[
          ButtonSegment<ChartView>(
              value: ChartView.expense, label: Text('Expense')),
          ButtonSegment<ChartView>(
              value: ChartView.income, label: Text('Income')),
        ],
        selected: <ChartView>{_chartView},
        onSelectionChanged: (Set<ChartView> newSelection) {
          setState(() {
            _chartView = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildSummaryCards(HomeProvider provider) {
    final summary = provider.summary;
    if (summary == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryCard('Expense', summary.totalExpense, Colors.red),
        _buildSummaryCard('Income', summary.totalIncome, Colors.green),
        _buildSummaryCard('Balance', summary.balance, Colors.blue),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(amount.toStringAsFixed(2),
                style: TextStyle(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No transactions for this day.')));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          title: Text(transaction.description.isEmpty
              ? transaction.categoryKey
              : transaction.description),
          subtitle: Text(transaction.categoryKey),
          trailing: Text(
            '${transaction.type == 'expense' ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
                color:
                    transaction.type == 'expense' ? Colors.red : Colors.green),
          ),
        );
      },
    );
  }
}
