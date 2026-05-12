import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Data models – swap these out for real API calls later
// ---------------------------------------------------------------------------

class ReportData {
  final int omset;
  final int pengeluaran;
  final int laba;
  final int kasMasuk;
  final int kasKeluar;
  final int saldoKas;
  final int piutang;
  final int piutangDibayar;
  final int transaksiDelete;
  final int transaksiCancel;
  final List<BestSellerItem> bestSellers;
  final int totalCustomer;
  final int customerBaru;
  final List<TopCustomerItem> topCustomers;

  const ReportData({
    this.omset = 0,
    this.pengeluaran = 0,
    this.laba = 0,
    this.kasMasuk = 0,
    this.kasKeluar = 0,
    this.saldoKas = 0,
    this.piutang = 0,
    this.piutangDibayar = 0,
    this.transaksiDelete = 0,
    this.transaksiCancel = 0,
    this.bestSellers = const [],
    this.totalCustomer = 0,
    this.customerBaru = 0,
    this.topCustomers = const [],
  });
}

class BestSellerItem {
  final String name;
  final int qty;
  final int total;
  const BestSellerItem({required this.name, required this.qty, required this.total});
}

class TopCustomerItem {
  final String name;
  final int total;
  const TopCustomerItem({required this.name, required this.total});
}

// ---------------------------------------------------------------------------
// Stub "API" – replace each method body with your real fetch logic
// ---------------------------------------------------------------------------

