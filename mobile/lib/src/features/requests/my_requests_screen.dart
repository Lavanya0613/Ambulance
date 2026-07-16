import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'requests_provider.dart';

const _kStatusMeta = {
  'PENDING':           {'label': 'Pending',       'color': Color(0xFF6b7280), 'bg': Color(0xFFf3f4f6)},
  'REQUEST_CREATED':   {'label': 'Created',        'color': Color(0xFF6b7280), 'bg': Color(0xFFf3f4f6)},
  'SEARCHING_DRIVER':  {'label': 'Searching',      'color': Color(0xFFF4B400), 'bg': Color(0xFFfef7e6)},
  'VENDOR_ACCEPTED':   {'label': 'Accepted',       'color': AppColors.darkBlue, 'bg': AppColors.darkBlueLight},
  'ASSIGNED':          {'label': 'Assigned',       'color': AppColors.darkBlue, 'bg': AppColors.darkBlueLight},
  'DRIVER_ASSIGNED':   {'label': 'Driver Assigned','color': AppColors.darkBlue, 'bg': AppColors.darkBlueLight},
  'EN_ROUTE':          {'label': 'En Route',       'color': AppColors.darkBlue, 'bg': AppColors.darkBlueLight},
  'ARRIVED':           {'label': 'Arrived',        'color': AppColors.green,    'bg': AppColors.greenLight},
  'PATIENT_ONBOARD':   {'label': 'Onboard',        'color': AppColors.darkBlue, 'bg': AppColors.darkBlueLight},
  'DESTINATION_REACHED':{'label': 'At Hospital',   'color': AppColors.green,    'bg': AppColors.greenLight},
  'COMPLETED':         {'label': 'Completed',      'color': AppColors.green,    'bg': AppColors.greenLight},
  'CANCELLED':         {'label': 'Cancelled',      'color': AppColors.red,      'bg': AppColors.redLight},
  'FAILED':            {'label': 'Failed',         'color': AppColors.red,      'bg': AppColors.redLight},
};

const _kAllStatuses = ['ALL', 'PENDING', 'DRIVER_ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'COMPLETED', 'CANCELLED'];

const _kEarlyStatuses = {'REQUEST_CREATED', 'PENDING', 'SEARCHING_DRIVER'};
const _kTerminal = {'COMPLETED', 'CANCELLED', 'FAILED', 'DESTINATION_REACHED'};

String _formatDate(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('d MMM y • HH:mm').format(d);
  } catch (_) {
    return iso;
  }
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestsProvider>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestsProvider>(builder: (context, prov, _) {
      return RefreshIndicator(
        color: AppColors.green,
        onRefresh: prov.fetchRequests,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(prov)),
            if (prov.isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SkeletonCard(),
                  childCount: 4,
                ),
              )
            else if (prov.errorMsg != null)
              SliverToBoxAdapter(child: _errorView(prov))
            else if (prov.filtered.isEmpty)
              SliverToBoxAdapter(child: _emptyView(prov))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RequestCard(request: prov.filtered[i]),
                    childCount: prov.filtered.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(RequestsProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Requests', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.darkBlue)),
              IconButton(
                onPressed: prov.fetchRequests,
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const Text('Your ambulance history and past trips.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 14),

          // Search
          TextField(
            onChanged: prov.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search by name or address...',
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 10),

          // Status filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kAllStatuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _kAllStatuses[i];
                final meta = _kStatusMeta[s];
                final label = s == 'ALL' ? 'All' : (meta?['label'] as String? ?? s);
                final selected = prov.statusFilter == s;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => prov.setFilter(s),
                  selectedColor: AppColors.green,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: selected ? AppColors.green : AppColors.cardBorder),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(RequestsProvider prov) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Icon(Icons.wifi_off, color: AppColors.red, size: 40),
        const SizedBox(height: 12),
        Text(prov.errorMsg!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: prov.fetchRequests, child: const Text('Retry')),
      ]),
    );
  }

  Widget _emptyView(RequestsProvider prov) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
      ),
      child: Column(children: [
        const Icon(Icons.local_hospital, size: 72, color: Color(0xFFe8ecf1)),
        const SizedBox(height: 16),
        const Text('No bookings found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkBlue)),
        const SizedBox(height: 6),
        const Text('You have no ambulance requests matching this filter.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () { /* Navigate to booking tab via main shell */ },
          child: const Text('Book Your First Ambulance'),
        ),
      ]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AmbulanceRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final meta = _kStatusMeta[request.status] ?? _kStatusMeta['PENDING']!;
    final color = meta['color'] as Color;
    final bg = meta['bg'] as Color;
    final label = meta['label'] as String;
    final isTerminal = _kTerminal.contains(request.status);
    final isEarly = _kEarlyStatuses.contains(request.status);
    final hasDriver = !isEarly && request.status != 'VENDOR_ACCEPTED';

    String etaLabel = 'Pending';
    if (isTerminal && request.status == 'COMPLETED') {
      etaLabel = 'Completed';
    } else if (request.etaSeconds != null) {
      etaLabel = '${(request.etaSeconds! / 60).ceil()} mins';
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/tracking', arguments: request.requestId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(request.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 3),
                    Text(request.requestNumber.isNotEmpty ? request.requestNumber : 'Request', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row('Driver Assigned', hasDriver ? 'Yes' : 'No'),
            const SizedBox(height: 6),
            _row('Estimated Arrival', etaLabel),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEarly)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Cancel Request?', style: TextStyle(fontWeight: FontWeight.w800)),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Dismiss')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.red), child: const Text('Cancel Request')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await context.read<RequestsProvider>().cancelRequest(request.requestId);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                else
                  const SizedBox.shrink(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/tracking', arguments: request.requestId),
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: Text(isTerminal ? 'View Details' : 'Track Live', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFf3f4f6),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
