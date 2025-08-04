import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';

class ReadingResultScreen extends StatelessWidget {
  final String question;
  final List<DrawnCard> drawnCards;
  final String reading;

  const ReadingResultScreen({
    super.key,
    required this.question,
    required this.drawnCards,
    required this.reading,
  });

  @override
  Widget build(BuildContext context) {
    // Validate data to prevent errors
    if (drawnCards.isEmpty || reading.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Invalid reading data. Please try again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Reading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Sharing coming soon! ✨',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AurennaTheme.crystalBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AurennaTheme.crystalBlue.withOpacity(0.3),
                      AurennaTheme.electricViolet.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.electricViolet.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Question',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Your Cards',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate card width based on available space
                  final cardWidth = (constraints.maxWidth - 48) / 3; // 3 cards with padding
                  final maxCardWidth = 120.0;
                  final finalCardWidth = cardWidth < maxCardWidth ? cardWidth : maxCardWidth;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: drawnCards.map((drawnCard) {
                      try {
                        return _buildCardDisplay(context, drawnCard, finalCardWidth);
                      } catch (e) {
                        // Fallback card display if individual card fails
                        return Container(
                          width: finalCardWidth,
                          height: finalCardWidth * 1.4,
                          decoration: BoxDecoration(
                            color: AurennaTheme.mysticBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Error loading card',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AurennaTheme.electricViolet.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AurennaTheme.electricViolet,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AurennaTheme.electricViolet.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Your Reading',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AurennaTheme.mysticBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.silverMist.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.silverMist.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      reading,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: AurennaTheme.silverMist,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AurennaTheme.silverMist.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'Remember: The cards offer guidance, but you always have the power to choose your own path.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AurennaTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth < 300 ? 16 : 32,
                            vertical: 16,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('Ask Another Question'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Reading history coming in Phase 3! 📚',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: AurennaTheme.crystalBlue,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth < 300 ? 16 : 32,
                            vertical: 16,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('View Reading History'),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  '✨ May the cards guide your path ✨',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AurennaTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDisplay(BuildContext context, DrawnCard drawnCard, double cardWidth) {
    final borderColor = drawnCard.isReversed
        ? AurennaTheme.electricViolet
        : AurennaTheme.crystalBlue;
    final cardHeight = cardWidth * 1.4; // Maintain aspect ratio

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AurennaTheme.crystalBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            drawnCard.positionName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AurennaTheme.crystalBlue,
              fontWeight: FontWeight.w600,
              fontSize: cardWidth < 100 ? 12 : 14, // Responsive font size
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Card image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Transform.rotate(
                  angle: drawnCard.isReversed ? 3.14159 : 0, // Rotate 180 degrees if reversed
                  child: Image.asset(
                    drawnCard.card.imagePath,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text design if image fails to load
                      return Container(
                        color: AurennaTheme.mysticBlue,
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              drawnCard.card.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (!drawnCard.card.isMajorArcana)
                              Text(
                                drawnCard.card.suit,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AurennaTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Reversed indicator overlay
              if (drawnCard.isReversed)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AurennaTheme.electricViolet.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reversed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Card title/name
        SizedBox(
          width: cardWidth,
          child: Text(
            drawnCard.card.name.isNotEmpty ? drawnCard.card.name : 'Unknown Card',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AurennaTheme.textPrimary,
              fontSize: cardWidth < 100 ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // Card keywords
        SizedBox(
          width: cardWidth,
          child: Text(
            drawnCard.card.keywords,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.textSecondary,
              fontSize: cardWidth < 100 ? 9 : 10, // Responsive font size
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
