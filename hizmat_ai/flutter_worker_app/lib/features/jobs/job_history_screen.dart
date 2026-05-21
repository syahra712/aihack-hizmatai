import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/job.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Job>> _jobsStream(List<String> statuses) =>
      FirebaseFirestore.instance
          .collection('bookings')
          .where('provider_id', isEqualTo: _uid)
          .where('status', whereIn: statuses)
          .orderBy('created_at', descending: true)
          .limit(30)
          .snapshots()
          .map((s) => s.docs.map(Job.fromFirestore).toList());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        title: const Text('Jobs'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WorkerColors.accent,
          labelColor: WorkerColors.accent,
          unselectedLabelColor: WorkerColors.textMuted,
          labelStyle: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _JobList(
            stream: _jobsStream(
                ['pending_worker', 'confirmed', 'en_route', 'arrived', 'in_progress']),
          ),
          _JobList(stream: _jobsStream(['completed'])),
          _JobList(stream: _jobsStream(['cancelled', 'disputed'])),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.stream});
  final Stream<List<Job>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Job>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: WorkerColors.accent));
        }
        final jobs = snap.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work_outline,
                    size: 64, color: WorkerColors.textLight),
                const SizedBox(height: 12),
                Text('No jobs here yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: WorkerColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(WorkerSizes.pagePadding),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _JobHistoryCard(job: jobs[index]),
        );
      },
    );
  }
}

class _JobHistoryCard extends StatelessWidget {
  const _JobHistoryCard({required this.job});
  final Job job;

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.completed:
        return WorkerColors.success;
      case JobStatus.cancelled:
      case JobStatus.disputed:
        return WorkerColors.error;
      case JobStatus.inProgress:
      case JobStatus.enRoute:
      case JobStatus.arrived:
        return WorkerColors.accent;
      default:
        return WorkerColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = job.slot != null
        ? DateFormat('d MMM yyyy').format(job.slot)
        : '—';
    final color = _statusColor(job.status);

    return InkWell(
      onTap: () => context.go('/job/${job.ref}'),
      borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(WorkerSizes.cardPadding),
        decoration: BoxDecoration(
          color: WorkerColors.surface,
          borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
          boxShadow: WorkerColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.home_repair_service_rounded,
                  color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.serviceLabel,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text('${job.customerName} · $dateStr',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.displayLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (job.finalPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${job.finalPrice!.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: WorkerColors.text,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
