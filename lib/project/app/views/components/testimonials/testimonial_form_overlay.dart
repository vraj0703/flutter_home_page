import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../testimonial/presentation/bloc/testimonial_bloc.dart';
import '../../../../testimonial/presentation/bloc/testimonial_event.dart';
import '../../../../testimonial/presentation/bloc/testimonial_state.dart';

/// A Flutter widget overlay for writing a recommendation.
///
/// Rendered as a Stack sibling to the Flame [GameWidget]. Visibility is
/// controlled via the external [showNotifier]. The [bloc] handles submission,
/// LinkedIn auth, and loading/error/success state transitions.
class TestimonialFormOverlay extends StatefulWidget {
  final ValueNotifier<bool> showNotifier;
  final TestimonialBloc bloc;

  const TestimonialFormOverlay({
    super.key,
    required this.showNotifier,
    required this.bloc,
  });

  @override
  State<TestimonialFormOverlay> createState() => _TestimonialFormOverlayState();
}

class _TestimonialFormOverlayState extends State<TestimonialFormOverlay>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  StreamSubscription<TestimonialState>? _blocSub;

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // ── Style constants ──────────────────────────────────────────────────
  static const _gold = Color(0xFFC78E53);
  static const _textColor = Color(0xFFE3E4E5);
  static const _hintColor = Color(0x4DFFFFFF); // 30%
  static const _inputFill = Color(0x0DFFFFFF); // 5%
  static const _inputBorder = Color(0x1AFFFFFF); // 10%
  static const _backdropColor = Color(0xD9000000); // 85%

  static const _linkedInRecommendUrl =
      'https://www.linkedin.com/in/vraj0703/details/recommendations/write/';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    widget.showNotifier.addListener(_onVisibilityChanged);

    // Listen to bloc state changes for submission feedback.
    _blocSub = widget.bloc.stream.listen(_onBlocState);
  }

  void _onBlocState(TestimonialState state) {
    if (!mounted) return;

    if (state is TestimonialLoaded) {
      setState(() {
        _isLoading = state.isSubmitting;
        _errorMessage = state.submissionError;

        if (state.submissionSuccess) {
          _isSuccess = true;
          _isLoading = false;
          // Clear the feedback flag in the bloc after consuming it.
          widget.bloc.add(const ClearSubmissionFeedback());
        }

        // Auto-fill fields from LinkedIn profile when available.
        final profile = state.linkedInProfile;
        if (profile != null) {
          if (_nameController.text.isEmpty) {
            _nameController.text = profile.fullName;
          }
          if (_roleController.text.isEmpty) {
            _roleController.text = profile.role;
          }
          if (_companyController.text.isEmpty) {
            _companyController.text = profile.company;
          }
        }
      });
    }
  }

  void _onVisibilityChanged() {
    if (widget.showNotifier.value) {
      _resetForm();
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _roleController.clear();
    _companyController.clear();
    _messageController.clear();
    _isLoading = false;
    _isSuccess = false;
    _errorMessage = null;

    // Pre-fill from LinkedIn profile if already authenticated.
    final state = widget.bloc.state;
    if (state is TestimonialLoaded && state.linkedInProfile != null) {
      final profile = state.linkedInProfile!;
      _nameController.text = profile.fullName;
      _roleController.text = profile.role;
      _companyController.text = profile.company;
    }
  }

  void _close() {
    widget.showNotifier.value = false;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Determine LinkedIn URL from profile if available.
    String? linkedinUrl;
    final state = widget.bloc.state;
    if (state is TestimonialLoaded && state.linkedInProfile != null) {
      linkedinUrl = state.linkedInProfile!.profileUrl;
    }

    widget.bloc.add(SubmitTestimonialRequested(
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      company: _companyController.text.trim(),
      message: _messageController.text.trim(),
      linkedinUrl: linkedinUrl,
      avatarUrl: (state is TestimonialLoaded)
          ? state.linkedInProfile?.profilePictureUrl
          : null,
    ));
  }

  Future<void> _openLinkedInAuth() async {
    final url = widget.bloc.getLinkedInAuthUrl();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLinkedInRecommend() async {
    final uri = Uri.parse(_linkedInRecommendUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showNotifier,
      builder: (context, isVisible, _) {
        if (!isVisible && !_animController.isAnimating) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _close,
            child: Container(
              color: _backdropColor,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {}, // absorb taps on the card
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCard(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width > 540.0 ? 500.0 : screenSize.width * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: screenSize.height * 0.80,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _inputBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: _isSuccess ? _buildSuccessBody() : _buildFormBody(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Success state ────────────────────────────────────────────────────

  Widget _buildSuccessBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.check_circle_outline, color: _gold, size: 56),
        const SizedBox(height: 20),
        const Text(
          'Thank you!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _gold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your recommendation is pending review.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: _textColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildLinkedInLink(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _close,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Done'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Form state ───────────────────────────────────────────────────────

  Widget _buildFormBody() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32), // balance
              Expanded(
                child: Text(
                  'Write a Recommendation',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _gold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _close,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: const Icon(Icons.close, color: _textColor, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Share your experience working with Vishal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // LinkedIn sign-in button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _openLinkedInAuth,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Sign in with LinkedIn'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.red.shade300,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Name
          _buildField(
            controller: _nameController,
            label: 'Name',
            hint: 'Your full name',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),

          // Role
          _buildField(
            controller: _roleController,
            label: 'Role / Title',
            hint: 'e.g. Senior Engineer',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Role is required' : null,
          ),
          const SizedBox(height: 14),

          // Company
          _buildField(
            controller: _companyController,
            label: 'Company',
            hint: 'e.g. Google',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Company is required' : null,
          ),
          const SizedBox(height: 14),

          // Message
          _buildField(
            controller: _messageController,
            label: 'Your recommendation',
            hint: 'What was it like working with Vishal?',
            maxLines: 5,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Recommendation is required';
              }
              if (v.trim().length < 20) {
                return 'Please write at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _gold.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black54,
                      ),
                    )
                  : const Text('Submit'),
            ),
          ),
          const SizedBox(height: 14),

          // LinkedIn recommend link
          _buildLinkedInLink(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────

  Widget _buildLinkedInLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Also recommend on LinkedIn ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          children: [
            TextSpan(
              text: '\u2192',
              style: const TextStyle(color: _gold),
              recognizer: TapGestureRecognizer()..onTap = _openLinkedInRecommend,
            ),
          ],
          recognizer: TapGestureRecognizer()..onTap = _openLinkedInRecommend,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: _textColor,
          ),
          cursorColor: _gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _hintColor,
            ),
            filled: true,
            fillColor: _inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
            errorStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.red.shade300,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _blocSub?.cancel();
    widget.showNotifier.removeListener(_onVisibilityChanged);
    _animController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
