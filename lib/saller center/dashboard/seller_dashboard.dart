import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String _selectedFilter = "All Time";
  final List<String> _filters = ["All Time", "Today", "This Week", "This Month", "This Year"];

  DateTime? _getStartDate() {
    DateTime now = DateTime.now();
    switch (_selectedFilter) {
      case "Today": return DateTime(now.year, now.month, now.day);
      case "This Week": return now.subtract(Duration(days: now.weekday - 1));
      case "This Month": return DateTime(now.year, now.month, 1);
      case "This Year": return DateTime(now.year, 1, 1);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DateTime? startDate = _getStartDate();

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FF),
      appBar: AppBar(
        title: const Text("Business Overview", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                double earned = 0, pendingM = 0, procM = 0, shipM = 0, cancM = 0, retM = 0, totalV = 0;
                int comp = 0, pend = 0, proc = 0, ship = 0, canc = 0, ret = 0;

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  double price = (data['totalPrice'] ?? 0).toDouble();
                  String status = (data['status'] ?? "").toString().toLowerCase();
                  totalV += price;

                  if (status == "completed") { earned += price; comp++; }
                  else if (status == "pending") { pendingM += price; pend++; }
                  else if (status == "in process") { procM += price; proc++; }
                  else if (status == "shipped") { shipM += price; ship++; }
                  else if (status == "cancelled") { cancM += price; canc++; }
                  else if (status == "returned") { retM += price; ret++; }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRevenueCard(earned, totalV),
                      const SizedBox(height: 24),
                      const Text("Performance Grid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildStatsGrid(comp, proc, pend, ship, ret, canc),
                      const SizedBox(height: 24),
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TabBar(
                              labelColor: Colors.green,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.green,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: [
                                Tab(text: "Money Distribution"),
                                Tab(text: "Order Volume"),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 480, // Increased height to prevent overflow with expanded list
                              child: TabBarView(
                                children: [
                                  _buildMoneyPieChart(totalV, earned, procM, pendingM, shipM, retM, cancM, comp, proc, pend, ship, ret, canc),
                                  _buildOrderVolumeChart(comp, ship, proc, pend, canc, ret),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildRecentActivity(snapshot.data!.docs),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 70,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == _filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedFilter = _filters[index]),
              selectedColor: Colors.green,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard(double earned, double volume) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xff1B5E20), Color(0xff43A047)], begin: Alignment.topLeft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("NET EARNINGS", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
          Text("PKR ${NumberFormat('#,###').format(earned)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mini("Gross Volume", "PKR ${NumberFormat('#,###').format(volume)}"),
              _mini("Period", _selectedFilter),
            ],
          )
        ],
      ),
    );
  }

  Widget _mini(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
  ]);

  Widget _buildStatsGrid(int comp, int proc, int pend, int ship, int ret, int canc) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statItem("Completed", comp, Colors.green, Icons.check_circle),
        _statItem("Shipped", ship, Colors.indigo, Icons.local_shipping),
        _statItem("Processing", proc, Colors.purple, Icons.sync),
        _statItem("Pending", pend, Colors.blue, Icons.hourglass_top),
        _statItem("Cancelled", canc, Colors.red, Icons.cancel),
        _statItem("Returned", ret, Colors.orange, Icons.assignment_return),
      ],
    );
  }

  Widget _statItem(String l, int v, Color c, IconData i) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, color: c, size: 18),
      const Spacer(),
      Text(v.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]),
  );

  // --- UPDATED PIE CHART WITH PERCENTAGES ---
  Widget _buildMoneyPieChart(double total, double e, double pr, double pe, double sh, double r, double ca, int ec, int prc, int pec, int shc, int rc, int cac) {
    // Helper to calculate percent
    String getPerc(double val) {
      if (total == 0) return "0%";
      return "${((val / total) * 100).toStringAsFixed(1)}%";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(
              centerSpaceRadius: 35,
              sectionsSpace: 2,
              sections: [
                _pieSection(e, Colors.green, getPerc(e)),
                _pieSection(sh, Colors.indigo, getPerc(sh)),
                _pieSection(pr, Colors.purple, getPerc(pr)),
                _pieSection(pe, Colors.blue, getPerc(pe)),
                _pieSection(ca, Colors.red, getPerc(ca)),
                _pieSection(r, Colors.orange, getPerc(r)),
              ],
            )),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _leg("Earned", Colors.green, e, ec, getPerc(e)),
                _leg("Shipped", Colors.indigo, sh, shc, getPerc(sh)),
                _leg("Processing", Colors.purple, pr, prc, getPerc(pr)),
                _leg("Pending", Colors.blue, pe, pec, getPerc(pe)),
                _leg("Cancelled", Colors.red, ca, cac, getPerc(ca)),
                _leg("Returned", Colors.orange, r, rc, getPerc(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(double val, Color color, String perc) {
    return PieChartSectionData(
      value: val > 0 ? val : 0.001, // Small value to keep slice valid if zero
      color: color,
      radius: 50,
      showTitle: val > 0, // Only show title if there is a value
      title: perc,
      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _leg(String l, Color c, double a, int n, String p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(l, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text("($p)", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      const Spacer(),
      Text("PKR ${a.toInt()} ($n)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  Widget _buildOrderVolumeChart(int comp, int ship, int proc, int pend, int canc, int ret) {
    int maxVal = [comp, ship, proc, pend, canc, ret].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Volume by Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal == 0 ? 10 : maxVal.toDouble() + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String status = ["Comp", "Ship", "Proc", "Pend", "Canc", "Ret"][rodIndex];
                      return BarTooltipItem("$status: ${rod.toY.toInt()}", const TextStyle(color: Colors.white));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => const Padding(padding: EdgeInsets.only(top: 8), child: Text("Overview", style: TextStyle(fontSize: 10, color: Colors.grey))))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      _barRod(comp.toDouble(), Colors.green),
                      _barRod(ship.toDouble(), Colors.indigo),
                      _barRod(proc.toDouble(), Colors.purple),
                      _barRod(pend.toDouble(), Colors.blue),
                      _barRod(canc.toDouble(), Colors.red),
                      _barRod(ret.toDouble(), Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 8, alignment: WrapAlignment.center,
            children: [
              _chartLegend("Completed", Colors.green),
              _chartLegend("Shipped", Colors.indigo),
              _chartLegend("Processing", Colors.purple),
              _chartLegend("Pending", Colors.blue),
              _chartLegend("Cancelled", Colors.red),
              _chartLegend("Returned", Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  BarChartRodData _barRod(double y, Color color) => BarChartRodData(
    toY: y, color: color, width: 14,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );

  Widget _chartLegend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildRecentActivity(List<QueryDocumentSnapshot> docs) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length > 5 ? 5 : docs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          var data = docs[index].data() as Map<String, dynamic>;
          String status = data['status'] ?? "Pending";
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text("Order #${docs[index].id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
            trailing: Text("PKR ${data['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch(s.toLowerCase()) {
      case "completed": return Colors.green;
      case "shipped": return Colors.indigo;
      case "in process": return Colors.purple;
      case "cancelled": return Colors.red;
      case "returned": return Colors.orange;
      default: return Colors.blue;
    }
  }

  Widget _buildEmptyState() => const SizedBox(height: 300, child: Center(child: Text("No Orders Found in this period", style: TextStyle(color: Colors.grey))));
}