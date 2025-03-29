import 'package:flutter/material.dart';

class AccountInfo extends StatelessWidget {
  const AccountInfo({Key? key}) : super(key: key);
  static final String routeName = '/accountInfo';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField('First Name'),
            const SizedBox(height: 16.0),
            _buildTextField('Last Name'),
            const SizedBox(height: 16.0),
            _buildTextField('Preferred Name'),
            const SizedBox(height: 16.0),
            _buildTextField(
              'Email',
              initialValue: 'odikscloneme@test.com',
              enabled: false,
              filled: true,
            ),
            const SizedBox(height: 16.0),
            _buildTextField('Phone Number'),
            const SizedBox(height: 16.0),
            _buildTextField('Date Of Birth'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        String? initialValue,
        bool enabled = true,
        bool filled = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: filled ?Colors.grey[200]: Colors.white ,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: initialValue != null
            ? TextEditingController(text: initialValue)
            : null,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: filled,
          fillColor: filled ?Colors.grey[200]: Colors.white ,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

}
