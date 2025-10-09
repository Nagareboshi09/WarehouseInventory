import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemFormFields extends StatelessWidget {
  final TextEditingController skuController;
  final TextEditingController descriptionController;
  final TextEditingController? brandController;
  final TextEditingController quantityController;
  final bool isReadonly;
  final FormFieldValidator<String>? skuValidator;
  final FormFieldValidator<String>? descriptionValidator;
  final FormFieldValidator<String>? brandValidator;
  final FormFieldValidator<String>? quantityValidator;
  final List<TextInputFormatter>? quantityInputFormatters;

  const ItemFormFields({
    super.key,
    required this.skuController,
    required this.descriptionController,
    this.brandController,
    required this.quantityController,
    this.isReadonly = false,
    this.skuValidator,
    this.descriptionValidator,
    this.brandValidator,
    this.quantityValidator,
    this.quantityInputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: skuController,
          decoration: const InputDecoration(
            labelText: 'SKU *',
            prefixIcon: Icon(Icons.qr_code),
            border: OutlineInputBorder(),
          ),
          readOnly: isReadonly,
          validator: skuValidator,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          readOnly: isReadonly,
          validator: descriptionValidator,
          maxLines: 2,
        ),
        if (brandController != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: brandController,
            decoration: const InputDecoration(
              labelText: 'Brand',
              prefixIcon: Icon(Icons.branding_watermark),
              border: OutlineInputBorder(),
            ),
            readOnly: isReadonly,
            validator: brandValidator,
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantity *',
            prefixIcon: Icon(Icons.inventory_2),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: quantityInputFormatters,
          validator: quantityValidator,
        ),
      ],
    );
  }
}