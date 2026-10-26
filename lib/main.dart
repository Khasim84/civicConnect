import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CivicConnectApp());
}

const Color appBlue = Color(0xFF195CF5);
const List<String> categories = [
  'Roads',
  'Water Supply',
  'Electricity',
  'Sanitation',
  'Other',
];

const List<String> statuses = [
  'Pending',
  'In Progress',
  'Resolved',
];

class ComplaintStorage {
  static const String storageKey = 'civic_complaints';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);

    if (saved == null) return [];

    try {
      final decoded = jsonDecode(saved) as List;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Map<String, dynamic>> complaints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(complaints));
  }
}

class CivicConnectApp extends StatelessWidget {
  const CivicConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appBlue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7FC),
      ),
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute<Map<String, dynamic>>(
              settings: settings,
              builder: (_) => ComplaintDetailsScreen(
                complaint: Map<String, dynamic>.from(args),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool loading = true;
  String searchText = '';
  String selectedCategory = 'All Categories';
  String selectedStatus = 'All Statuses';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadComplaints() async {
    final saved = await ComplaintStorage.load();
    if (!mounted) return;

    setState(() {
      complaints = saved;
      loading = false;
    });
  }

  Future<void> saveComplaints() async {
    await ComplaintStorage.save(complaints);
  }

  Future<void> registerComplaint() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ComplaintFormScreen(),
      ),
    );

    if (result == null) return;

    setState(() {
      complaints.insert(0, result);
    });
    await saveComplaints();
  }

  Future<void> openDetails(Map<String, dynamic> complaint) async {
    final result = await Navigator.of(context).pushNamed<Map<String, dynamic>>(
      '/details',
      arguments: Map<String, dynamic>.from(complaint),
    );

    if (!mounted || result == null) return;

    final id = result['id'];

    if (result['action'] == 'delete') {
      setState(() {
        complaints.removeWhere((item) => item['id'] == id);
      });
      await saveComplaints();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint deleted')),
      );
    } else if (result['action'] == 'update') {
      setState(() {
        final index = complaints.indexWhere(
          (item) => item['id'] == id,
        );
        if (index != -1) {
          complaints[index] = Map<String, dynamic>.from(result['complaint']);
        }
      });
      await saveComplaints();
    }
  }

  List<Map<String, dynamic>> get filteredComplaints {
    return complaints.where((complaint) {
      final query = searchText.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          (complaint['title'] ?? '').toString().toLowerCase().contains(query) ||
          (complaint['name'] ?? '').toString().toLowerCase().contains(query) ||
          (complaint['location'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query);

      final matchesCategory = selectedCategory == 'All Categories' ||
          complaint['category'] == selectedCategory;

      final matchesStatus = selectedStatus == 'All Statuses' ||
          complaint['status'] == selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleComplaints = filteredComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CivicConnect',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appBlue,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Your Voice, Your City.',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Report civic issues and help your community.',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_city, color: Colors.white, size: 42),
                      SizedBox(height: 12),
                      Text(
                        'Make a Difference Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Report roads, water, electricity and sanitation issues.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: registerComplaint,
                  icon: const Icon(Icons.add),
                  label: const Text('Register a Complaint'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'My Complaints (${complaints.length})',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title, name or location',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchText = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                        items: [
                          'All Categories',
                          ...categories,
                        ].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                        items: [
                          'All Statuses',
                          ...statuses,
                        ].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedStatus = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visibleComplaints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 45, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          complaints.isEmpty
                              ? 'No complaints yet. Register your first complaint!'
                              : 'No complaints match your search or filters.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ...visibleComplaints.map((complaint) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment_outlined),
                      ),
                      title: Text(
                        complaint['title'] ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${complaint['category']} • ${complaint['status']}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        openDetails(complaint);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'SDG 11 • Sustainable Cities and Communities',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
    );
  }
}

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = categories[0];

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void submitComplaint() {
    if (!formKey.currentState!.validate()) return;

    final complaint = <String, dynamic>{
      'id': 'CG-${DateTime.now().millisecondsSinceEpoch}',
      'name': nameController.text.trim(),
      'title': titleController.text.trim(),
      'category': category,
      'location': locationController.text.trim(),
      'description': descriptionController.text.trim(),
      'status': 'Pending',
    };

    Navigator.pop(context, complaint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register a Complaint')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Report a civic issue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Citizen Name',
                border: OutlineInputBorder(),
              ),
              validator: validate,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Complaint Title',
                hintText: 'e.g. Water leakage',
                border: OutlineInputBorder(),
              ),
              validator: validate,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Street or area',
                border: OutlineInputBorder(),
              ),
              validator: validate,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: validate,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: submitComplaint,
              icon: const Icon(Icons.send),
              label: const Text('Submit Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late Map<String, dynamic> complaint;
  late String status;

  @override
  void initState() {
    super.initState();
    complaint = Map<String, dynamic>.from(widget.complaint);
    status = statuses.contains(complaint['status'])
        ? complaint['status']
        : 'Pending';
  }

  Future<void> confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete complaint?'),
        content: const Text(
          'This complaint will be permanently removed from this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, {
        'action': 'delete',
        'id': complaint['id'],
      });
    }
  }

  void saveStatus() {
    complaint['status'] = status;
    Navigator.pop(context, {
      'action': 'update',
      'id': complaint['id'],
      'complaint': complaint,
    });
  }

  Widget detailItem(String label, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(value == null || value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 8),
          const Text(
            'Complaint Details',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          detailItem('Complaint ID', complaint['id']?.toString()),
          detailItem('Citizen Name', complaint['name']?.toString()),
          detailItem('Title', complaint['title']?.toString()),
          detailItem('Category', complaint['category']?.toString()),
          detailItem('Location', complaint['location']?.toString()),
          detailItem('Description', complaint['description']?.toString()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: statuses.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveStatus,
                      child: const Text('Save Status'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Delete Complaint',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
