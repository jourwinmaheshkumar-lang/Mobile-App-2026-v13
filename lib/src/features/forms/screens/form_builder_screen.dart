import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/localization_service.dart';
import '../models/form_field.dart';
import '../models/form_model.dart';
import '../services/form_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification.dart';

class FormBuilderScreen extends StatefulWidget {
  final FormModel? form;
  const FormBuilderScreen({super.key, this.form});

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _repository = FormRepository();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<FormFieldModel> _fields = [];
  DateTime? _startDate;
  DateTime? _deadline;
  bool _allowProxySubmission = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.form != null) {
      _titleController.text = widget.form!.title;
      _descriptionController.text = widget.form!.description;
      _fields.addAll(widget.form!.fields);
      _startDate = widget.form!.startDate;
      _deadline = widget.form!.deadline;
      _allowProxySubmission = widget.form!.allowProxySubmission;
    } else {
      // Add one default text field
      _addField();
    }
  }

  void _addField() {
    setState(() {
      _fields.add(FormFieldModel(
        id: const Uuid().v4(),
        label: '',
        type: FormFieldType.text,
        isRequired: false,
      ));
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a form title')),
      );
      return;
    }

    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one field')),
      );
      return;
    }

    // Check if all fields have labels
    for (var field in _fields) {
      if (field.label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields must have a label')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = await AuthService().currentUser;
      final form = FormModel(
        id: widget.form?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        fields: _fields,
        createdBy: user?.uid ?? 'unknown',
        createdAt: widget.form?.createdAt ?? DateTime.now(),
        startDate: _startDate,
        deadline: _deadline,
        isActive: widget.form?.isActive ?? true,
        allowProxySubmission: _allowProxySubmission,
      );

      await _repository.saveForm(form);

      if (widget.form == null) {
        // Broad notification for all directors
        await notificationService.notifyAllDirectors(
          title: '📋 New Form: ${form.title}',
          message: 'A new administrative form is available for you to fill.',
          type: NotificationType.info,
          category: 'forms',
          clickAction: 'open_form_list',
          relatedEntityId: form.id,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving form: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.form == null ? localizationService.tr('create_form') : localizationService.tr('edit_form')),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveForm,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(isDark),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Form Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                return _buildFieldEditor(index, isDark);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addField,
        label: const Text('Add Field'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Form Title',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary, width: 2)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Form Description (optional)',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Start Date',
                  value: _startDate,
                  onChanged: (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Deadline',
                  value: _deadline,
                  onChanged: (date) => setState(() => _deadline = date),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Allow Proxy Submission', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Allows users to fill this form on behalf of other directors'),
            value: _allowProxySubmission,
            onChanged: (val) => setState(() => _allowProxySubmission = val),
            secondary: Icon(Icons.people_alt_rounded, color: _allowProxySubmission ? AppTheme.primary : AppTheme.textTertiary),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({required String label, DateTime? value, required Function(DateTime) onChanged}) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );
          if (time != null) {
            onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          } else {
            onChanged(date);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                value == null ? 'Not Set' : '${value.day}/${value.month} ${value.hour}:${value.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldEditor(int index, bool isDark) {
    final field = _fields[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Field ${index + 1}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                onPressed: () => _removeField(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: field.label,
            onChanged: (val) => _fields[index] = _updateField(index, label: val),
            decoration: const InputDecoration(
              labelText: 'Field Label',
              hintText: 'e.g. Full Name, Date of Birth',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FormFieldType>(
                  value: field.type,
                  decoration: const InputDecoration(labelText: 'Field Type'),
                  items: FormFieldType.values.map((type) {
                    String label = type.name.toUpperCase();
                    if (type == FormFieldType.currency) {
                      label = 'INDIAN RUPEES (₹)';
                    } else if (type == FormFieldType.calculation) {
                      label = 'MATH CALCULATION (=)';
                    } else if (type == FormFieldType.notes) {
                      label = 'NOTES (Multi-line)';
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _fields[index] = _updateField(index, type: val);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text('Required', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: field.isRequired,
                    onChanged: (val) {
                      setState(() {
                        _fields[index] = _updateField(index, isRequired: val);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (field.type == FormFieldType.dropdown || 
              field.type == FormFieldType.checkbox || 
              field.type == FormFieldType.radio)
            _buildOptionsEditor(index)
          else if (field.type == FormFieldType.calculation)
            _buildMathEditor(index),
        ],
      ),
    );
  }

   Widget _buildMathEditor(int index) {
    final field = _fields[index];
    final sourceFields = field.mathSourceFields ?? [];
    
    // Only number and currency fields can be used as sources
    final availableSources = _fields.where((f) => 
      f.id != field.id && 
      (f.type == FormFieldType.number || f.type == FormFieldType.currency)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Calculation Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: field.mathOperation ?? 'add',
          decoration: const InputDecoration(labelText: 'Operation'),
          items: const [
            DropdownMenuItem(value: 'add', child: Text('ADD (+)')),
            DropdownMenuItem(value: 'subtract', child: Text('SUBTRACT (-)')),
            DropdownMenuItem(value: 'multiply', child: Text('MULTIPLY (*)')),
          ],
          onChanged: (val) => setState(() {
            _fields[index] = _updateField(index, mathOperation: val);
          }),
        ),
        const SizedBox(height: 16),
        const Text('Source Amount Fields (Select multiple)', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        if (availableSources.isEmpty)
          const Text('No amount/number fields available in this form yet.', style: TextStyle(color: AppTheme.error, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            children: availableSources.map((s) {
              final isSelected = sourceFields.contains(s.id);
              return FilterChip(
                label: Text(s.label.isEmpty ? '(Unnamed Field)' : s.label),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    final newList = List<String>.from(sourceFields);
                    if (val) newList.add(s.id);
                    else newList.remove(s.id);
                    _fields[index] = _updateField(index, mathSourceFields: newList);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildOptionsEditor(int index) {
    final field = _fields[index];
    final options = field.options ?? ['Option 1'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          int optIdx = entry.key;
          String optVal = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: optVal,
                    onChanged: (newVal) {
                      final newOptions = List<String>.from(options);
                      newOptions[optIdx] = newVal;
                      _fields[index] = _updateField(index, options: newOptions);
                    },
                    decoration: InputDecoration(
                      hintText: 'Option ${optIdx + 1}',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.error),
                  onPressed: () {
                    final newOptions = List<String>.from(options);
                    if (newOptions.length > 1) {
                      newOptions.removeAt(optIdx);
                      setState(() {
                        _fields[index] = _updateField(index, options: newOptions);
                      });
                    }
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            final newOptions = List<String>.from(options);
            newOptions.add('Option ${newOptions.length + 1}');
            setState(() {
              _fields[index] = _updateField(index, options: newOptions);
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Option'),
        ),
      ],
    );
  }

   FormFieldModel _updateField(int index, {
    String? label, 
    FormFieldType? type, 
    List<String>? options, 
    bool? isRequired,
    String? mathOperation,
    List<String>? mathSourceFields,
  }) {
    final current = _fields[index];
    return FormFieldModel(
      id: current.id,
      label: label ?? current.label,
      type: type ?? current.type,
      options: options ?? current.options,
      isRequired: isRequired ?? current.isRequired,
      mathOperation: mathOperation ?? current.mathOperation,
      mathSourceFields: mathSourceFields ?? current.mathSourceFields,
    );
  }
}
