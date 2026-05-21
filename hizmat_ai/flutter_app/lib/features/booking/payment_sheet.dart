import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class PaymentResult {
  final String last4;
  final String transactionId;
  PaymentResult({required this.last4, required this.transactionId});
}

class PaymentSheet extends StatefulWidget {
  final int amount;
  final String providerName;
  final String bookingId;
  final void Function(PaymentResult result) onSuccess;

  const PaymentSheet({
    super.key,
    required this.amount,
    required this.providerName,
    required this.bookingId,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required int amount,
    required String providerName,
    required String bookingId,
    required void Function(PaymentResult result) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        amount: amount,
        providerName: providerName,
        bookingId: bookingId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final digits = _cardCtrl.text.replaceAll(' ', '');
    if (digits.length < 16) return 'Enter a valid 16-digit card number';
    if (_expiryCtrl.text.length < 5) return 'Enter expiry as MM/YY';
    if (_cvcCtrl.text.length < 3) return 'Enter a 3-digit CVC';
    if (_nameCtrl.text.trim().isEmpty) return 'Enter cardholder name';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() { _busy = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final last4 = _cardCtrl.text.replaceAll(' ', '').substring(12);
    final result = PaymentResult(
      last4: last4,
      transactionId: 'pi_demo_${DateTime.now().millisecondsSinceEpoch}',
    );
    widget.onSuccess(result);

    setState(() { _busy = false; _success = true; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.pop(context);
  }

  void _fillTestCard() {
    _cardCtrl.text = '4242 4242 4242 4242';
    _expiryCtrl.text = '12/34';
    _cvcCtrl.text = '123';
    _nameCtrl.text = 'Test User';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _success ? 'Payment Confirmed' : 'Pay PKR ${_formatAmount(widget.amount)}',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_success) _buildSuccess() else ...[
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildCardForm(),
                const SizedBox(height: 20),
                _buildTestCardHint(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.providerName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(widget.bookingId, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PKR ${_formatAmount(widget.amount)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('Estimate', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Card Number', _cardCtrl, 'XXXX XXXX XXXX XXXX', Icons.credit_card_rounded,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
          maxLength: 19, keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildField('Expiry', _expiryCtrl, 'MM/YY', Icons.date_range_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()],
              maxLength: 5, keyboardType: TextInputType.number)),
            const SizedBox(width: 14),
            Expanded(child: _buildField('CVC', _cvcCtrl, '123', Icons.lock_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 14),
        _buildField('Cardholder Name', _nameCtrl, 'Ahmed Khan', Icons.person_rounded,
          keyboardType: TextInputType.name),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _busy ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _busy ? null : const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
              color: _busy ? AppColors.surfaceLight : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _busy ? [] : AppShadows.primaryGlow,
            ),
            child: Center(
              child: _busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Text('Processing...', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textMuted, fontSize: 15)),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Pay PKR ${_formatAmount(widget.amount)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                    ],
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('Sandbox mode · No real charges · Demo payment', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, {
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCardHint() {
    return GestureDetector(
      onTap: _fillTestCard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Text('Try test card', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
            const SizedBox(width: 8),
            Text('4242 4242 4242 4242', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
            const Spacer(),
            Text('Tap to fill', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 4)],
          ),
          child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
        ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Payment Confirmed!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text))
            .animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 8),
        Text('PKR ${_formatAmount(widget.amount)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary))
            .animate().fadeIn(duration: 400.ms, delay: 300.ms),
        const SizedBox(height: 12),
        Text(
          'Paid to ${widget.providerName}\nSandbox mode — no real money charged.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatAmount(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 16) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    String text = digits;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
