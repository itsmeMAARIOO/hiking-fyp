import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class StylishSelect extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String> onChanged;
  final IconData? prefixIcon;

  const StylishSelect({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  State<StylishSelect> createState() => _StylishSelectState();
}

class _StylishSelectState extends State<StylishSelect>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: InputDecorator(
            isFocused: _expanded,
            isEmpty: !hasValue,
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: kDeepTeal)
                  : null,
              labelText: widget.label,
              labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF16A085),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? widget.value! : '',
                    style: TextStyle(
                      color: hasValue
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFF7F8C8D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF2C3E50),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _OptionsList(
            items: widget.items.where((e) => e != widget.value).toList(),
            onSelect: (v) {
              widget.onChanged(v);
              setState(() => _expanded = false);
            },
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

class _OptionsList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelect;

  const _OptionsList({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => onSelect(e),
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
