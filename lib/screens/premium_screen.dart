import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../core/app_constrants.dart';
import '../core/services/analytics_services.dart';
import '../providers/subscribtionprovider.dart';
import '../widgets/app_dialogs.dart';
import '../../core/app_theme.dart';
import '../providers/in_app_purchase_provider.dart';

import 'dart:async';

import 'home_screen.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  final bool isFromOnboarding;
  const PremiumScreen({super.key, this.isFromOnboarding = false});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  // 0 = monthly, 1 = yearly, 2 = lifetime
  int _selectedPlan = 1;

  int _countdown = 5;
  Timer? _timer;
  StreamSubscription? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isFromOnboarding) {
      _countdown = 5;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          _timer?.cancel();
        }
      });
    } else {
      _countdown = 0;
    }

    // Listen for purchase updates to show snackbars
    Future.microtask(() {
      final l10n = AppLocalizations.of(context);

      final iap = ref.read(inAppPurchaseProvider);
      _purchaseSubscription = iap.purchaseUpdates.listen((purchase) {
        if (!mounted) return;
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.purchaseSuccessful ?? 'Purchase Successful! Enjoy your Pro features.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Auto-hide paywall after short delay to allow snackbar visibility
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _onClose();
            }
          });
        } else if (purchase.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.purchaseError(purchase.error?.message ?? l10n.transactionFailed) ?? 'Purchase Error: ${purchase.error?.message ?? "Transaction failed"}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _onClose() {
    AnalyticsService.instance.logEvent('premium_screen_close_tapped');
    if (widget.isFromOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  List<_PlanData> _getPlans(AppLocalizations? l10n) => [
    _PlanData(
      label: l10n?.monthly ?? 'Monthly',
      price: '',
      per: l10n?.perMonth ?? '/ month',
      badge: null,
      productId: StoreKeys.getMonthlyKey(),
    ),
    _PlanData(
      label: l10n?.yearly ?? 'Yearly',
      price: '',
      per: l10n?.perYear ?? '/ year',
      badge: null,
      productId: StoreKeys.getYearlyKey(),
    ),
    _PlanData(
      label: l10n?.lifetime ?? 'Lifetime',
      price: '',
      per: l10n?.oneTime ?? 'one-time',
      badge: null,
      productId: StoreKeys.getLifetimeKey(),
    ),
  ];

  List<_Feature> _getFeatures(AppLocalizations? l10n) => [
    _Feature(
      icon: Icons.all_inclusive_rounded,
      label: l10n?.unlimitedScans ?? 'Unlimited AI Scans',
      color: const Color(0xFFFF6B35),
    ),
    _Feature(
      icon: Icons.medical_services_outlined,
      label: l10n?.treatmentGuides ?? 'Treatment Guides',
      color: const Color(0xFF4CAF50),
    ),
    _Feature(
      icon: Icons.block_rounded,
      label: l10n?.adFree ?? 'Ad-Free Experience',
      color: const Color(0xFF2196F3),
    ),
    _Feature(
      icon: Icons.insights_rounded,
      label: l10n?.pestInsights ?? 'Advanced Pest Insights',
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final iapProvider = ref.watch(inAppPurchaseProvider);
    final subProvider = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context);
    final plans = _getPlans(l10n);
    final features = _getFeatures(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // ── Background gradient blobs ──────────────────────────
          _buildBackgroundBlobs(),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Platform.isMacOS
                ? _buildMacLayout(iapProvider, subProvider, plans, features)
                : _buildMobileLayout(iapProvider, subProvider, plans, features),
          ),

          // ── Fixed Close Button ────────────────────────────────
          if (_countdown <= 0)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                    onPressed: _onClose,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.shade700.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 80,
          right: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepOrange.shade400.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -30,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.shade900.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepOrange.shade900.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      InAppPurchaseProvider iap,
      SubscriptionProvider sub,
      List<_PlanData> plans,
      List<_Feature> features,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(sub.isPremium),
                      const SizedBox(height: 20),
                      _buildFeatureGrid(features: features),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      _buildPlanCards(iap, plans),
                      const SizedBox(height: 20),
                      _buildSubscribeButton(iap, sub.isPremium, plans),
                      const SizedBox(height: 12),
                      _buildFooter(iap),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacLayout(
      InAppPurchaseProvider iap,
      SubscriptionProvider sub,
      List<_PlanData> plans,
      List<_Feature> features,
      ) {

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            // Mac AppBar style row
            const SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildHeader(sub.isPremium),
                    const SizedBox(height: 30),

                    // ── Plan Cards ─────────────────────────
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: List.generate(plans.length, (index) {
                        return SizedBox(
                          width: 320, // Final increased width for long currency strings
                          height: 200, // Reduced height to keep them compact and uniform
                          child: _buildPlanTile(index, iap, plans, isMac: true),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),

                    // ── Features Row (Wide) ─────────────────────────
                    _buildFeatureGrid(features: features, isMac: true),
                    const SizedBox(height: 30),

                    // ── Mac Centered Subscribe Button ───────────────
                    SizedBox(
                      width: 440,
                      child: _buildSubscribeButton(iap, sub.isPremium, plans),
                    ),
                    const SizedBox(height: 30),
                    _buildFooter(iap),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isPremium) {
    final l10n = AppLocalizations.of(context);

    bool isMac = Platform.isMacOS;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMac ? 16 : 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: isMac ? 36 : 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.appName ?? AppConstants.appName,
          style: GoogleFonts.outfit(
            fontSize: isMac ? 14 : 11,
            color: Colors.orange.shade300,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n?.goProUpgrade ?? 'Go PRO & Unlock\nFull Power',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMac ? 32 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.healthyPlantsDesc ??
              'Everything you need for healthy plants,\nunlimited and ad-free.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMac ? 14 : 11,
            color: Colors.white54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildFeatureGrid({required List<_Feature> features, bool isMac = false}) {
    if (isMac) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: features.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 4.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (_, i) {
          final f = features[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f.icon, color: f.color, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    f.label,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Mobile: Compact Box Layout like reference
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(f.icon, color: f.color, size: 16),
                const SizedBox(width: 12),
                Text(
                  f.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 16),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildPlanCards(InAppPurchaseProvider iap, List<_PlanData> plans) {
    if (Platform.isMacOS) {
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: List.generate(plans.length, (index) {
          return SizedBox(
            width: 320,
            height: 200,
            child: _buildPlanTile(index, iap, plans, isMac: true),
          );
        }),
      );
    }

    // Mobile: 1+2 layout for better space utilization and robustness
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildPlanTile(0, iap, plans)),
              const SizedBox(width: 8),
              Expanded(child: _buildPlanTile(1, iap, plans)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPlanTile(2, iap, plans),
      ],
    );
  }

  Widget _buildPlanTile(
      int i,
      InAppPurchaseProvider iap,
      List<_PlanData> plans, {
        bool isMac = false,
      }) {
    final plan = plans[i];
    final selected = _selectedPlan == i;
    final isLifetime = i == 2;

    // Get real price if available
    final realPrice = iap.getPrice(plan.productId);

    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.logEvent('premium_screen_onTap_tapped');
        return setState(() => _selectedPlan = i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(isMac ? 24 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMac ? 24 : 16),
          gradient: selected
              ? LinearGradient(
            colors: [
              Colors.orange.shade400.withOpacity(0.22),
              Colors.deepOrange.shade700.withOpacity(0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected
                ? Colors.orange.shade400
                : Colors.white.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: isMac
            ? _buildMacTileContent(plan, realPrice, selected)
            : _buildMobileTileContent(plan, realPrice, selected, isLifetime),
      ),
    );
  }

  Widget _buildMacTileContent(_PlanData plan, String? realPrice, bool selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _radio(selected),
            const SizedBox(width: 12),
            Text(
              plan.label,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (plan.badge != null) ...[
          const SizedBox(height: 8),
          _badge(plan.badge!),
        ],
        const Spacer(),
        Text(
          realPrice ?? plan.price,
          style: GoogleFonts.outfit(
            color: selected ? Colors.orange.shade300 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
        Text(
          plan.per,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMobileTileContent(_PlanData plan, String? realPrice, bool selected, bool isLifetime) {
    if (isLifetime) {
      return Row(
        children: [
          _radio(selected),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plan.label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              realPrice ?? plan.price,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.orange.shade400 : Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _radio(selected),
        const SizedBox(height: 4),
        Text(
          plan.label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            realPrice ?? plan.price,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.orange.shade400 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _radio(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.orange.shade400 : Colors.white30,
          width: 2,
        ),
        color: selected ? Colors.orange.shade400 : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 12)
          : null,
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildSubscribeButton(InAppPurchaseProvider iap, bool isPremium, List<_PlanData> plans) {
    final l10n = AppLocalizations.of(context);
    final plan = plans[_selectedPlan];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            plan.label == 'Lifetime' || plan.label == (l10n?.lifetime ?? 'Lifetime')
                ? (l10n?.legalNoticeLifetime ?? "Payment will be charged to your iTunes account at confirmation of purchase. This is a one-time purchase that unlocks all Pro features forever. No monthly or yearly renewals required.")
                : (l10n?.legalNoticeSubscription ?? "Payment will be charged to your iTunes account at confirmation of purchase. Your subscription will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage your subscription and turn off auto-renewal by going to your App Store Account Settings after purchase."),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: iap.isLoading
                ? null
                : () {
              AnalyticsService.instance.logEvent(
                'premium_screen_onPressed_tapped',
              );
              return _onSubscribe(iap, plans);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: iap.isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${l10n?.subscribe(plan.label) ?? 'Subscribe ${plan.label}'} — ${iap.getPrice(plan.productId) ?? plan.price}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildFooter(InAppPurchaseProvider iap) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _footerLink(AppLocalizations.of(context)!.termsOfService, _onTerms),
            _dot(),
            _footerLink(
              AppLocalizations.of(context)!.privacyPolicy,
              _onPrivacy,
            ),
            _dot(),
            _footerLink(
              AppLocalizations.of(context)!.restore,
                  () => _onRestore(iap),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: Colors.white24, fontSize: 14)),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white38,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white24,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  void _onSubscribe(InAppPurchaseProvider iap, List<_PlanData> plans) async {
    if (iap.isPremium) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.alreadyPremium),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }
    final productId = plans[_selectedPlan].productId;
    await iap.purchase(productId);
  }

  void _onRestore(InAppPurchaseProvider iap) async {
    final l10n = AppLocalizations.of(context);

    final success = await iap.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (l10n?.purchaseSuccessful ?? 'Purchases restored successfully!')
                : (l10n?.unknown ?? 'No previous purchases found.'),
          ),
          backgroundColor: success ? Colors.green : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onTerms() async {
    final uri = Uri.parse(
      'https://sites.google.com/view/eline-chart-terms-condition/terms-of-services',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onPrivacy() async {
    final uri = Uri.parse(
      'https://sites.google.com/view/eline-chart-terms-condition/privacy-policy',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────
class _PlanData {
  final String label;
  final String price;
  final String per;
  final String? badge;
  final String productId;
  const _PlanData({
    required this.label,
    required this.price,
    required this.per,
    this.badge,
    required this.productId,
  });
}

class _Feature {
  final IconData icon;
  final String label;
  final Color color;
  const _Feature({
    required this.icon,
    required this.label,
    required this.color,
  });
}
