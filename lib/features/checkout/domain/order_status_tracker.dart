enum OrderStatusStage {
  placed,
  verified,
  processing,
  dispatched,
  delivered,
}

class OrderMilestone {
  final OrderStatusStage stage;
  final String title;
  final bool isCompleted;
  final bool isCurrent;

  OrderMilestone({
    required this.stage,
    required this.title,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class OrderStatusTracker {
  /// Generates a timeline list of order milestones based on status string
  static List<OrderMilestone> getMilestones(String statusStr) {
    final status = statusStr.trim().toUpperCase();

    int currentIndex = 0;
    switch (status) {
      case 'PLACED':
        currentIndex = 0;
        break;
      case 'VERIFIED':
        currentIndex = 1;
        break;
      case 'PROCESSING':
        currentIndex = 2;
        break;
      case 'DISPATCHED':
        currentIndex = 3;
        break;
      case 'DELIVERED':
        currentIndex = 4;
        break;
      default:
        currentIndex = 0;
    }

    final stages = [
      OrderStatusStage.placed,
      OrderStatusStage.verified,
      OrderStatusStage.processing,
      OrderStatusStage.dispatched,
      OrderStatusStage.delivered,
    ];

    final titles = [
      'Order Placed',
      'Price Verified',
      'Processing',
      'Dispatched',
      'Delivered',
    ];

    return List.generate(stages.length, (i) {
      return OrderMilestone(
        stage: stages[i],
        title: titles[i],
        isCompleted: i <= currentIndex,
        isCurrent: i == currentIndex,
      );
    });
  }
}
