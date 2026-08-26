import 'package:flutter_test/flutter_test.dart';
import 'package:blog_store/features/checkout/domain/order_status_tracker.dart';

void main() {
  group('OrderStatusTracker Tests', () {
    test('Generates completed milestones up to PLACED status', () {
      final milestones = OrderStatusTracker.getMilestones('PLACED');

      expect(milestones.length, 5);
      expect(milestones[0].isCompleted, isTrue);
      expect(milestones[0].isCurrent, isTrue);
      expect(milestones[1].isCompleted, isFalse);
    });

    test('Generates completed milestones up to DISPATCHED status', () {
      final milestones = OrderStatusTracker.getMilestones('DISPATCHED');

      expect(milestones[0].isCompleted, isTrue);
      expect(milestones[1].isCompleted, isTrue);
      expect(milestones[2].isCompleted, isTrue);
      expect(milestones[3].isCompleted, isTrue);
      expect(milestones[3].isCurrent, isTrue);
      expect(milestones[4].isCompleted, isFalse);
    });
  });
}
