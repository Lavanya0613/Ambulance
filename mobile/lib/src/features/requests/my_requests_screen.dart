import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'requests_provider.dart';

const Color _kTopGreen = Color(0xFF5BA438);
const Color _kChekupGreen = Color(0xFF5BA438);

const _kStatusMeta = {
  'PENDING':           {'label': 'Pending',            'color': AppColors.secondary, 'bg': AppColors.border,        'icon': Icons.schedule},
  'REQUEST_RECEIVED':  {'label': 'Request Received',    'color': AppColors.secondary, 'bg': AppColors.border,        'icon': Icons.fiber_new},
  'REQUEST_CREATED':   {'label': 'Searching',          'color': AppColors.amber,     'bg': Color(0xFFFEF3C7),       'icon': Icons.search},
  'SEARCHING':         {'label': 'Searching',          'color': AppColors.amber,     'bg': Color(0xFFFEF3C7),       'icon': Icons.search},
  'SEARCHING_DRIVER':  {'label': 'Searching',          'color': AppColors.amber,     'bg': Color(0xFFFEF3C7),       'icon': Icons.search},
  'VENDOR_ACCEPTED':   {'label': 'Accepted',           'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5),       'icon': Icons.thumb_up},
  'DRIVER_ASSIGNED':   {'label': 'Assigned',           'color': Colors.blue,         'bg': Color(0xFFE3F2FD),       'icon': Icons.person},
  'EN_ROUTE':          {'label': 'On The Way',         'color': Colors.blue,         'bg': Color(0xFFE3F2FD),       'icon': Icons.local_shipping},
  'ARRIVED':           {'label': 'Arrived',            'color': Colors.purple,       'bg': Color(0xFFF3E8FF),       'icon': Icons.location_on},
  'PATIENT_ONBOARD':   {'label': 'Trip Started',       'color': Colors.blue,         'bg': Color(0xFFE3F2FD),       'icon': Icons.airline_seat_recline_normal},
  'TRIP_STARTED':      {'label': 'Trip Started',       'color': Colors.blue,         'bg': Color(0xFFE3F2FD),       'icon': Icons.airline_seat_recline_normal},
  'DESTINATION_REACHED':{'label': 'Completed',         'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5),       'icon': Icons.check_circle},
  'COMPLETED':         {'label': 'Completed',          'color': _kChekupGreen,       'bg': Color(0xFFD1FAE5),       'icon': Icons.check_circle},
  'CANCELLED':         {'label': 'Cancelled',          'color': AppColors.red,       'bg': Color(0xFFFEE2E2),       'icon': Icons.cancel},
  'FAILED':            {'label': 'Failed',             'color': AppColors.red,       'bg': Color(0xFFFEE2E2),       'icon': Icons.error},
};

const _kTabs = [
  {'id': 'ALL', 'label': 'All Orders', 'icon': Icons.list_alt},
  {'id': 'ACTIVE', 'label': 'Upcoming', 'icon': Icons.calendar_today},
  {'id': 'COMPLETED', 'label': 'Completed', 'icon': Icons.check_circle_outline},
  {'id': 'CANCELLED', 'label': 'Cancelled', 'icon': Icons.cancel_outlined},
];

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestsProvider>().fetchRequests(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<RequestsProvider>().fetchRequests();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<RequestsProvider>(builder: (context, prov, _) {
        return Stack(
          children: [
            // Top Green Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 170,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CA02A), Color(0xFF1E8815)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('My Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
                              SizedBox(height: 6),
                              Text('View and manage all your bookings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.read<RequestsProvider>().fetchRequests(refresh: true),
                          icon: const Icon(Icons.tune, color: Colors.white, size: 16),
                          label: const Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tabs overlapping
                  _buildTabs(prov),
                  
                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      color: _kChekupGreen,
                      backgroundColor: Colors.white,
                      onRefresh: () => prov.fetchRequests(refresh: true),
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: _kChekupGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                              child: const Icon(Icons.local_shipping_outlined, color: _kChekupGreen, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text('Ambulance Bookings', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondary)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                                        child: Text('${prov.orders.length} Orders', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildList(prov),
                                _buildNeedHelp(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabs(RequestsProvider prov) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _kTabs.map((tab) {
          final isSelected = prov.statusFilter == tab['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => prov.setFilter(tab['id'] as String),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isSelected ? _kTopGreen : Colors.transparent, width: 3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab['icon'] as IconData, size: 16, color: isSelected ? _kTopGreen : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(tab['label'] as String, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isSelected ? _kTopGreen : AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNeedHelp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF2FBF5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD1FAE5))),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4)]),
                        child: const Icon(Icons.shield_outlined, color: _kChekupGreen, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Need Help?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _kChekupGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Our support team is available 24/7 for any assistance.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.headset_mic, color: Colors.white, size: 16),
                      label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kTopGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4)]),
                  child: const Icon(Icons.shield_outlined, color: _kChekupGreen, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Need Help?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _kChekupGreen)),
                      SizedBox(height: 4),
                      Text('Our support team is available 24/7 for any assistance.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.headset_mic, color: Colors.white, size: 16),
                  label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTopGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(RequestsProvider prov) {
    if (prov.isLoading && prov.orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: List.generate(3, (_) => _SkeletonCard().animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 0.8))),
      );
    }
    if (prov.errorMsg != null && prov.orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text(prov.errorMsg!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    if (prov.orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _kChekupGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_long, size: 64, color: _kChekupGreen)),
              const SizedBox(height: 24),
              const Text('No bookings found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondary)),
              const SizedBox(height: 8),
              const Text('Your ambulance history will appear here.', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(prov.orders.length, (i) {
          return _OrderCard(order: prov.orders[i]);
        }),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AmbulanceRequest order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final isScheduled = order.scheduledFor != null &&
        (status == 'PENDING' || status == 'REQUEST_CREATED' || status == 'REQUEST_RECEIVED' || status == 'SEARCHING' || status == 'SEARCHING_DRIVER');
    
    final hasDriver = order.driver != null;

    Map<String, dynamic> meta;
    if (isScheduled) {
      meta = {
        'label': 'Scheduled',
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
        'icon': Icons.event,
      };
    } else {
      meta = _kStatusMeta[status] ?? _kStatusMeta['PENDING']!;
    }

    final color = meta['color'] as Color;
    final bg = meta['bg'] as Color;
    final label = meta['label'] as String;
    final icon = meta['icon'] as IconData;

    final fare = (order.totalPayable ?? order.baseFare ?? 1250.0);

    // Parse date
    DateTime displayDate;
    if (order.scheduledFor != null) {
      try {
        displayDate = DateTime.parse(order.scheduledFor!).toLocal();
      } catch (_) {
        displayDate = DateTime.tryParse(order.createdAt)?.toLocal() ?? DateTime.now();
      }
    } else {
      try {
        displayDate = DateTime.parse(order.createdAt).toLocal();
      } catch (_) {
        displayDate = DateTime.now();
      }
    }
    final dateStr = DateFormat('d MMM yyyy').format(displayDate);
    final timeStr = DateFormat('hh:mm a').format(displayDate);

    final ambulanceTypeName = (order.driver?.ambulanceType != null && order.driver!.ambulanceType.isNotEmpty)
        ? '${order.driver!.ambulanceType} Ambulance'
        : 'Standard Ambulance';

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed('/tracking', arguments: order.requestId);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mobile Top Row: Avatar + Title & Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset('assets/images/ambulance.png', fit: BoxFit.contain),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  child: Icon(icon, color: Colors.white, size: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ambulanceTypeName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.secondary)),
                              const SizedBox(height: 2),
                              Text(order.requestNumber.isNotEmpty ? order.requestNumber : order.requestId, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    // Route details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: _kChekupGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.pickupAddress ?? 'Current Location', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.dropAddress ?? 'Destination Hospital', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Date & Time
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom actions inside card
                    _buildRightSection(context, order, isScheduled, hasDriver, fare),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side content
                    Expanded(
                      flex: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                                    child: ClipOval(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Image.asset('assets/images/ambulance.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                        child: Icon(icon, color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, size: 12, color: color),
                                          const SizedBox(width: 4),
                                          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(ambulanceTypeName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.secondary)),
                                    const SizedBox(height: 4),
                                    Text(order.requestNumber.isNotEmpty ? order.requestNumber : order.requestId, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: _kChekupGreen, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(order.pickupAddress ?? 'Current Location', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600))),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 7, top: 2, bottom: 2),
                            width: 2,
                            height: 12,
                            child: Flex(direction: Axis.vertical, children: List.generate(4, (_) => Expanded(child: Container(color: AppColors.border, margin: const EdgeInsets.only(bottom: 2))))),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: AppColors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(order.dropAddress ?? 'Destination Hospital', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('|', style: TextStyle(color: AppColors.border, fontSize: 13))),
                              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 190, color: AppColors.border.withOpacity(0.5)),
                    const SizedBox(width: 16),
                    // Right side content
                    Expanded(
                      flex: 9,
                      child: _buildRightSection(context, order, isScheduled, hasDriver, fare),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRightSection(BuildContext context, AmbulanceRequest order, bool isScheduled, bool hasDriver, double fare) {
    final status = order.status;

    // 1. DRIVER ASSIGNED / EN ROUTE / TRIP STARTED (with assigned driver & tracking)
    if (hasDriver && (status == 'DRIVER_ASSIGNED' || status == 'EN_ROUTE' || status == 'PATIENT_ONBOARD' || status == 'TRIP_STARTED')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBDEFB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (order.etaSeconds != null) ...[
              const Text('ETA', style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '${(order.etaSeconds! / 60).ceil()} mins',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 10),
            ],
            const Text('Driver', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(order.driver!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
            if (order.driver!.vehicleNumber.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(order.driver!.vehicleNumber, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 8),
            Text('\u20B9 ${fare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size(0, 36),
                  elevation: 0,
                ),
                child: const Text('Track Now >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
    }

    // 2. SEARCHING FOR AMBULANCE (driver not assigned yet)
    if (!hasDriver && (status == 'SEARCHING' || status == 'SEARCHING_DRIVER' || status == 'REQUEST_CREATED' || status == 'REQUEST_RECEIVED' || status == 'PENDING') && !isScheduled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.search, color: AppColors.amber, size: 20),
            ),
            const SizedBox(height: 6),
            const Text('Searching for Ambulance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
            const SizedBox(height: 8),
            Text('\u20B9 ${fare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.amber, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('View Details >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
              ),
            ),
          ],
        ),
      );
    }

    // 3. SCHEDULED BOOKING
    if (isScheduled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Icon(Icons.event, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(height: 6),
            const Text('Scheduled', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
            const SizedBox(height: 8),
            Text('\u20B9 ${fare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('View Details >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
              ),
            ),
          ],
        ),
      );
    }

    // 4. ARRIVED
    if (status == 'ARRIVED') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.purple, size: 22),
            const SizedBox(height: 4),
            const Text('Arrived', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.purple)),
            if (hasDriver) ...[
              const SizedBox(height: 4),
              Text(order.driver!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text('\u20B9 ${fare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.purple, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('View Details >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.purple)),
              ),
            ),
          ],
        ),
      );
    }

    // 5. COMPLETED / CANCELLED / OTHER
    final isCancelled = status == 'CANCELLED' || status == 'FAILED';
    final btnColor = isCancelled ? AppColors.red : _kChekupGreen;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Total Fare', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          '\u20B9 ${fare.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.secondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: order.requestId),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: btnColor, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 36),
            ),
            child: Text('View Details >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: btnColor)),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: const Padding(padding: EdgeInsets.all(16)),
    );
  }
}
