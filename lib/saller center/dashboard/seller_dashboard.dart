import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:zrai_mart/app_colors.dart';

import '../../Notification/Notification.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = "All Time";
  final List<String> _filters = [
    "All Time",
    "Today",
    "This Week",
    "This Month",
    "This Year"
  ];

  double balance = 0,
      totalEarning = 0,
      onHold = 0,
      totalWithdrawn = 0,
      pendingWithdrawal = 0;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  late Stream<QuerySnapshot> _orderStream;

  @override
  void initState() {
    super.initState();
    _fetchSellerWallet();
    _updateStream(); // 2. Initialize the stream
  }

  // 3. Create a function to build the stream based on current filters
  void _updateStream() {
    DateTime? startDate = _getStartDate();
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    // Store the snapshots stream so it doesn't reset on every build
    _orderStream = query.snapshots();
  }

  // 4. Update the filter bar to refresh the stream properly



  Future<void> _fetchSellerWallet() async {
    final doc =
        await FirebaseFirestore.instance.collection('saller').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        balance = (data['balance'] ?? 0).toDouble();
        totalEarning = (data['totalEarnings'] ?? 0).toDouble();
        onHold = (data['onHold'] ?? 0).toDouble();
        totalWithdrawn = (data['totalWithdrawn'] ?? 0).toDouble();
        pendingWithdrawal = (data['pendingWithdrawal'] ?? 0).toDouble();
      });
    }
  }

  DateTime? _getStartDate() {
    DateTime now = DateTime.now();
    switch (_selectedFilter) {
      case "Today":
        return DateTime(now.year, now.month, now.day);
      case "This Week":
        return now.subtract(Duration(days: now.weekday - 1));
      case "This Month":
        return DateTime(now.year, now.month, 1);
      case "This Year":
        return DateTime(now.year, 1, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xffF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Dashboard",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>UniversalNotificationScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid, userRole: 'seller',)));
              },
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Colors.black)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          // 2. Re-fetch the wallet balance manually
          await _fetchSellerWallet();

          // 3. Small delay to make the animation feel smooth
          await Future.delayed(const Duration(milliseconds: 500));

          // 4. Force a rebuild of the stream by calling setState
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _orderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xff2D31FA)));
            }

            double earned = 0;
            double shipAmt = 0;
            double procAmt = 0;
            double pendAmt = 0;
            double retAmt = 0;
            double cancAmt = 0;
            double totalV = 0;

            int comp = 0, proc = 0, pend = 0, ship = 0, ret = 0, canc = 0;

            for (var doc in snapshot.data?.docs ?? []) {
              var data = doc.data() as Map<String, dynamic>;
              double price = (data['totalPrice'] ?? 0).toDouble();
              String status = (data['status'] ?? "").toString().toLowerCase();

              totalV += price;

              if (status == "completed") {
                earned += price;
                comp++;
              } else if (status == "shipped") {
                shipAmt += price;
                ship++;
              } else if (status == "in process") {
                procAmt += price;
                proc++;
              } else if (status == "pending") {
                pendAmt += price;
                pend++;
              } else if (status == "returned") {
                retAmt += price;
                ret++;
              } else if (status == "cancelled") {
                cancAmt += price;
                canc++;
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildMainWalletCard()),
                SliverToBoxAdapter(child: _buildFilterBar()),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Net Earning", "PKR ${earned.toInt()}",
                          Icons.account_balance_wallet, Colors.green),
                      _buildStatCard(
                          "Total Orders",
                          snapshot.data?.docs.length.toString() ?? "0",
                          Icons.shopping_cart,
                          Colors.blue),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Text("Performance Overview",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 3, // Maintains the clean 3-column look
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _miniGridItem("Completed", comp, Colors.green),
                      _miniGridItem("Shipped", ship, Colors.indigo),
                      _miniGridItem("Processing", proc, Colors.purple),
                      _miniGridItem("Pending", pend, Colors.blue),
                      _miniGridItem("Returned", ret, Colors.orange),
                      _miniGridItem("Cancelled", canc, Colors.red),
                    ],
                  ),
                ),
                // ... inside CustomScrollView
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Text("Analytics",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Color(0xff2D31FA),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xff2D31FA),
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(text: "Revenue Split"),
                            Tab(text: "Order Volume"),
                          ],
                        ),
                        SizedBox(
                          height: 350, // Height for the charts
                          child: TabBarView(
                            children: [
                              _buildModernPieChart(
                                earned,
                                procAmt,
                                pendAmt,
                                shipAmt,
                                retAmt,
                                cancAmt,
                                totalV,
                              ),
                              _buildModernBarChart(
                                  comp, ship, proc, pend, canc, ret),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        // ...
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Text("Recent Sales Activity",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildOrderTile(snapshot.data!.docs[index]),
                    childCount: (snapshot.data?.docs.length ?? 0) > 5
                        ? 5
                        : snapshot.data?.docs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernPieChart(double e, double pr, double pe, double sh,
      double r, double ca, double total) {
    double chartTotal = e + pr + pe + sh + r + ca;

    const colorEarned = Color(0xFF2DD4BF);
    const colorShipped = Color(0xFF6366F1);
    const colorProcess = Color(0xFF8B5CF6);
    const colorPending = Color(0xFF3B82F6);
    const colorReturned = Color(0xFFF59E0B);
    const colorCancelled = Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // We use a clip behavior to ensure the scrolling content doesn't bleed out of rounded corners
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView( // 🛠️ FIX: Wrap content in a scroll view
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allow the column to be as small as its children
          children: [
            const Text(
              "Revenue Analytics",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 220, // High-impact height preserved
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 5,
                      centerSpaceRadius: 85,
                      startDegreeOffset: -90,
                      sections: [
                        _slice(e, colorEarned, chartTotal),
                        _slice(sh, colorShipped, chartTotal),
                        _slice(pr, colorProcess, chartTotal),
                        _slice(pe, colorPending, chartTotal),
                        _slice(r, colorReturned, chartTotal),
                        _slice(ca, colorCancelled, chartTotal),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TOTAL REVENUE",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "PKR ${chartTotal > 1000 ? '${(chartTotal / 1000).toStringAsFixed(1)}k' : chartTotal.toInt()}",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Legend Grid
            GridView.count(
              shrinkWrap: true, // 🛠️ CRITICAL: Tells GridView not to take infinite height
              physics: const NeverScrollableScrollPhysics(), // Grid doesn't scroll, the Container does
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              children: [
                _modernLegend("Earned", colorEarned, e, chartTotal),
                _modernLegend("Shipped", colorShipped, sh, chartTotal),
                _modernLegend("Process", colorProcess, pr, chartTotal),
                _modernLegend("Pending", colorPending, pe, chartTotal),
                _modernLegend("Returned", colorReturned, r, chartTotal),
                _modernLegend("Cancelled", colorCancelled, ca, chartTotal),
              ],
            ),
          ],
        ),
      ),
    );
  }


  PieChartSectionData _slice(double val, Color color, double total) {
    if (val <= 0) {
      return PieChartSectionData(value: 0, showTitle: false, radius: 0);
    }

    double visualValue = val;
    if (total > 0 && (val / total) < 0.03) {
      visualValue = total * 0.03;
    }

    return PieChartSectionData(
      value: visualValue,
      color: color,
      radius: 22,
      showTitle: true,

      // ✅ SHOW ACTUAL VALUE ONLY
      title: val >= 1000
          ? "${(val / 1000).toStringAsFixed(1)}k"
          : val.toInt().toString(),

      titleStyle: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titlePositionPercentageOffset: 0.5,
    );
  }

  Widget _modernLegend(String label, Color color, double val, double total) {
    if (val <= 0) return const SizedBox.shrink();

    final double percentage = total > 0 ? (val / total) * 100 : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),

            Text(
              "PKR ${val.toInt()} (${percentage.toStringAsFixed(1)}%)",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Text("No data available for the selected period"));
  }

  Widget _buildModernBarChart(
      int comp, int ship, int proc, int pend, int canc, int ret) {
    final List<int> values = [comp, ship, proc, pend, canc, ret];
    int maxVal = values.reduce((a, b) => a > b ? a : b);

    // 🔥 Adjusted multiplier to 1.4 to keep numbers well within the new height
    double chartMaxY = maxVal == 0 ? 10 : (maxVal * 1.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Volume",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 25),
          SizedBox(
            height: 240, // 🚀 Increased from 180 to 210 for a taller look
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 6, // Slightly more space for the label
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toInt().toString(),
                        TextStyle(
                          color: rod.color?.withOpacity(0.85),
                          fontWeight: FontWeight.bold,
                          fontSize:
                              12, // Slightly larger font to match taller height
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          30, // Increased to prevent bottom label clipping
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600);
                        switch (value.toInt()) {
                          case 0:
                            return const Text('COM', style: style);
                          case 1:
                            return const Text('SHI', style: style);
                          case 2:
                            return const Text('PRO', style: style);
                          case 3:
                            return const Text('PEN', style: style);
                          case 4:
                            return const Text('RET', style: style);
                          case 5:
                            return const Text('CAN', style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _group(0, comp.toDouble(), Colors.green, chartMaxY),
                  _group(1, ship.toDouble(), Colors.indigo, chartMaxY),
                  _group(2, proc.toDouble(), Colors.purple, chartMaxY),
                  _group(3, pend.toDouble(), Colors.blue, chartMaxY),
                  _group(4, ret.toDouble(), Colors.orange, chartMaxY),
                  _group(5, canc.toDouble(), Colors.red, chartMaxY),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _group(int x, double y, Color color, double totalMax) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: totalMax,
            color: const Color(0xffF4F7FA),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  Widget _buildMainWalletCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2D31FA), Color(0xff5D8BF4)],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xff2D31FA).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
              "PKR ${NumberFormat('#,###.00').format(balance == 0 ? 0 : balance)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _walletSubDetail("Total Earned", totalEarning),
              _walletSubDetail("On Hold", onHold),
              _walletSubDetail("Withdrawn", totalWithdrawn),
            ],
          )
        ],
      ),
    );
  }

  Widget _walletSubDetail(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text("PKR ${amount.toInt()}",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(

        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == _filters[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = _filters[index];
                _updateStream(); // Re-generates the Firestore query
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5)
                      ],
              ),
              child: Center(
                child: Text(_filters[index],
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ]),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                FittedBox(
                    child: Text(val,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _miniGridItem(String label, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String productId = data['productId'] ?? ""; // Fetch product ID from order

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get(),
        builder: (context, prodSnap) {
          String name = "Order #${doc.id.substring(0, 5).toUpperCase()}";
          String img = "";

          if (prodSnap.hasData && prodSnap.data!.exists) {
            var pData = prodSnap.data!.data() as Map<String, dynamic>;
            name = pData['name'] ?? name;
            img = pData['image'] ?? "";
          }

          return Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  image: img.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(img), fit: BoxFit.cover)
                      : null,
                ),
                child: img.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color:
                              _getStatusColor(data['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(data['status'].toString().toUpperCase(),
                          style: TextStyle(
                              color: _getStatusColor(data['status']),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("PKR ${data['totalPrice']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2D31FA))),
                  Text(
                      data['timestamp'] != null
                          ? DateFormat('dd MMM')
                              .format((data['timestamp'] as Timestamp).toDate())
                          : "",
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? s) {
    switch (s?.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "shipped":
        return Colors.indigo;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
