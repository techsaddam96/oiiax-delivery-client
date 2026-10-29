part of 'add_shipment.dart';

/// OIIAX palette for this flow (brand tokens from AppColors, neutral greys).
class _FlowColors {
  static const Color background = Color(0xffF4F7FB);
  static const Color ink = Color(0xff0F172A);
  static const Color muted = Color(0xff64748B);
  static const Color border = Color(0xffE2E8F0);
  static const Color field = Color(0xffF8FAFC);
  static const Color error = Color(0xffDC2626);
  static const Color success = Color(0xff16A06D);
  static const Color brandCyan = AppColors.primary;
  // A deeper take on the brand blue, so white text keeps its contrast.
  static const Color headerStart = AppColors.primary;
  static const Color headerDeep = AppColors.gradient2;

  static Color get primary => AppColors.primary;
  static Color get primaryTint => AppColors.primary.withValues(alpha: 0.07);
}

// ------------------------------------------------------------------ header and progress

/// A floating brand card: back, title with the step count, and a stepper.
class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.backLabel,
    required this.stepLabels,
    required this.currentIndex,
    required this.counterLabel,
    required this.compact,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final List<String> stepLabels;
  final int currentIndex;
  final String counterLabel;
  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _FlowColors.headerDeep.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [_FlowColors.headerStart, _FlowColors.headerDeep],
              ),
            ),
            child: Stack(
              children: [
                // Soft brand light, behind everything.
                PositionedDirectional(
                  top: -70,
                  end: -50,
                  child: _Glow(
                    size: 190,
                    color: _FlowColors.brandCyan.withValues(alpha: 0.38),
                  ),
                ),
                PositionedDirectional(
                  bottom: -80,
                  start: -40,
                  child: _Glow(
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, compact ? 12 : 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _HeaderButton(
                            icon: Icons.arrow_back,
                            tooltip: backLabel,
                            onTap: onBack,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  counterLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ExcludeSemantics(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      _StepProgress(
                        labels: stepLabels,
                        currentIndex: currentIndex,
                        showLabels: !compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Numbered steps joined by a line: done ✓, current highlighted, the rest open.
class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.labels,
    required this.currentIndex,
    required this.showLabels,
  });

  final List<String> labels;
  final int currentIndex;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final node = showLabels ? 28.0 : 22.0;
    final last = labels.length - 1;
    // The step count above already says where the user is.
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: node,
                    child: Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox.shrink()
                              : _StepConnector(
                                  done: i <= currentIndex, nodeAtEnd: true),
                        ),
                        _StepNode(
                          number: i + 1,
                          done: i < currentIndex,
                          current: i == currentIndex,
                          size: node,
                        ),
                        Expanded(
                          child: i == last
                              ? const SizedBox.shrink()
                              : _StepConnector(
                                  done: i < currentIndex, nodeAtEnd: false),
                        ),
                      ],
                    ),
                  ),
                  if (showLabels) ...[
                    const SizedBox(height: 7),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: i == currentIndex
                              ? 1
                              : i < currentIndex
                                  ? 0.86
                                  : 0.62,
                        ),
                        fontSize: 11,
                        fontWeight: i == currentIndex
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.done, required this.nodeAtEnd});

  final bool done;

  /// Which side the circle is on: the line keeps a small gap there only, so
  /// the halves of neighbouring steps join into one continuous line.
  final bool nodeAtEnd;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 2,
      margin: nodeAtEnd
          ? const EdgeInsetsDirectional.only(end: 4)
          : const EdgeInsetsDirectional.only(start: 4),
      // Square ends: the two halves of a step meet without a notch.
      color: done ? Colors.white : Colors.white.withValues(alpha: 0.26),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.done,
    required this.current,
    required this.size,
  });

  final int number;
  final bool done;
  final bool current;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = done || current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.28),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: done
          ? Icon(
              Icons.check_rounded,
              size: size * 0.6,
              color: _FlowColors.headerStart,
            )
          : Text(
              '$number',
              style: TextStyle(
                color: current
                    ? _FlowColors.headerDeep
                    : Colors.white.withValues(alpha: 0.8),
                fontSize: size * 0.44,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
    );
  }
}

// ------------------------------------------------------------------ step sections

