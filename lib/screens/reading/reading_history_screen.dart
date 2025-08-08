import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import 'reading_result_screen.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  List<Reading> _readings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Bulk selection state
  bool _isSelectionMode = false;
  Set<String> _selectedReadings = {};

  @override
  void initState() {
    super.initState();
    _checkPremiumAndLoadHistory();
  }

  Future<void> _checkPremiumAndLoadHistory() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isPremium = await authService.hasActiveSubscription();
      
      if (!isPremium) {
        // Redirect to premium upgrade if not subscribed
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/premium-upgrade');
        }
        return;
      }

      await _loadReadings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReadings() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final readings = await TarotService.getUserReadings(userId);
      
      if (mounted) {
        setState(() {
          _readings = readings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load reading history: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _showReading(Reading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingResultScreen(
          question: reading.question,
          drawnCards: reading.drawnCards,
          reading: reading.aiReading,
          isFromHistory: true,
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedReadings.clear();
      }
    });
  }

  void _toggleSelection(String readingId) {
    setState(() {
      if (_selectedReadings.contains(readingId)) {
        _selectedReadings.remove(readingId);
      } else {
        _selectedReadings.add(readingId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedReadings.length == _readings.length) {
        // If all are selected, deselect all
        _selectedReadings.clear();
      } else {
        // Select all readings
        _selectedReadings = _readings.map((reading) => reading.id).toSet();
      }
    });
  }

  void _deleteSelectedReadings() async {
    if (_selectedReadings.isEmpty) return;

    // Show confirmation dialog for bulk delete
    final confirmed = await _showBulkDeleteConfirmationDialog(_selectedReadings.length);
    if (!confirmed || !mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create list of reading IDs to delete
      final readingIdsToDelete = List<String>.from(_selectedReadings);
      
      // Use optimized batch delete for much faster performance
      final deleteResults = await TarotService.batchDeleteReadings(readingIdsToDelete, userId);
      final successCount = deleteResults['successful']!.length;
      final failedReadings = deleteResults['failed']!;

      // Update UI by removing successfully deleted readings
      if (mounted) {
        setState(() {
          _readings.removeWhere((reading) => 
            readingIdsToDelete.contains(reading.id) && 
            !failedReadings.contains(reading.id)
          );
          _selectedReadings.clear();
          _isSelectionMode = false;
        });

        // Show result message
        if (failedReadings.isEmpty) {
          // All deletions successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$successCount readings deleted successfully'),
                ],
              ),
              backgroundColor: AurennaTheme.crystalBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          // Some deletions failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Bulk Delete Results', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$successCount readings deleted successfully'),
                  Text('${failedReadings.length} readings could not be deleted'),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to delete readings: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _deleteReading(String readingId) async {
    // Show confirmation dialog first
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed || !mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete from database using optimized method
      await TarotService.deleteReadingFast(readingId, userId);

      // Remove from local list to update UI immediately
      if (mounted) {
        setState(() {
          _readings.removeWhere((reading) => reading.id == readingId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Reading deleted successfully'),
              ],
            ),
            backgroundColor: AurennaTheme.crystalBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Extract meaningful error message
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Check if this is a database permission issue
        final isDatabasePermissionIssue = errorMessage.contains('DATABASE PERMISSION ISSUE') || 
                                         errorMessage.contains('RLS') ||
                                         errorMessage.contains('No rows were deleted');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDatabasePermissionIssue ? Icons.security : Icons.error_outline, 
                      color: Colors.white, 
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDatabasePermissionIssue ? 'Permission Issue' : 'Delete Failed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDatabasePermissionIssue 
                      ? 'Delete functionality is temporarily unavailable due to database configuration. Please contact support.'
                      : errorMessage,
                  style: const TextStyle(fontSize: 14),
                ),
                if (isDatabasePermissionIssue) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Technical: Missing RLS DELETE policy in Supabase',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            backgroundColor: isDatabasePermissionIssue ? Colors.orange.shade700 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 8),
            action: isDatabasePermissionIssue ? null : SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _deleteReading(readingId),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showBulkDeleteConfirmationDialog(int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AurennaTheme.mysticBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AurennaTheme.amberGlow,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete $count Readings?',
                style: TextStyle(
                  color: AurennaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $count readings? This action cannot be undone.',
            style: TextStyle(
              color: AurennaTheme.textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AurennaTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete All',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AurennaTheme.mysticBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AurennaTheme.amberGlow,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Reading?',
                style: TextStyle(
                  color: AurennaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this reading? This action cannot be undone.',
            style: TextStyle(
              color: AurennaTheme.textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AurennaTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('${_selectedReadings.length} selected')
          : const Text('Reading History'),
        leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel selection',
            )
          : null,
        actions: _isSelectionMode 
          ? [
              if (_readings.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _selectedReadings.length == _readings.length 
                      ? Icons.deselect 
                      : Icons.select_all
                  ),
                  onPressed: _selectAll,
                  tooltip: _selectedReadings.length == _readings.length 
                    ? 'Deselect all' 
                    : 'Select all',
                ),
              if (_selectedReadings.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelectedReadings,
                  tooltip: 'Delete selected',
                ),
            ]
          : [
              if (_readings.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'select':
                        _toggleSelectionMode();
                        break;
                      case 'refresh':
                        _loadReadings();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist, size: 20),
                          SizedBox(width: 8),
                          Text('Select readings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Refresh'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AurennaTheme.electricViolet),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your cosmic journey...',
              style: TextStyle(
                color: AurennaTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AurennaTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AurennaTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadReadings,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_readings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AurennaTheme.electricViolet.withValues(alpha: 0.3),
                      AurennaTheme.cosmicPurple.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: AurennaTheme.electricViolet,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your cosmic journey awaits',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AurennaTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t done any readings yet.\nStart your first reading to see it here!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AurennaTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ask Your First Question'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReadings,
      color: AurennaTheme.electricViolet,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _readings.length,
        itemBuilder: (context, index) {
          final reading = _readings[index];
          return _buildReadingCard(reading);
        },
      ),
    );
  }

  Widget _buildReadingCard(Reading reading) {
    final isSelected = _selectedReadings.contains(reading.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AurennaTheme.mysticBlue.withValues(alpha: 0.05),
              AurennaTheme.cosmicPurple.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: isSelected 
              ? AurennaTheme.electricViolet.withValues(alpha: 0.5)
              : AurennaTheme.electricViolet.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSelectionMode 
            ? () => _toggleSelection(reading.id)
            : () => _showReading(reading),
          onLongPress: !_isSelectionMode 
            ? () {
                _toggleSelectionMode();
                _toggleSelection(reading.id);
              }
            : null,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(reading.createdAt),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AurennaTheme.crystalBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!_isSelectionMode)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: AurennaTheme.textSecondary,
                          size: 20,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteReading(reading.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Question
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AurennaTheme.electricViolet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: AurennaTheme.electricViolet,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reading.question,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AurennaTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cards preview
                Row(
                  children: [
                    Text(
                      'Cards: ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reading.drawnCards
                            .map((card) => '${card.card.name}${card.isReversed ? " (R)" : ""}')
                            .join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AurennaTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Reading preview
                Text(
                  reading.aiReading,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Tap to view full reading or selection hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _isSelectionMode 
                        ? 'Tap to select/deselect'
                        : 'Tap to view full reading',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AurennaTheme.crystalBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isSelectionMode ? Icons.touch_app : Icons.arrow_forward_ios,
                      color: AurennaTheme.crystalBlue,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Selection checkbox overlay
          if (_isSelectionMode)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AurennaTheme.electricViolet 
                    : AurennaTheme.mysticBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AurennaTheme.electricViolet,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check : null,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ), // closes InkWell child (Stack)
      ), // closes InkWell
    ), // closes Container (Card's child)
    ); // closes Card
  }
}