import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/services/first_aid_service.dart';
import 'package:hikingapp/data/models/first_aid_guide.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';

class FirstAidPage extends StatefulWidget {
  const FirstAidPage({super.key});

  @override
  State<FirstAidPage> createState() => _FirstAidPageState();
}

class _FirstAidPageState extends State<FirstAidPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirstAidService _service = FirstAidService();
  List<FirstAidGuide> _items = [];
  String? _userId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId ?? profile.userId;
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final items = await _service.fetchGuides(_userId!);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addNote() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _buildNoteDialog(ctx, titleCtrl, contentCtrl, isEdit: false),
    );
    if (ok == true && _userId != null) {
      if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
        return;
      }
      final g = await _service.addNote(
        userId: _userId!,
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
      );
      setState(() => _items.insert(0, g));
    }
  }

  Future<void> _editNote(FirstAidGuide g) async {
    final titleCtrl = TextEditingController(text: g.title);
    final contentCtrl = TextEditingController(text: g.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _buildNoteDialog(ctx, titleCtrl, contentCtrl, isEdit: true),
    );
    if (ok == true && _userId != null) {
      await _service.updateNote(
        userId: _userId!,
        id: g.id,
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
      );
      final idx = _items.indexWhere((e) => e.id == g.id);
      if (idx >= 0) {
        setState(() {
          _items[idx] = FirstAidGuide(
            id: g.id,
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim(),
            createdAt: g.createdAt,
          );
        });
      }
    }
  }

  Future<void> _delete(String id) async {
    if (_userId == null) return;
    // Show confirmation
    // Show confirmation
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AppActionDialog(
        title: 'Delete Note?',
        icon: Icons.delete_forever_rounded,
        message: 'This cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Color(0xFFCC5500),
      ),
    );

    if (result == 'confirm') {
      await _service.deleteGuide(userId: _userId!, id: id);
      setState(() => _items.removeWhere((e) => e.id == id));
    }
  }

  Widget _buildNoteDialog(
    BuildContext context,
    TextEditingController titleCtrl,
    TextEditingController contentCtrl, {
    required bool isEdit,
  }) {
    bool showTitleError = false;
    bool showContentError = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kMediumSage.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.note_add_rounded,
                    color: kMediumSage,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: titleCtrl,
                  label: 'Title',
                  icon: Icons.title_rounded,
                  hasError: showTitleError,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: contentCtrl,
                  label: 'Content',
                  icon: Icons.description_outlined,
                  maxLines: 5,
                  isMultiline: true,
                  hasError: showContentError,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showTitleError = titleCtrl.text.trim().isEmpty;
                            showContentError = contentCtrl.text.trim().isEmpty;
                          });
                          if (!showTitleError && !showContentError) {
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDeepTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 8,
                          shadowColor: kDeepTeal.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Save Note",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isMultiline = false,
    bool hasError = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: kDeepForest,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: hasError ? Colors.red : Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: isMultiline
              ? const EdgeInsets.only(bottom: 85)
              : const EdgeInsets.all(0),
          child: Icon(icon, color: hasError ? Colors.red : kDeepTeal, size: 22),
        ),
        filled: true,
        fillColor: hasError
            ? Colors.red.withOpacity(0.05)
            : const Color(0xFFF5F7F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError ? Colors.red : kDeepTeal,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: kLightCream,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kLightCream,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 8),
          child: FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
            foregroundColor: kDeepForest,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [
              // --- Header ---
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 80, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First Aid Guide',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: kDeepForest,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Act fast - Save lives',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Tab Bar ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepTeal.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: kDeepTeal,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: kSoftMint.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Standard",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "My Notes",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Tab Views ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PresetGuideTab(),
                    _MyGuidesTab(
                      items: _items,
                      loading: _loading,
                      onAddNote: _addNote,
                      onDelete: _delete,
                      onEditNote: _editNote,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetGuideTab extends StatefulWidget {
  @override
  State<_PresetGuideTab> createState() => _PresetGuideTabState();
}

class _PresetGuideTabState extends State<_PresetGuideTab> {
  final FirstAidService _service = FirstAidService();
  List<Map<String, dynamic>> _guides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetchStandardGuides();
      setState(() {
        _guides = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepTeal));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final guide = _guides[index];
        final List<dynamic> raw = (guide['content'] as List?) ?? [];
        final List<String> content = raw.map((e) => e.toString()).toList();
        return _ExpandableGuideCard(
          title: (guide['title'] ?? '').toString(),
          content: content,
          icon: Icons.local_hospital_rounded,
          color: kDeepTeal,
        );
      },
    );
  }
}

class _MyGuidesTab extends StatelessWidget {
  final List<FirstAidGuide> items;
  final bool loading;
  final VoidCallback onAddNote;
  final void Function(String id) onDelete;
  final void Function(FirstAidGuide g) onEditNote;

  const _MyGuidesTab({
    required this.items,
    required this.loading,
    required this.onAddNote,
    required this.onDelete,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepTeal));
    }

    return Stack(
      children: [
        if (items.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No personal notes yet',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              80,
            ), // Padding for FAB
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ExpandableGuideCard(
                title: item.title,
                // Convert single string content to list for display
                content: (item.content).split('\n'),
                icon: Icons.sticky_note_2_rounded,
                color: kMediumSage,
                isUserNote: true,
                onEdit: () => onEditNote(item),
                onDelete: () => onDelete(item.id),
              );
            },
          ),

        // Floating "Add Note" Button
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: onAddNote,
            backgroundColor: kSoftMint,
            icon: const Icon(Icons.add),
            label: const Text("Add Note"),
            elevation: 4,
          ),
        ),
      ],
    );
  }
}

class _ExpandableGuideCard extends StatelessWidget {
  final String title;
  final List<String> content;
  final IconData icon;
  final Color color;
  final bool isUserNote;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ExpandableGuideCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.isUserNote = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showDetailsDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kDeepForest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: kDeepTeal.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetailsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor:
            Colors.transparent, // Transparent to handle custom shape
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kDeepTeal.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kMediumSage.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_information_outlined,
                      color: kDeepTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title, // Using your class variable
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kDeepForest,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // --- 2. SCROLLABLE CONTENT ---
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content.map((line) {
                      // Using your class variable
                      if (line.trim().isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom Bullet Point
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: kMediumSage,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // The Text
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. ACTION BUTTONS ---
              if (isUserNote) ...[
                // User Note Actions (Edit/Delete/Close)
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onEdit != null) onEdit!(); // Using your callback
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kDeepTeal,
                          side: const BorderSide(color: kDeepTeal),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onDelete != null) {
                            onDelete!(); // Using your callback
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Close Button (Full Width)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text("Close"),
                  ),
                ),
              ] else ...[
                // Standard Guide Actions (Just Close)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDeepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Got it",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