class _ActiveStepCard extends StatelessWidget {
  const _ActiveStepCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _FlowColors.primary.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _FlowColors.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                _StepBadge(number: number, state: _BadgeState.active),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _FlowColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _FlowColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(number),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: child,
          ),
        ],
      ),
    );
  }
}

enum _BadgeState { active, done, upcoming }

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.state});

  final int number;
  final _BadgeState state;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    switch (state) {
      case _BadgeState.active:
        background = _FlowColors.primary;
        foreground = Colors.white;
      case _BadgeState.done:
        background = _FlowColors.success.withValues(alpha: 0.12);
        foreground = _FlowColors.success;
      case _BadgeState.upcoming:
        background = _FlowColors.border;
        foreground = _FlowColors.muted;
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: state == _BadgeState.done
          ? Icon(Icons.check_rounded, size: 18, color: foreground)
          : Text(
              '$number',
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _CompletedStepCard extends StatelessWidget {
  const _CompletedStepCard({
    required this.number,
    required this.title,
    required this.summary,
    required this.editLabel,
    required this.editSemanticLabel,
    required this.onEdit,
  });

  final int number;
  final String title;
  final String summary;
  final String editLabel;
  final String editSemanticLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FlowColors.border),
      ),
      child: Row(
        children: [
          _StepBadge(number: number, state: _BadgeState.done),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _FlowColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _FlowColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Semantics(
            button: true,
            label: editSemanticLabel,
            excludeSemantics: true,
            child: TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: _FlowColors.primary,
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                editLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingStepTile extends StatelessWidget {
  const _UpcomingStepTile({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FlowColors.border),
      ),
      child: Row(
        children: [
          _StepBadge(number: number, state: _BadgeState.upcoming),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _FlowColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ inputs

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _FlowColors.ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 6, top: 1),
            child: Icon(Icons.error_outline_rounded,
                size: 16, color: _FlowColors.error),
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _FlowColors.error,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: _FlowColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _FlowTextField extends StatelessWidget {
  const _FlowTextField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.showErrors,
    this.helper,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
    this.forceLtr = false,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.suffixText,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String? helper;
  final IconData icon;
  final bool showErrors;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool forceLtr;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: _FieldLabel(label)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            minLines: minLines,
            maxLines: maxLines,
            textDirection: forceLtr ? TextDirection.ltr : null,
            textAlign: forceLtr && rtl ? TextAlign.right : TextAlign.start,
            autovalidateMode: showErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            // Reveal just this much above the keyboard, nothing more.
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            style: const TextStyle(
              color: _FlowColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 2,
              errorMaxLines: 3,
              suffixText: suffixText,
              prefixIcon: Icon(icon, size: 20, color: _FlowColors.muted),
              filled: true,
              fillColor: _FlowColors.field,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: _fieldBorder(_FlowColors.border),
              focusedBorder: _fieldBorder(_FlowColors.primary, 1.6),
              errorBorder: _fieldBorder(_FlowColors.error),
              focusedErrorBorder: _fieldBorder(_FlowColors.error, 1.6),
              border: _fieldBorder(_FlowColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    super.key,
    required this.tileKey,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final Key tileKey;
  final String label;
  final String value;
  final String placeholder;
  final IconData icon;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    final borderColor = errorText != null
        ? _FlowColors.error
        : hasValue
            ? _FlowColors.primary.withValues(alpha: 0.35)
            : _FlowColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: _FieldLabel(label)),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '$label: ${hasValue ? value : placeholder}',
          excludeSemantics: true,
          child: Material(
            color: hasValue ? _FlowColors.primaryTint : _FlowColors.field,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: tileKey,
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color:
                            hasValue ? _FlowColors.primary : _FlowColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasValue ? value : placeholder,
                        style: TextStyle(
                          color: hasValue ? _FlowColors.ink : _FlowColors.muted,
                          fontSize: 15,
                          fontWeight:
                              hasValue ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        color: _FlowColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          _InlineError(errorText!),
        ],
      ],
    );
  }
}

class _MapPinCard extends StatelessWidget {
  const _MapPinCard({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.actionLabel,
    required this.onTap,
    this.errorText,
  });

  final String title;
  final String emptyHint;
  final String address;
  final double? latitude;
  final double? longitude;
  final String actionLabel;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    final detail = hasPin
        ? (address.isNotEmpty
            ? address
            : '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}')
        : emptyHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: hasPin ? _FlowColors.primaryTint : _FlowColors.field,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('mapPinCard'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: errorText != null
                      ? _FlowColors.error
                      : hasPin
                          ? _FlowColors.primary.withValues(alpha: 0.35)
                          : _FlowColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _FlowColors.border),
                    ),
                    child: Icon(
                      hasPin
                          ? Icons.where_to_vote_rounded
                          : Icons.add_location_alt_outlined,
                      color: _FlowColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _FlowColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _FlowColors.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: _FlowColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          _InlineError(errorText!),
        ],
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Material(
        color: _FlowColors.field,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _FlowColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: _FlowColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _FlowColors.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        value,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: _FlowColors.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    super.key,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: _FlowColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _FlowColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: _FlowColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ choices

class _Choice {
  const _Choice({
    required this.value,
    required this.title,
    this.subtitle = '',
    this.icon,
  });

  final int value;
  final String title;
  final String subtitle;
  final IconData? icon;
}

/// Selectable cards, two per row when there is room.
class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_Choice> options;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 320 ? 2 : 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: _ChoiceCard(
                  option: option,
                  selected: option.value == selected,
                  onTap: () => onSelected(option.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Choice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: option.title,
      excludeSemantics: true,
      child: Material(
        color: selected ? _FlowColors.primaryTint : _FlowColors.field,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: Key('choice_${option.value}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _FlowColors.primary : _FlowColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon,
                      size: 20,
                      color:
                          selected ? _FlowColors.primary : _FlowColors.muted),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          color:
                              selected ? _FlowColors.primary : _FlowColors.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (option.subtitle.isNotEmpty)
                        Text(
                          option.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _FlowColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: _FlowColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact pill choices for short lists such as the product type.
class _ChipChoices extends StatelessWidget {
  const _ChipChoices({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_Choice> options;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          Semantics(
            button: true,
            selected: option.value == selected,
            inMutuallyExclusiveGroup: true,
            label: option.title,
            excludeSemantics: true,
            child: Material(
              color: option.value == selected
                  ? _FlowColors.primary
                  : _FlowColors.field,
              shape: StadiumBorder(
                side: BorderSide(
                  color: option.value == selected
                      ? _FlowColors.primary
                      : _FlowColors.border,
                ),
              ),
              child: InkWell(
                key: Key('chip_${option.value}'),
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(option.value),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.value == selected) ...[
                          const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          option.title,
                          style: TextStyle(
                            color: option.value == selected
                                ? Colors.white
                                : _FlowColors.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ payment

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.cardKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final Key cardKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected ? _FlowColors.primaryTint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: cardKey,
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _FlowColors.primary : _FlowColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? _FlowColors.primary
                        : _FlowColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: selected ? Colors.white : _FlowColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _FlowColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _FlowColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? _FlowColors.primary : _FlowColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentNote extends StatelessWidget {
  const _PaymentNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xff047857),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xff065F46),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryFeeNote extends StatelessWidget {
  const _DeliveryFeeNote({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _FlowColors.primaryTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 20, color: _FlowColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _FlowColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: _FlowColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ review

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({
    required this.title,
    required this.editLabel,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final String editLabel;
  final VoidCallback onEdit;
  final List<_ReviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 12),
      decoration: BoxDecoration(
        color: _FlowColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FlowColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _FlowColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: '$editLabel $title',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: _FlowColors.primary,
                  ),
                  child: Text(
                    editLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value, {this.ltr = false});

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: _FlowColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: ltr && rtl ? TextAlign.right : TextAlign.start,
              style: const TextStyle(
                color: _FlowColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitErrorBanner extends StatelessWidget {
  const _SubmitErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 20, color: _FlowColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xff991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ sticky actions

class _FlowCtaBar extends StatelessWidget {
  const _FlowCtaBar({
    super.key,
    required this.primaryLabel,
    required this.loadingLabel,
    required this.backLabel,
    required this.showBack,
    required this.loading,
    required this.onPrimary,
    required this.onBack,
  });

  final String primaryLabel;
  final String loadingLabel;
  final String backLabel;
  final bool showBack;
  final bool loading;
  final VoidCallback onPrimary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _FlowColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (showBack) ...[
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                key: const Key('addShipmentBack'),
                onPressed: loading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _FlowColors.ink,
                  side: const BorderSide(color: _FlowColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  backLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                key: const Key('addShipmentPrimary'),
                onPressed: loading ? null : onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _FlowColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _FlowColors.primary.withValues(alpha: 0.72),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              loadingLabel,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        primaryLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ area sheet

class _AreaPickerSheet extends StatefulWidget {
  const _AreaPickerSheet({
    required this.regions,
    required this.selectedId,
    required this.title,
    required this.searchHint,
    required this.emptyLabel,
    required this.arabic,
  });

  final List<Region> regions;
  final int? selectedId;
  final String title;
  final String searchHint;
  final String emptyLabel;
  final bool arabic;

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _name(Region region) =>
      widget.arabic ? region.anregion : region.enregion;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final regions = query.isEmpty
        ? widget.regions
        : widget.regions
            .where((region) =>
                region.anregion.toLowerCase().contains(query) ||
                region.enregion.toLowerCase().contains(query))
            .toList();

    // A sheet is its own route: the keyboard inset is applied here, once.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _FlowColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: _FlowColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (widget.regions.length > 6)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    key: const Key('areaSearch'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: _FlowColors.field,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: _fieldBorder(_FlowColors.border),
                      focusedBorder: _fieldBorder(_FlowColors.primary, 1.6),
                      border: _fieldBorder(_FlowColors.border),
                    ),
                  ),
                ),
              Flexible(
                child: regions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.emptyLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _FlowColors.muted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        itemCount: regions.length,
                        itemBuilder: (context, index) {
                          final region = regions[index];
                          final selected = region.id == widget.selectedId;
                          return ListTile(
                            key: Key('area_${region.id}'),
                            minTileHeight: 48,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selected: selected,
                            selectedTileColor: _FlowColors.primaryTint,
                            title: Text(
                              _name(region),
                              style: TextStyle(
                                color: selected
                                    ? _FlowColors.primary
                                    : _FlowColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: selected
                                ? Icon(Icons.check_rounded,
                                    color: _FlowColors.primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(region.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ states and dialog

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.policyLabel,
    required this.policyNumber,
    required this.deliveryFeeLabel,
    required this.deliveryFee,
    required this.doneLabel,
    required this.onDone,
  });

  final String title;
  final String message;
  final String policyLabel;
  final String? policyNumber;
  final String deliveryFeeLabel;
  final String? deliveryFee;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _FlowColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _FlowColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _FlowColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xff475569),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (policyNumber != null && policyNumber!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _FlowColors.field,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _FlowColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policyLabel,
                    style: const TextStyle(
                      color: _FlowColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    policyNumber!,
                    style: const TextStyle(
                      color: _FlowColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (deliveryFee != null && deliveryFee!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _FlowColors.primaryTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _FlowColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryFeeLabel,
                    style: const TextStyle(
                      color: _FlowColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deliveryFee!,
                    style: const TextStyle(
                      color: _FlowColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: _FlowColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              doneLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _whiteCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _FlowColors.border),
  );
}

class _ReferenceLoadingState extends StatelessWidget {
  const _ReferenceLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: const [
        _SkeletonCard(height: 120),
        SizedBox(height: 14),
        _SkeletonCard(height: 220),
        SizedBox(height: 14),
        _SkeletonCard(height: 64),
        SizedBox(height: 10),
        _SkeletonCard(height: 64),
      ],
    );
  }
}

class _ReferenceErrorState extends StatelessWidget {
  const _ReferenceErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _whiteCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xffEA580C),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _FlowColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _FlowColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  AppLocalizations.isArabic ? 'إعادة المحاولة' : 'Retry',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    // As many placeholder bars as fit: an 18px title bar, then 14px bars,
    // 12px apart, inside 18px padding.
    var lines = 1;
    var used = 18.0;
    while (lines < 4 && used + 12 + 14 <= height - 36) {
      used += 26;
      lines++;
    }
    return Container(
      height: height,
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) => Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
            child: Container(
              width: index == 0
                  ? 140
                  : index == 1
                      ? 220
                      : double.infinity,
              height: index == 0 ? 18 : 14,
              decoration: BoxDecoration(
                color: _FlowColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
