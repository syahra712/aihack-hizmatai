import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/chat_message.dart';
import '../../services/mock_ai_service.dart';
import '../../services/api_service.dart';
import '../providers/provider_picker_sheet.dart';
import '../agent_trace/agent_trace_drawer.dart';
import 'widgets/agent_pipeline.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/sample_prompt_chip.dart';
import 'widgets/typing_indicator.dart';

final selectedCityProvider = StateProvider<String>((ref) => 'Karachi');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <ChatMessage>[];
  final _traceSteps = <AgentStep>[];
  bool _isLoading = false;
  bool _showHero = true;
  bool _usedRealADK = false;
  int _toolsCalledCount = 0;
  int _pipelineCompleted = 0;
  int? _pipelineActive;
  List<String> _quickReplies = [];
  bool _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 160;
    if (_showScrollBtn == atBottom) {
      setState(() => _showScrollBtn = !atBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearSession() {
    setState(() {
      _messages.clear();
      _traceSteps.clear();
      _showHero = true;
      _usedRealADK = false;
      _toolsCalledCount = 0;
      _pipelineCompleted = 0;
      _pipelineActive = null;
      _quickReplies = [];
      _isLoading = false;
    });
    _textCtrl.clear();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _showHero = false;
      _messages.add(userMsg);
      _isLoading = true;
      _quickReplies = [];
      _pipelineActive = _pipelineCompleted;
    });
    _scrollToBottom();

    try {
      ApiResponse? apiResponse;
      AiResponse? mockResponse;
      bool usedReal = false;

      try {
        apiResponse = await ApiService.chat(text.trim());
        usedReal = true;
      } catch (_) {
        mockResponse = await MockAiService.processQuery(text.trim());
      }

      final message = usedReal ? apiResponse!.message : mockResponse!.message;
      final providers = usedReal ? apiResponse!.providers : mockResponse!.providers;
      final trace = usedReal ? apiResponse!.trace : mockResponse!.trace;
      final detectedCity = usedReal
          ? (apiResponse!.detectedCity ?? 'Karachi')
          : mockResponse!.detectedCity;

      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: MessageRole.ai,
        text: message,
        timestamp: DateTime.now(),
        providerIds: providers.map((p) => p.id).toList(),
      );

      final newCompleted = (trace.length).clamp(0, 6);

      setState(() {
        _isLoading = false;
        _messages.add(aiMsg);
        _traceSteps.addAll(trace);
        _usedRealADK = usedReal;
        _toolsCalledCount = usedReal ? trace.length : 0;
        _pipelineCompleted = newCompleted;
        _pipelineActive = null;
      });
      _scrollToBottom();

      if (!mounted) return;
      if (providers.isNotEmpty) {
        ProviderPickerSheet.show(
          context,
          providers: providers,
          detectedCity: detectedCity,
          ref: ref,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _pipelineActive = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)],
              ),
              child: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Hizmat', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 20)),
            Text('AI', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 20)),
          ],
        ),
        actions: [
          if (!_showHero)
            IconButton(
              onPressed: _clearSession,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
              tooltip: 'New Chat',
              color: AppColors.textMuted,
            ),
          PopupMenuButton<String>(
            onSelected: (v) => ref.read(selectedCityProvider.notifier).state = v,
            itemBuilder: (_) => AppConstants.cities.map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(city, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _traceSteps.isEmpty
                ? () => _showEmptyTraceInfo(context)
                : () => AgentTraceDrawer.show(context, _traceSteps),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _traceSteps.isEmpty ? AppColors.surfaceLight : AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: _traceSteps.isNotEmpty ? Border.all(color: AppColors.accent.withOpacity(0.2)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree_rounded,
                    color: _traceSteps.isEmpty ? AppColors.textMuted : AppColors.accent,
                    size: 18,
                  ),
                  if (_traceSteps.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_traceSteps.length}',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (!_showHero && _pipelineCompleted > 0)
            AgentPipeline(
              completedCount: _pipelineCompleted,
              activeIndex: _pipelineActive,
            ),
          if (!_showHero && _traceSteps.isNotEmpty) _buildADKBanner(),
          Expanded(
            child: Stack(
              children: [
                _showHero ? _buildHeroView() : _buildChatView(),
                if (_showScrollBtn && !_showHero)
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.card,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
                      ),
                    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                  ),
              ],
            ),
          ),
          if (_quickReplies.isNotEmpty) _buildQuickReplies(),
          _buildInputBar(),
        ],
      ),
    );
  }

  void _showEmptyTraceInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send a message to see the AI agent pipeline trace', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildADKBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.08), AppColors.primary.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_rounded, size: 16, color: AppColors.accent.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            _usedRealADK ? 'Powered by Google ADK' : 'Demo Mode (Mock)',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Real Backend', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (_toolsCalledCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_toolsCalledCount tools',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_traceSteps.length} steps',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildHeroView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF059669).withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇵🇰', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Built for Pakistan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF059669))),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
        const SizedBox(height: 16),
        Text(
          "Ghar ki koi bhi zaroorat?",
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.15),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF6366F1)],
          ).createShader(bounds),
          child: Text(
            'HizmatAI pe chhod do.',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 10),
        Text(
          '6 AI agents orchestrated via Google ADK — understands Roman Urdu, Urdu, English & mixed input.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.samplePrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final prompt = AppConstants.samplePrompts[i];
              return SamplePromptChip(
                prompt: prompt,
                onTap: () => _sendMessage(prompt.text),
              ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: 300 + i * 100)).slideX(begin: 0.2, end: 0);
            },
          ),
        ),
        const SizedBox(height: 28),
        _buildDemoScenarios(),
        const SizedBox(height: 28),
        Text('Popular Services', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 16),
        _buildServiceGrid(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDemoScenarios() {
    final scenarios = [
      (
        'A',
        'Double Booking',
        'Mujhe DHA Phase 2 mein AC repair chahiye abhi, kal subah 9 baje slot book karo.',
        Icons.event_busy_rounded,
        const Color(0xFFFF6B6B),
      ),
      (
        'B',
        'No Zone Match',
        'G-13 Islamabad mein AC technician chahiye kal subah 10 baje',
        Icons.location_off_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        'C',
        'Ambiguous Input',
        'koi repair wala chahiye ghar mein',
        Icons.help_outline_rounded,
        const Color(0xFF6C5CE7),
      ),
      (
        'D',
        'Full Pipeline',
        'Electrician chahiye DHA mein, urgent hai',
        Icons.rocket_launch_rounded,
        const Color(0xFF00B894),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Demo Scenarios', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('For Judges', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...scenarios.asMap().entries.map((entry) {
          final i = entry.key;
          final (id, title, prompt, icon, color) = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _sendMessage(prompt),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(id, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                          Text(
                            prompt,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(icon, color: color, size: 20),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: 500 + i * 100)).slideX(begin: 0.1, end: 0);
        }),
      ],
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      ('Electrician', '⚡', Icons.electrical_services_rounded, const Color(0xFFF59E0B)),
      ('Plumber', '🔧', Icons.plumbing_rounded, const Color(0xFF6C5CE7)),
      ('Cleaning', '🧹', Icons.cleaning_services_rounded, const Color(0xFF00B894)),
      ('AC Repair', '❄️', Icons.ac_unit_rounded, const Color(0xFF0891B2)),
      ('Carpenter', '🪚', Icons.handyman_rounded, const Color(0xFF0284C7)),
      ('Painter', '🎨', Icons.format_paint_rounded, const Color(0xFFFF6B6B)),
      ('Home Tutor', '📚', Icons.school_rounded, const Color(0xFF059669)),
      ('Beautician', '💅', Icons.spa_rounded, const Color(0xFFEC4899)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: services.length,
      itemBuilder: (_, i) {
        final (label, emoji, _, color) = services[i];
        return GestureDetector(
          onTap: () => _sendMessage('I need a $label in ${ref.read(selectedCityProvider)}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: 400 + i * 70)).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length && _isLoading) {
          return const TypingIndicator();
        }
        return ChatBubble(message: _messages[i])
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.12, end: 0);
      },
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickReplies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _sendMessage(reply),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Text(reply, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 8, top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), offset: const Offset(0, -4), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _textCtrl.text = 'AC repair chahiye DHA mein urgent',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.mic_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Describe what you need...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_textCtrl.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                color: _isLoading ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(15),
                boxShadow: _isLoading ? [] : AppShadows.primaryGlow,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
