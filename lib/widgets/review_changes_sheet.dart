import 'package:flutter/material.dart';

class ReviewChangesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> selectedSlots;
  final List<Map<String, dynamic>> selectedForDelete;
  final VoidCallback onConfirm;

  const ReviewChangesSheet({
    Key? key,
    required this.selectedSlots,
    required this.selectedForDelete,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalChanges = selectedSlots.length + selectedForDelete.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Your Changes',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please confirm the modifications before we update your itinerary',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFA384DA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFA384DA), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Summary • $totalChanges Change${totalChanges > 1 ? 's' : ''}\n'
                    '${selectedSlots.isNotEmpty ? '${selectedSlots.length} swap${selectedSlots.length > 1 ? 's' : ''}' : ''}'
                    '${selectedSlots.isNotEmpty && selectedForDelete.isNotEmpty ? ' • ' : ''}'
                    '${selectedForDelete.isNotEmpty ? '${selectedForDelete.length} deletion${selectedForDelete.length > 1 ? 's' : ''}' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFA384DA)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Swap slots
          if (selectedSlots.isNotEmpty) ...[
            const Text('Swap',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006E51))),
            const SizedBox(height: 8),
            ...selectedSlots.map((slot) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh,
                          size: 16, color: Color(0xFF006E51)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${slot['dayNumber']} — ${slot['period']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF006E51)),
                            ),
                            Text(slot['name'],
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Delete slots
          if (selectedForDelete.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Delete',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red)),
            const SizedBox(height: 8),
            ...selectedForDelete.map((slot) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${slot['dayNumber']} — ${slot['period']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red),
                            ),
                            Text(slot['name'],
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF006E51).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Center(
                child: Text('Confirm',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}