import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/mock_ai_service.dart';

class AgentTraceDrawer {
  static void show(BuildContext context, List<AgentStep> steps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TraceSheet(steps: steps),
    );
  }
}

class _TraceSheet extends StatelessWidget {
  final List<AgentStep> steps;
  const _TraceSheet({required this.steps});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, -8), blurRadius: 30),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 14),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree_rounded, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Agent Trace',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${steps.length} fired',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Full reasoning & decisions from each AI agent',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: steps.length,
                  itemBuilder: (_, i) {
                    final step = steps[i];
                    final isLast = i == steps.length - 1;
                    return _TraceStepTile(step: step, index: i, isLast: isLast, initiallyExpanded: i == 0)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 60))
                        .slideX(begin: 0.08, end: 0);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TraceStepTile extends StatefulWidget {
  final AgentStep step;
  final int index;
  final bool isLast;
  final bool initiallyExpanded;
  const _TraceStepTile({required this.step, required this.index, required this.isLast, this.initiallyExpanded = false});

  @override
  State<_TraceStepTile> createState() => _TraceStepTileState();
}

class _TraceStepTileState extends State<_TraceStepTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  Color get _agentColor => {
    'IntentAgent': AppColors.intentAgent,
    'DiscoveryAgent': AppColors.discoveryAgent,
    'RankAgent': AppColors.rankAgent,
    'PriceAgent': AppColors.priceAgent,
    'BookingAgent': AppColors.bookingAgent,
    'FollowupAgent': AppColors.followupAgent,
    'ADK_Orchestrator': AppColors.adkOrchestrator,
  }[widget.step.agent] ?? AppColors.primary;

  IconData get _agentIcon => {
    'IntentAgent': Icons.psychology_rounded,
    'DiscoveryAgent': Icons.search_rounded,
    'RankAgent': Icons.leaderboard_rounded,
    'PriceAgent': Icons.receipt_rounded,
    'BookingAgent': Icons.calendar_today_rounded,
    'FollowupAgent': Icons.support_agent_rounded,
    'ADK_Orchestrator': Icons.hub_rounded,
  }[widget.step.agent] ?? Icons.smart_toy_rounded;

  String get _agentDescription => {
    'IntentAgent': 'Parses user intent, language, service type & urgency',
    'DiscoveryAgent': 'Searches provider database for matching candidates',
    'RankAgent': 'Scores & ranks providers across 6 quality factors',
    'PriceAgent': 'Calculates cost with labor, urgency & distance modifiers',
    'BookingAgent': 'Creates booking, checks slot availability & conflicts',
    'FollowupAgent': 'Schedules reminders & sets up dispute channels',
    'ADK_Orchestrator': 'Google ADK orchestration layer',
  }[widget.step.agent] ?? '';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _agentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_agentIcon, size: 15, color: _agentColor),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_agentColor.withOpacity(0.2), _agentColor.withOpacity(0.05)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.soft,
                  border: _expanded
                      ? Border.all(color: _agentColor.withOpacity(0.15))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _agentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.step.agent,
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _agentColor),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.step.timestamp.hour}:${widget.step.timestamp.minute.toString().padLeft(2, '0')}:${widget.step.timestamp.second.toString().padLeft(2, '0')}',
                          style: GoogleFonts.sourceCodePro(fontSize: 10, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.step.action,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      if (_agentDescription.isNotEmpty)
                        Text(
                          _agentDescription,
                          style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _agentColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 13, color: _agentColor),
                            const SizedBox(width: 6),
                            Text('Reasoning', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _agentColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.step.detail,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.text, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text('Raw output', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '{\n  "agent": "${widget.step.agent}",\n  "action": "${widget.step.action}",\n  "detail": "${widget.step.detail}",\n  "timestamp": "${widget.step.timestamp.toIso8601String()}"\n}',
                                style: GoogleFonts.sourceCodePro(fontSize: 10, color: AppColors.textMuted, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
