import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/reading.dart';

class TarotSpreadGrid extends StatelessWidget {
  final List<DrawnCard> cards;
  final int crossAxisCount;
  final double minCardWidth;
  final double maxCardWidth;
  final double? customMainAxisSpacing;

  const TarotSpreadGrid({
    super.key,
    required this.cards,
    required this.crossAxisCount,
    this.minCardWidth = 120,
    this.maxCardWidth = 156,
    this.customMainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final gutterX = w >= 360 ? 16.0 : 12.0;
        final gutterY = customMainAxisSpacing ?? (gutterX * 0.75);

        final rawWidth = (w - (crossAxisCount - 1) * gutterX) / crossAxisCount;
        final cardWidth = rawWidth.clamp(minCardWidth, maxCardWidth);

        final cardHeight = cardWidth * 1.4;
        const chipHeight = 18.0;
        const titleHeight = 32.0;
        const vSpace = 8.0;

        final totalItemHeight = chipHeight + vSpace + cardHeight + vSpace + titleHeight;
        final aspectRatio = cardWidth / totalItemHeight;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutterX / 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gutterX,
              mainAxisSpacing: gutterY,
              childAspectRatio: aspectRatio,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return _TarotCardTile(card: cards[index], cardWidth: cardWidth);
            },
          ),
        );
      },
    );
  }
}

class _TarotCardTile extends StatelessWidget {
  final DrawnCard card;
  final double cardWidth;

  const _TarotCardTile({required this.card, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final borderColor = card.isReversed
        ? AurennaTheme.electricViolet
        : AurennaTheme.amberGlow;
    final cardHeight = cardWidth * 1.4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Position chip
        Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AurennaTheme.amberGlow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            card.positionName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.amberGlow,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Card image panel
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Transform.rotate(
                  angle: card.isReversed ? 3.14159 : 0,
                  child: Image.asset(
                    card.card.imagePath,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: AurennaTheme.mysticBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            card.card.name,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AurennaTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Reversed indicator
              if (card.isReversed)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AurennaTheme.electricViolet.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'R',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Card title
        SizedBox(
          width: cardWidth,
          child: Text(
            card.card.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}