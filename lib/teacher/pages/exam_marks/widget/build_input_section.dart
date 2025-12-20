import 'package:flutter/material.dart';

class ExamSubjectInputSection extends StatefulWidget {
  final TextEditingController examNameController;
  final TextEditingController subjectController;
  final TextEditingController minMarkController;
  final TextEditingController maxMarkController;
  final List<String> examSuggestions;
  final List<String> subjectSuggestions;
  final VoidCallback prefillExistingMarks;
  final VoidCallback clearMarks;
  final VoidCallback checkHasChanged;
  final Widget? dateAndSessionInput;
  final ValueChanged<String>? onExamNameChanged;
  final ValueChanged<String>? onSubjectChanged;

  const ExamSubjectInputSection({
    super.key,
    required this.examNameController,
    required this.subjectController,
    required this.minMarkController,
    required this.maxMarkController,
    required this.examSuggestions,
    required this.subjectSuggestions,
    required this.prefillExistingMarks,
    required this.clearMarks,
    required this.checkHasChanged,
    this.dateAndSessionInput,
    this.onExamNameChanged,
    this.onSubjectChanged,
  });

  @override
  State<ExamSubjectInputSection> createState() =>
      _ExamSubjectInputSectionState();
}

class _ExamSubjectInputSectionState extends State<ExamSubjectInputSection> {
  bool examSelectedFromSuggestion = false;
  bool subjectSelectedFromSuggestion = false;
  bool _subjectManuallyEdited = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return widget.examSuggestions;
                  }
                  return widget.examSuggestions.where(
                    (option) => option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder: (
                  context,
                  textController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  textController.text = widget.examNameController.text;
                  textController.selection =
                      widget.examNameController.selection;

                  textController.addListener(() {
                    if (widget.examNameController.text != textController.text) {
                      widget.examNameController.value = textController.value;
                      widget.onExamNameChanged?.call(textController.text);
                      examSelectedFromSuggestion = widget.examSuggestions
                          .contains(textController.text);
                      setState(() {});
                      _subjectManuallyEdited =
                          false; // reset subject manual edit when exam changes
                    }
                  });

                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Exam Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        (value) => _handleExamOrSubjectChanged(
                          value,
                          widget.subjectController.text,
                        ),
                  );
                },
                onSelected: (selection) {
                  widget.examNameController.text = selection;
                  examSelectedFromSuggestion = true;
                  setState(() {});
                  _subjectManuallyEdited =
                      false; // reset subject manual edit when exam selected
                  _handleExamOrSubjectChanged(
                    selection,
                    widget.subjectController.text,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return widget.subjectSuggestions;
                  }
                  return widget.subjectSuggestions.where(
                    (option) => option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder: (
                  context,
                  textController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  textController.text = widget.subjectController.text;
                  textController.selection = widget.subjectController.selection;

                  textController.addListener(() {
                    if (widget.subjectController.text != textController.text) {
                      widget.subjectController.value = textController.value;
                      widget.onSubjectChanged?.call(textController.text);
                      subjectSelectedFromSuggestion = widget.subjectSuggestions
                          .contains(textController.text);
                      _subjectManuallyEdited =
                          textController.text.isNotEmpty
                              ? true
                              : _subjectManuallyEdited;
                      setState(() {});
                    }
                  });

                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        (value) => _handleExamOrSubjectChanged(
                          widget.examNameController.text,
                          value,
                        ),
                  );
                },
                onSelected: (selection) {
                  widget.subjectController.text = selection;
                  subjectSelectedFromSuggestion = true;
                  _subjectManuallyEdited = true; // user explicitly picked
                  setState(() {});
                  _handleExamOrSubjectChanged(
                    widget.examNameController.text,
                    selection,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.minMarkController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Mark',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => widget.checkHasChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.maxMarkController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Mark',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => widget.checkHasChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Only show date/session picker if NOT both selected from suggestions
        if (!(examSelectedFromSuggestion && subjectSelectedFromSuggestion))
          if (widget.dateAndSessionInput != null) widget.dateAndSessionInput!,
      ],
    );
  }

  void _handleExamOrSubjectChanged(String exam, String subject) {
    if (exam.trim().isNotEmpty && subject.trim().isNotEmpty) {
      if (!_subjectManuallyEdited) {
        // Prefill only if subject not manually edited
        widget.prefillExistingMarks();
      }
      widget.checkHasChanged();
    } else {
      widget.clearMarks();
      widget.checkHasChanged();
    }
  }
}
