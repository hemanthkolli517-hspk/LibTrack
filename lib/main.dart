
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LibTrackApp());
}

const green = Color(0xFF315C4C);
const darkGreen = Color(0xFF183C32);
const pageBackground = Color(0xFFF5F7F5);

class LibTrackApp extends StatelessWidget {
  const LibTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LibTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: pageBackground,
      ),
      home: const LibraryHome(),
    );
  }
}

// Each Book object represents one physical copy in the library.
class Book {
  final String copyId;
  final String title;
  final String author;
  final String category;
  final String block;
  final String floor;
  final String rack;
  final String shelf;
  final bool isAvailable;

  const Book({
    required this.copyId,
    required this.title,
    required this.author,
    required this.category,
    required this.block,
    required this.floor,
    required this.rack,
    required this.shelf,
    required this.isAvailable,
  });


  String get location => '$block • $floor • $rack • $shelf';

  Book copyWith({String? copyId, String? title, String? author, String? category, String? block, String? floor, String? rack, String? shelf, bool? isAvailable}) => Book(
    copyId: copyId ?? this.copyId, title: title ?? this.title, author: author ?? this.author, category: category ?? this.category,
    block: block ?? this.block, floor: floor ?? this.floor, rack: rack ?? this.rack, shelf: shelf ?? this.shelf,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  Map<String, dynamic> toJson() => {
    'copyId': copyId, 'title': title, 'author': author, 'category': category,
    'block': block, 'floor': floor, 'rack': rack, 'shelf': shelf,
    'isAvailable': isAvailable,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    copyId: json['copyId'] as String, title: json['title'] as String,
    author: json['author'] as String, category: json['category'] as String,
    block: json['block'] as String, floor: json['floor'] as String,
    rack: json['rack'] as String, shelf: json['shelf'] as String,
    isAvailable: json['isAvailable'] as bool? ?? true,
  );
}

class BorrowRecord {
  final String id, copyId, bookTitle, studentName, rollNumber;
  final DateTime borrowedAt, dueDate;
  final DateTime? returnedAt;
  const BorrowRecord({required this.id, required this.copyId, required this.bookTitle,
    required this.studentName, required this.rollNumber, required this.borrowedAt,
    required this.dueDate, this.returnedAt});
  bool get isReturned => returnedAt != null;
  bool get isOverdue => !isReturned && _dateOnly(dueDate).isBefore(_dateOnly(DateTime.now()));
  int get daysOverdue => isOverdue
      ? _dateOnly(DateTime.now()).difference(_dateOnly(dueDate)).inDays
      : 0;
  BorrowRecord returned(DateTime at) => BorrowRecord(id: id, copyId: copyId,
    bookTitle: bookTitle, studentName: studentName, rollNumber: rollNumber,
    borrowedAt: borrowedAt, dueDate: dueDate, returnedAt: at);
  Map<String, dynamic> toJson() => {'id': id, 'copyId': copyId, 'bookTitle': bookTitle,
    'studentName': studentName, 'rollNumber': rollNumber,
    'borrowedAt': borrowedAt.toIso8601String(), 'dueDate': dueDate.toIso8601String(),
    'returnedAt': returnedAt?.toIso8601String()};
  factory BorrowRecord.fromJson(Map<String, dynamic> json) => BorrowRecord(
    id: json['id'] as String, copyId: json['copyId'] as String,
    bookTitle: json['bookTitle'] as String, studentName: json['studentName'] as String,
    rollNumber: json['rollNumber'] as String,
    borrowedAt: DateTime.parse(json['borrowedAt'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    returnedAt: json['returnedAt'] == null ? null : DateTime.parse(json['returnedAt'] as String));
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';


class LibraryHome extends StatefulWidget {
  const LibraryHome({super.key});

  @override
  State<LibraryHome> createState() => _LibraryHomeState();
}

class _LibraryHomeState extends State<LibraryHome> {
  int selectedIndex = 0;
  String searchQuery = '';
  String availabilityFilter = 'All';
  bool isLoading = true;
  final List<BorrowRecord> borrowRecords = [];
  static const _booksKey = 'libtrack_books_v1';
  static const _loansKey = 'libtrack_borrow_records_v1';

  final TextEditingController searchController = TextEditingController();

  final List<String> menuItems = [
    'Dashboard',
    'Book Inventory',
    'Find a Book',
    'Issue & Return',
    'Students',
    'Reports',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_rounded,
    Icons.menu_book_rounded,
    Icons.search_rounded,
    Icons.swap_horiz_rounded,
    Icons.people_alt_rounded,
    Icons.bar_chart_rounded,
  ];

  // Sample records. These are stored in memory for Day 2.
  final List<Book> books = [
    const Book(
      copyId: 'BK-101',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      block: 'Block A',
      floor: 'Floor 1',
      rack: 'Rack 03',
      shelf: 'Shelf 02',
      isAvailable: true,
    ),
    const Book(
      copyId: 'BK-102',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      block: 'Block A',
      floor: 'Floor 1',
      rack: 'Rack 03',
      shelf: 'Shelf 03',
      isAvailable: true,
    ),
    const Book(
      copyId: 'BK-103',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      category: 'Fiction',
      block: 'Block B',
      floor: 'Floor 2',
      rack: 'Rack 01',
      shelf: 'Shelf 04',
      isAvailable: true,
    ),
    const Book(
      copyId: 'BK-104',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      category: 'Computer Science',
      block: 'Block A',
      floor: 'Floor 2',
      rack: 'Rack 05',
      shelf: 'Shelf 01',
      isAvailable: true,
    ),
    const Book(
      copyId: 'BK-105',
      title: 'Learning Flutter',
      author: 'Various Authors',
      category: 'Programming',
      block: 'Block C',
      floor: 'Floor 1',
      rack: 'Rack 02',
      shelf: 'Shelf 03',
      isAvailable: true,
    ),
  ];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBooks = prefs.getString(_booksKey);
      final savedLoans = prefs.getString(_loansKey);
      if (savedBooks != null) {
        final list = jsonDecode(savedBooks) as List<dynamic>;
        books..clear()..addAll(list.map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      if (savedLoans != null) {
        final list = jsonDecode(savedLoans) as List<dynamic>;
        borrowRecords..clear()..addAll(list.map((e) => BorrowRecord.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      if (savedBooks == null) await _saveBooks();
      if (savedLoans == null) await _saveLoans();
    } catch (e) {
      debugPrint('Could not load LibTrack data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_booksKey, jsonEncode(books.map((b) => b.toJson()).toList()));
  }

  Future<void> _saveLoans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loansKey, jsonEncode(borrowRecords.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveAll() async {
    await _saveBooks();
    await _saveLoans();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Book> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return books;

    return books.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.copyId.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query) ||
          book.location.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> showBookDialog({Book? existingBook}) async {
    final Book? result = await showDialog<Book>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookEditorDialog(
        books: books,
        existingBook: existingBook,
      ),
    );

    if (result == null || !mounted) return;

    var bookToSave = result;
    if (existingBook != null) {
      final hasActiveLoan = borrowRecords.any((record) =>
          record.copyId.toLowerCase() == existingBook.copyId.toLowerCase() && !record.isReturned);
      if (hasActiveLoan) {
        // Keep the loan linked to its original copy ID and keep it unavailable.
        bookToSave = result.copyWith(copyId: existingBook.copyId, isAvailable: false);
      }
    }

    setState(() {
      if (existingBook == null) {
        books.add(bookToSave);
      } else {
        final index = books.indexOf(existingBook);
        if (index != -1) books[index] = bookToSave;
      }
    });
    await _saveBooks();
  }

  Future<void> deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book copy?'),
        content: Text(
          'Delete "${book.title}" (${book.copyId}) from the inventory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (borrowRecords.any((r) => r.copyId.toLowerCase() == book.copyId.toLowerCase() && !r.isReturned)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return this book before deleting it.')));
        return;
      }
      setState(() => books.remove(book));
      await _saveBooks();
    }
  }

  Future<void> _issueBook({String? preferredCopyId}) async {
    final available = books.where((b) => b.isAvailable).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No books are available to borrow.')));
      return;
    }
    final draft = await showDialog<_BorrowDraft>(context: context, barrierDismissible: false,
      builder: (_) => _BorrowDialog(books: available, preferredCopyId: preferredCopyId));
    if (draft == null || !mounted) return;
    final index = books.indexWhere((b) => b.copyId == draft.copyId);
    if (index < 0 || !books[index].isAvailable) return;
    final book = books[index];
    setState(() {
      books[index] = book.copyWith(isAvailable: false);
      borrowRecords.insert(0, BorrowRecord(id: DateTime.now().microsecondsSinceEpoch.toString(),
        copyId: book.copyId, bookTitle: book.title, studentName: draft.studentName,
        rollNumber: draft.rollNumber, borrowedAt: DateTime.now(), dueDate: draft.dueDate));
      selectedIndex = 3;
    });
    await _saveAll();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${book.title} issued successfully.')));
  }

  Future<void> _returnBook(BorrowRecord record) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirm book return'),
      content: Text('Mark "${record.bookTitle}" (${record.copyId}) as returned by ${record.studentName}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm return'))]));
    if (yes != true || !mounted) return;
    final ri = borrowRecords.indexWhere((r) => r.id == record.id);
    if (ri < 0 || borrowRecords[ri].isReturned) return;
    final bi = books.indexWhere((b) => b.copyId.toLowerCase() == record.copyId.toLowerCase());
    setState(() {
      borrowRecords[ri] = borrowRecords[ri].returned(DateTime.now());
      if (bi >= 0) books[bi] = books[bi].copyWith(isAvailable: true);
    });
    await _saveAll();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${record.bookTitle} returned successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;

        return Scaffold(
          body: Row(
            children: [
              if (wide) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : selectedIndex == 0
                              ? _buildDashboard()
                              : selectedIndex == 1
                                  ? _buildInventory(constraints.maxWidth)
                                  : selectedIndex == 2
                                      ? _buildFindBook(constraints.maxWidth)
                                      : selectedIndex == 3
                                          ? _buildIssueReturn(constraints.maxWidth)
                                          : selectedIndex == 5
                                              ? _buildReports(constraints.maxWidth)
                                              : _buildPlaceholder(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex == 0
                      ? 0
                      : selectedIndex == 1
                          ? 1
                          : 2,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index == 2 ? 5 : index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      label: 'Books',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      label: 'Reports',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 235,
      color: darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(
                  Icons.local_library_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 10),
                Text(
                  'LibTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 4, 12, 12),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: Color(0xFFB7CDC2),
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...List.generate(menuItems.length, (index) {
            final selected = selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              child: Material(
                color: darkGreen,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  selected: selected,
                  selectedTileColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(
                    menuIcons[index],
                    color: selected ? Colors.white : const Color(0xFFB7CDC2),
                  ),
                  title: Text(
                    menuItems[index],
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD4E1DA),
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => setState(() => selectedIndex = index),
                ),
              ),
            );
          }),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Organise books. Find them faster.',
              style: TextStyle(color: Color(0xFFB7CDC2), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuItems[selectedIndex],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF20352C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Library management workspace',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFFDCE9E0),
            child: Icon(Icons.person_outline, color: green),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final available = books.where((book) => book.isAvailable).length;
    final activeLoans = borrowRecords.where((r) => !r.isReturned).length;
    final returnedLoans = borrowRecords.where((r) => r.isReturned).length;
    final overdueLoans = borrowRecords.where((r) => r.isOverdue).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [green, Color(0xFF527D66)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your library, organised.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track every book, shelf and borrower in one place.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _dashboardCard('Book copies', '${books.length}', Icons.library_books),
              _dashboardCard('Available', '$available', Icons.check_circle),
              _dashboardCard('Borrowed', '$activeLoans', Icons.menu_book),
              _dashboardCard('Returned', '$returnedLoans', Icons.assignment_turned_in_outlined),
              _dashboardCard('Overdue', '$overdueLoans', Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 25),
          FilledButton.icon(
            onPressed: () => setState(() => selectedIndex = 1),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Open book inventory'),
          ),
          const SizedBox(height: 15),
          const Text(
            'Day 3: Borrowing and return management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Book and borrowing records are saved in this browser. Issue books, track due dates and record returns.'),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: () => setState(() => selectedIndex = 3), icon: const Icon(Icons.swap_horiz_rounded), label: const Text('Manage borrowing and returns')),
        ],
      ),
    );
  }

  Widget _dashboardCard(String title, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EAE5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 28),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInventory(double width) {
    final results = filteredBooks;
    final available = books.where((book) => book.isAvailable).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(width >= 850 ? 28 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Inventory',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Manage book copies and their shelf locations.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => showBookDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add book copy'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _smallStat('Total copies', '${books.length}', Icons.menu_book),
              _smallStat('Available', '$available', Icons.check_circle_outline),
              _smallStat(
                'Borrowed',
                '${books.length - available}',
                Icons.assignment_return_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search title, author, copy ID, category or shelf...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE0E7E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE0E7E1)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE4EAE5)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(35),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 42, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No matching books found.'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF0F4F1),
                      ),
                      columns: const [
                        DataColumn(label: Text('Copy ID')),
                        DataColumn(label: Text('Book details')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Shelf location')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: results.map((book) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                book.copyId,
                                style: const TextStyle(
                                  color: green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 185,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      book.author,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(book.category)),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  book.location,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(_statusBadge(book.isAvailable)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit book',
                                    onPressed: () =>
                                        showBookDialog(existingBook: book),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: green,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete book',
                                    onPressed: () => deleteBook(book),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            'Showing ${results.length} of ${books.length} book copies',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Text(
            'Note: shelf locations show the last location recorded by library staff.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String label, String value, IconData icon) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EAE5)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool available) {
    final color = available ? const Color(0xFF28784A) : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Available' : 'Borrowed',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  Widget _buildFindBook(double width) {
    final query = searchQuery.trim().toLowerCase();
    final results = books.where((book) {
      final matchesQuery = query.isEmpty ||
          book.copyId.toLowerCase().contains(query) ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query) ||
          book.location.toLowerCase().contains(query);
      final matchesStatus = availabilityFilter == 'All' ||
          (availabilityFilter == 'Available' && book.isAvailable) ||
          (availabilityFilter == 'Borrowed' && !book.isAvailable);
      return matchesQuery && matchesStatus;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(width >= 850 ? 28 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Find a Book', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text('Search by copy ID, title, author, category, or shelf location.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final searchField = TextField(
            controller: searchController,
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'e.g. BK-101, Clean Code, Rack 03',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty ? null : IconButton(
                tooltip: 'Clear search',
                onPressed: () { searchController.clear(); setState(() => searchQuery = ''); },
                icon: const Icon(Icons.close),
              ),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          final statusField = DropdownButtonFormField<String>(
            initialValue: availabilityFilter,
            decoration: InputDecoration(labelText: 'Availability', filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const ['All', 'Available', 'Borrowed'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) { if (value != null) setState(() => availabilityFilter = value); },
          );
          if (constraints.maxWidth < 650) {
            return Column(children: [searchField, const SizedBox(height: 12), statusField]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: searchField), const SizedBox(width: 12), Expanded(flex: 1, child: statusField)]);
        }),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _smallStat('Matching copies', '${results.length}', Icons.search_rounded),
          _smallStat('Available matches', '${results.where((b) => b.isAvailable).length}', Icons.check_circle_outline),
          _smallStat('Borrowed matches', '${results.where((b) => !b.isAvailable).length}', Icons.menu_book_outlined),
        ]),
        const SizedBox(height: 18),
        if (results.isEmpty)
          Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4EAE5))), child: const Column(children: [Icon(Icons.search_off, size: 42, color: Colors.grey), SizedBox(height: 10), Text('No books match your search and filter.')]))
        else
          Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAE5)), borderRadius: BorderRadius.circular(14)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4F1)),
            columns: const [DataColumn(label: Text('Copy ID')), DataColumn(label: Text('Book')), DataColumn(label: Text('Author')), DataColumn(label: Text('Exact location')), DataColumn(label: Text('Status')), DataColumn(label: Text('Action'))],
            rows: results.map((book) => DataRow(cells: [
              DataCell(Text(book.copyId, style: const TextStyle(color: green, fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 170, child: Text(book.title, overflow: TextOverflow.ellipsis))),
              DataCell(Text(book.author)),
              DataCell(Text(book.location, style: const TextStyle(fontSize: 12))),
              DataCell(_statusBadge(book.isAvailable)),
              DataCell(book.isAvailable
                ? TextButton.icon(onPressed: () => _issueBook(preferredCopyId: book.copyId), icon: const Icon(Icons.add_circle_outline), label: const Text('Issue'))
                : const Text('Currently borrowed', style: TextStyle(color: Colors.orange))),
            ])).toList(),
          ))),
        const SizedBox(height: 12),
        Text('Showing ${results.length} of ${books.length} copies. Location is displayed as block • floor • rack • shelf.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _buildReports(double width) {
    final active = borrowRecords.where((record) => !record.isReturned).toList();
    final returned = borrowRecords.where((record) => record.isReturned).toList();
    final overdue = active.where((record) => record.isOverdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final today = _dateOnly(DateTime.now());
    final soon = active.where((record) {
      final due = _dateOnly(record.dueDate);
      return !record.isOverdue && !due.isBefore(today) && due.difference(today).inDays <= 3;
    }).length;
    final available = books.where((book) => book.isAvailable).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(width >= 850 ? 28 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Library Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text('A live summary of inventory, borrowing activity, and upcoming returns.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _smallStat('Total copies', '${books.length}', Icons.library_books_outlined),
          _smallStat('Available', '$available', Icons.check_circle_outline),
          _smallStat('Borrowed', '${active.length}', Icons.menu_book_outlined),
          _smallStat('Returned', '${returned.length}', Icons.assignment_turned_in_outlined),
          _smallStat('Overdue', '${overdue.length}', Icons.warning_amber_rounded),
          _smallStat('Due in 3 days', '$soon', Icons.event_available_outlined),
        ]),
        const SizedBox(height: 26),
        Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), const Expanded(child: Text('Overdue books', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), if (overdue.isNotEmpty) Text('${overdue.length} require attention', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 10),
        if (overdue.isEmpty)
          Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAE5)), borderRadius: BorderRadius.circular(14)), child: const Column(children: [Icon(Icons.check_circle_outline, color: green, size: 36), SizedBox(height: 8), Text('No overdue books. Great work!')]))
        else
          Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAE5)), borderRadius: BorderRadius.circular(14)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF0F0)),
            columns: const [DataColumn(label: Text('Book / Copy ID')), DataColumn(label: Text('Student')), DataColumn(label: Text('Roll number')), DataColumn(label: Text('Due date')), DataColumn(label: Text('Days overdue')), DataColumn(label: Text('Action'))],
            rows: overdue.map((record) => DataRow(cells: [
              DataCell(
                SizedBox(
                  width: 155,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.bookTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        record.copyId,
                        style: const TextStyle(color: green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(record.studentName)),
              DataCell(Text(record.rollNumber)),
              DataCell(Text(_formatDate(record.dueDate))),
              DataCell(Text(
                '${record.daysOverdue} day${record.daysOverdue == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              )),
              DataCell(TextButton.icon(
                onPressed: () => _returnBook(record),
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Record return'),
              )),
            ])).toList(),
          ))),
        const SizedBox(height: 24),
        const Text('Upcoming due dates', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (soon == 0)
          const Text('No active books are due within the next 3 days.', style: TextStyle(color: Colors.grey))
        else
          ...active.where((record) {
            final due = _dateOnly(record.dueDate);
            return !record.isOverdue && !due.isBefore(today) && due.difference(today).inDays <= 3;
          }).map((record) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            tileColor: Colors.white,
            leading: const Icon(Icons.event, color: green),
            title: Text('${record.bookTitle} (${record.copyId})'),
            subtitle: Text('Borrower: ${record.studentName} • Roll no: ${record.rollNumber}'),
            trailing: Text(_formatDate(record.dueDate), style: const TextStyle(fontWeight: FontWeight.w600)),
          )),
      ]),
    );
  }

  Widget _buildIssueReturn(double width) {
    final active = borrowRecords.where((r) => !r.isReturned).toList();
    final returned = borrowRecords.where((r) => r.isReturned).toList();
    final overdue = active.where((r) => r.isOverdue).length;
    return SingleChildScrollView(padding: EdgeInsets.all(width >= 850 ? 28 : 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 12, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Issue & Return', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 5), Text('Issue books to students and track due dates.', style: TextStyle(color: Colors.grey))]),
        FilledButton.icon(onPressed: _issueBook, icon: const Icon(Icons.add), label: const Text('Issue a book'))]),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [_smallStat('Currently borrowed', '${active.length}', Icons.menu_book_outlined), _smallStat('Overdue', '$overdue', Icons.warning_amber_rounded), _smallStat('Returned', '${returned.length}', Icons.assignment_turned_in_outlined)]),
      const SizedBox(height: 24), const Text('Active borrowings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
      _loanTable(active, history: false), const SizedBox(height: 24), const Text('Return history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
      _loanTable(returned, history: true), const SizedBox(height: 12),
      const Text('Overdue means the due date has passed and the book has not been returned.', style: TextStyle(color: Colors.grey, fontSize: 12))]));
  }

  Widget _loanTable(List<BorrowRecord> records, {required bool history}) {
    if (records.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAE5)), borderRadius: BorderRadius.circular(14)), child: Text(history ? 'No books have been returned yet.' : 'No active borrowings. Select “Issue a book” to begin.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
    return Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAE5)), borderRadius: BorderRadius.circular(14)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4F1)),
      columns: const [DataColumn(label: Text('Book / Copy ID')), DataColumn(label: Text('Student')), DataColumn(label: Text('Roll number')), DataColumn(label: Text('Borrowed on')), DataColumn(label: Text('Due date')), DataColumn(label: Text('Status')), DataColumn(label: Text('Action'))],
      rows: records.map((r) {
        final status = r.isReturned ? 'Returned' : r.isOverdue ? 'Overdue • ${r.daysOverdue}d' : 'Borrowed';
        final color = r.isReturned ? Colors.green.shade700 : r.isOverdue ? Colors.red.shade700 : Colors.orange.shade800;
        return DataRow(cells: [
          DataCell(SizedBox(width: 160, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.bookTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), Text(r.copyId, style: const TextStyle(fontSize: 12, color: green))]))),
          DataCell(Text(r.studentName)), DataCell(Text(r.rollNumber)), DataCell(Text(_formatDate(r.borrowedAt))), DataCell(Text(_formatDate(r.dueDate))),
          DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)))),
          DataCell(r.isReturned ? Text('Returned ${_formatDate(r.returnedAt!)}', style: const TextStyle(color: Colors.grey, fontSize: 12)) : TextButton.icon(onPressed: () => _returnBook(r), icon: const Icon(Icons.assignment_return_outlined, size: 18), label: const Text('Return')))]);
      }).toList())));
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 48, color: green),
            const SizedBox(height: 14),
            Text(
              '${menuItems[selectedIndex]} is coming soon',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text('We will build this section in a later step.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => selectedIndex = 0),
              child: const Text('Back to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}


class _BorrowDraft {
  final String copyId, studentName, rollNumber;
  final DateTime dueDate;
  const _BorrowDraft({required this.copyId, required this.studentName, required this.rollNumber, required this.dueDate});
}

class _BorrowDialog extends StatefulWidget {
  final List<Book> books;
  final String? preferredCopyId;
  const _BorrowDialog({required this.books, this.preferredCopyId});
  @override State<_BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<_BorrowDialog> {
  final _formKey = GlobalKey<FormState>();
  final _student = TextEditingController();
  final _roll = TextEditingController();
  late String _copyId;
  DateTime _due = _dateOnly(DateTime.now().add(const Duration(days: 14)));

  @override
  void initState() {
    super.initState();
    _copyId = widget.preferredCopyId != null &&
            widget.books.any((book) => book.copyId == widget.preferredCopyId)
        ? widget.preferredCopyId!
        : widget.books.first.copyId;
  }

  @override
  void dispose() {
    _student.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Issue a book'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _copyId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Available book copy',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.books.map((book) => DropdownMenuItem(
                    value: book.copyId,
                    child: Text('${book.copyId} — ${book.title}', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _copyId = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _student,
                  decoration: const InputDecoration(labelText: 'Student name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter the student name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _roll,
                  decoration: const InputDecoration(labelText: 'Student roll number', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter the roll number' : null,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, color: green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Due date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_formatDate(_due), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _due,
                            firstDate: _dateOnly(DateTime.now()),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null && mounted) setState(() => _due = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Default loan period: 14 days.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _BorrowDraft(
              copyId: _copyId,
              studentName: _student.text.trim(),
              rollNumber: _roll.text.trim(),
              dueDate: _due,
            ));
          },
          child: const Text('Issue book'),
        ),
      ],
    );
  }
}

// The dialog owns its controllers. Flutter disposes this State only after the
// dialog route has finished closing, preventing disposed-controller rebuild errors.
class BookEditorDialog extends StatefulWidget {
  final List<Book> books;
  final Book? existingBook;

  const BookEditorDialog({
    super.key,
    required this.books,
    this.existingBook,
  });

  @override
  State<BookEditorDialog> createState() => _BookEditorDialogState();
}

class _BookEditorDialogState extends State<BookEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _copyIdController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _blockController;
  late final TextEditingController _floorController;
  late final TextEditingController _rackController;
  late final TextEditingController _shelfController;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    final book = widget.existingBook;
    _copyIdController = TextEditingController(text: book?.copyId ?? '');
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _categoryController = TextEditingController(text: book?.category ?? '');
    _blockController = TextEditingController(text: book?.block ?? 'Block A');
    _floorController = TextEditingController(text: book?.floor ?? 'Floor 1');
    _rackController = TextEditingController(text: book?.rack ?? '');
    _shelfController = TextEditingController(text: book?.shelf ?? '');
    _isAvailable = book?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _copyIdController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _blockController.dispose();
    _floorController.dispose();
    _rackController.dispose();
    _shelfController.dispose();
    super.dispose();
  }

  String _normalise(String value) => value.trim().toLowerCase();

  Future<void> _showValidationAlert({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (alertContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(alertContext).pop(),
            child: const Text('OK, I understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    final newId = _copyIdController.text.trim();
    final newBlock = _blockController.text.trim();
    final newFloor = _floorController.text.trim();
    final newRack = _rackController.text.trim();
    final newShelf = _shelfController.text.trim();
    final currentBook = widget.existingBook;

    final duplicateIdMatches = widget.books.where((book) {
      return !identical(book, currentBook) &&
          _normalise(book.copyId) == _normalise(newId);
    }).toList();
    final Book? duplicateId =
        duplicateIdMatches.isEmpty ? null : duplicateIdMatches.first;

    if (duplicateId != null) {
      await _showValidationAlert(
        title: 'Book ID already exists',
        message: 'The ID "$newId" is already assigned to '
            '"${duplicateId.title}". Please enter a different book ID.',
      );
      return;
    }

    final duplicateLocationMatches = widget.books.where((book) {
      return !identical(book, currentBook) &&
          _normalise(book.block) == _normalise(newBlock) &&
          _normalise(book.floor) == _normalise(newFloor) &&
          _normalise(book.rack) == _normalise(newRack) &&
          _normalise(book.shelf) == _normalise(newShelf);
    }).toList();
    final Book? duplicateLocation = duplicateLocationMatches.isEmpty
        ? null
        : duplicateLocationMatches.first;

    if (duplicateLocation != null) {
      await _showValidationAlert(
        title: 'Rack and shelf already occupied',
        message: '$newBlock, $newFloor, $newRack, $newShelf is already '
            'assigned to "${duplicateLocation.title}" '
            '(${duplicateLocation.copyId}). Please choose a different rack or shelf.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      Book(
        copyId: newId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
        block: newBlock,
        floor: newFloor,
        rack: newRack,
        shelf: newShelf,
        isAvailable: _isAvailable,
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBook != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit book copy' : 'Add a book copy'),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(_copyIdController, 'Unique copy ID', hint: 'e.g. BK-106'),
                _formField(_titleController, 'Book title'),
                _formField(_authorController, 'Author'),
                _formField(_categoryController, 'Category'),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PHYSICAL SHELF LOCATION',
                    style: TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _formField(_blockController, 'Block'),
                _formField(_floorController, 'Floor'),
                _formField(_rackController, 'Rack number'),
                _formField(_shelfController, 'Shelf number'),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool>(
                  initialValue: _isAvailable,
                  decoration: const InputDecoration(
                    labelText: 'Availability',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Available')),
                    DropdownMenuItem(value: false, child: Text('Borrowed')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _isAvailable = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveBook,
          child: Text(isEditing ? 'Save' : 'Add book'),
        ),
      ],
    );
  }
}

