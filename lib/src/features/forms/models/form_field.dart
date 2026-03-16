import 'package:cloud_firestore/cloud_firestore.dart';

enum FormFieldType {
  text,
  number,
  date,
  dropdown,
  checkbox,
  radio,
  currency,
  calculation,
  notes,
}

class FormFieldModel {
  final String id;
  final String label;
  final FormFieldType type;
  final List<String>? options;
  final bool isRequired;
  final String? placeholder;
  final String? mathOperation; // 'add', 'subtract', 'multiply'
  final List<String>? mathSourceFields; // IDs of fields to use in calculation

  FormFieldModel({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.isRequired = false,
    this.placeholder,
    this.mathOperation,
    this.mathSourceFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'options': options,
      'isRequired': isRequired,
      'placeholder': placeholder,
      'mathOperation': mathOperation,
      'mathSourceFields': mathSourceFields,
    };
  }

  factory FormFieldModel.fromMap(Map<String, dynamic> map) {
    return FormFieldModel(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: FormFieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FormFieldType.text,
      ),
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      isRequired: map['isRequired'] ?? false,
      placeholder: map['placeholder'],
      mathOperation: map['mathOperation'],
      mathSourceFields: map['mathSourceFields'] != null ? List<String>.from(map['mathSourceFields']) : null,
    );
  }
}
