import 'package:flutter/material.dart';

class EmergencyContacts extends StatelessWidget {
  const EmergencyContacts({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      {'name': 'Jane Thompson (Wife)', 'phone': '(555) 123-4567'},
      {'name': 'Mike Johnson (Friend)', 'phone': '(555) 987-6543'},
      {'name': 'Local Rangers', 'phone': '(555) 555-0123'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Emergency Contacts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ...contacts.map((contact) {
            return Card(
              child: ListTile(
                title: Text(contact['name']!),
                subtitle: Text(contact['phone']!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.phone, color: Colors.green),
                    SizedBox(width: 8),
                    Icon(Icons.message, color: Colors.green),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