Future<ReportData> fetchReportData({
  required String period, // 'harian' | 'mingguan' | 'bulanan' | 'tahunan'
  required String branch,
  required DateTime date,
}) async {
  // TODO: replace with real API call
  await Future.delayed(const Duration(milliseconds: 400));
  return const ReportData(); // all zeros / empty until API is wired
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReportDetailScreen extends StatefulWidget {
  final String title;
  final String description;

  const ReportDetailScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF8B2E6E);

  late TabController _tabController;

  final List<String> _tabs = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
  final List<String> _periods = ['harian', 'mingguan', 'bulanan', 'tahunan'];

  String _selectedBranch = 'Semua Cabang';
  // For simplicity the branch list is hardcoded – swap with real data later
  final List<String> _branches = ['Semua Cabang'];

  DateTime _selectedDate = DateTime.now();

  ReportData? _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) _loadData();
      });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await fetchReportData(
        period: _periods[_tabController.index],
        branch: _selectedBranch,
        date: _selectedDate,
      );
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date display helpers ──────────────────────────────────────────────────

  String get _dateLabel {
    switch (_tabController.index) {
      case 0: // Harian
        return DateFormat('d MMM yyyy', 'id').format(_selectedDate);
      case 1: // Mingguan – show the week range
        final startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'id').format(startOfWeek)} – '
            '${DateFormat('d MMM yyyy', 'id').format(endOfWeek)}';
      case 2: // Bulanan
        return DateFormat('MMMM yyyy', 'id').format(_selectedDate);
      case 3: // Tahunan
        return _selectedDate.year.toString();
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final idx = _tabController.index;
    if (idx == 3) {
      // Year picker via simple dialog
      final year = await _showYearPicker();
      if (year != null) {
        setState(() => _selectedDate = DateTime(year));
        _loadData();
      }
      return;
    }
    if (idx == 2) {
      // Month picker
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: 'Pilih Bulan',
      );
      if (picked != null) {
        setState(() => _selectedDate = DateTime(picked.year, picked.month));
        _loadData();
      }
      return;
    }
    // Daily / weekly – single date picker
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  Future<int?> _showYearPicker() async {
    final currentYear = DateTime.now().year;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Tahun'),
          content: SizedBox(
            width: 200,
            height: 300,
            child: ListView.builder(
              itemCount: currentYear - 2019,
              itemBuilder: (_, i) {
                final year = currentYear - i;
                return ListTile(
                  title: Text(year.toString()),
                  selected: year == _selectedDate.year,
                  selectedColor: _primaryColor,
                  onTap: () => Navigator.pop(ctx, year),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Formatting ────────────────────────────────────────────────────────────

  String _fmt(int amount) {
    final f = NumberFormat('#,##0', 'id');
    return 'Rp. ${f.format(amount).replaceAll(',', '.')}';
  }

  // ── Download stub ─────────────────────────────────────────────────────────

  void _onDownload() {
    // TODO: implement PDF / Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur download akan segera tersedia')),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _onDownload,
            tooltip: 'Download',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Branch dropdown
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBranch,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _branches
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedBranch = v);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Date chip
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    _dateLabel,
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildOmsetCard(),
                        const SizedBox(height: 12),
                        _buildKasCard(),
                        const SizedBox(height: 12),
                        _buildSingleCard(
                          label: 'Piutang',
                          value: _fmt(_data?.piutang ?? 0),
                          onDetail: () => _onCardDetail('Piutang'),
                        ),
                        const SizedBox(height: 12),
                        _buildSingleCard(
                          label: 'Piutang Dibayar',
                          value: _fmt(_data?.piutangDibayar ?? 0),
                          onDetail: () => _onCardDetail('Piutang Dibayar'),
                        ),
                        const SizedBox(height: 12),
                        _buildTransaksiCard(),
                        const SizedBox(height: 12),
                        _buildBestSellerCard(),
                        const SizedBox(height: 12),
                        _buildCustomerCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Card builders ─────────────────────────────────────────────────────────

  Widget _buildOmsetCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Omset',
                  value: _fmt(_data?.omset ?? 0),
                ),
              ),
              Expanded(
                child: _metricTile(
                  label: 'Pengeluaran',
                  value: _fmt(_data?.pengeluaran ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile(label: 'Laba', value: _fmt(_data?.laba ?? 0)),
              _detailButton(() => _onCardDetail('Laba Rugi')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKasCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Kas Masuk',
                  value: _fmt(_data?.kasMasuk ?? 0),
                ),
              ),
              Expanded(
                child: _metricTile(
                  label: 'Kas Keluar',
                  value: _fmt(_data?.kasKeluar ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile(
                  label: 'Saldo Kas', value: _fmt(_data?.saldoKas ?? 0)),
              _detailButton(() => _onCardDetail('Kas')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Transaksi Delete',
                  value: _fmt(_data?.transaksiDelete ?? 0),
                ),
              ),
              Expanded(
                child: _metricTile(
                  label: 'Transaksi Cancel',
                  value: _fmt(_data?.transaksiCancel ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: _detailButton(() => _onCardDetail('Transaksi')),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleCard({
    required String label,
    required String value,
    required VoidCallback onDetail,
  }) {
    return _card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _metricTile(label: label, value: value),
          _detailButton(onDetail),
        ],
      ),
    );
  }

  Widget _buildBestSellerCard() {
    final items = _data?.bestSellers ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Seller',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Data tidak ada',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name),
                    Text('${item.qty}x · ${_fmt(item.total)}',
                        style: const TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final topCustomers = _data?.topCustomers ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Total Customer',
                  value: (_data?.totalCustomer ?? 0).toString(),
                ),
              ),
              Expanded(
                child: _metricTile(
                  label: 'Customer Baru',
                  value: (_data?.customerBaru ?? 0).toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Customer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (topCustomers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Data tidak ada',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            )
          else
            ...topCustomers.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.name),
                    Text(_fmt(c.total),
                        style: const TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared small widgets ──────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _metricTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }

  Widget _detailButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.open_in_new, size: 20, color: Colors.black54),
      ),
    );
  }

  // ── Navigation stub ───────────────────────────────────────────────────────

  void _onCardDetail(String section) {
    // TODO: navigate to the specific detail screen for [section]
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detail: $section')),
    );
  }
}