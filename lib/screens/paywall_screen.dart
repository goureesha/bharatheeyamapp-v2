import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveCenter(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/images/logo.png', width: 90, height: 90),
                const SizedBox(height: 16),
                Text('ಭಾರತೀಯಮ್', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: kOrange,
                  letterSpacing: 1.5,
                )),
                const SizedBox(height: 4),
                Text('Vedic Astrology', style: TextStyle(
                  fontSize: 14, color: kMuted, letterSpacing: 0.5,
                )),
                const SizedBox(height: 32),

                // Trial expired message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(children: [
                    Icon(Icons.timer_off, color: Colors.red.shade700, size: 40),
                    const SizedBox(height: 12),
                    Text('ಉಚಿತ ಪ್ರಯೋಗ ಅವಧಿ ಮುಗಿದಿದೆ',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text('Your 3-day free trial has ended',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Subscription benefits
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ಚಂದಾದಾರಿಕೆ ಪ್ರಯೋಜನಗಳು', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kPurple2)),
                      const SizedBox(height: 14),
                      _benefit(Icons.auto_awesome, 'ಎಲ್ಲಾ ಕುಂಡಲಿ ವೈಶಿಷ್ಟ್ಯಗಳು'),
                      _benefit(Icons.calendar_month, 'ಪಂಚಾಂಗ ಮತ್ತು ತಾರಾನುಕೂಲ'),
                      _benefit(Icons.favorite, 'ಹೊಂದಾಣಿಕೆ / Match Making'),
                      _benefit(Icons.menu_book, 'ಮಂತ್ರ ಸಂಗ್ರಹ'),
                      _benefit(Icons.save, 'ನಿಮ್ಮ ಡೇಟಾ ಸುರಕ್ಷಿತ ಬ್ಯಾಕಪ್ (Data Backup)'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await SubscriptionService.buySubscription();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ಚಂದಾದಾರಿಕೆ ಪ್ರಕ್ರಿಯೆ ವಿಫಲವಾಗಿದೆ.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('₹700 / ವರ್ಷಕ್ಕೆ ಚಂದಾದಾರರಾಗಿ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 12),

                // Restore purchases
                TextButton(
                  onPressed: () async {
                    await SubscriptionService.restorePurchases();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ಹಿಂದಿನ ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ.')),
                      );
                    }
                  },
                  child: Text('ಹಿಂದಿನ ಖರೀದಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಿ (Restore)',
                    style: TextStyle(color: kPurple2, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            )),
          ),
        ),
      ),
    );
  }

  static Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, color: kGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: kText, fontSize: 14))),
      ]),
    );
  }
}
