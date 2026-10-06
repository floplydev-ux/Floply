import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../l10n/app_strings.dart';
import '../../services/premium/promo_aware_premium_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import 'widgets/promo_code_section.dart';

/// Paywall Premium con estética Sala Verde / FLOPly.
///
/// Carga las Offerings de RevenueCat dinámicamente — los precios son siempre
/// los que devuelve RC, nunca hardcodeados. El entitlement se activa en
/// [PremiumService] vía listener; cuando isPremium pasa a true mientras
/// esta pantalla está abierta, se cierra automáticamente.
class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key, required this.premium});

  final PremiumService premium;

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _loadingOfferings = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.premium.addListener(_onPremiumChanged);
    _loadOfferings();
  }

  @override
  void dispose() {
    widget.premium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (widget.premium.isPremium && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loadingOfferings = true;
      _errorMessage = null;
    });
    final offerings = await widget.premium.getOfferings();
    if (!mounted) return;
    final packages = offerings?.current?.availablePackages ?? [];
    setState(() {
      _loadingOfferings = false;
      _offerings = offerings;
      _selectedPackage = packages.isEmpty ? null : packages.first;
    });
  }

  Future<void> _purchase() async {
    final package = _selectedPackage;
    if (package == null) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final success = await widget.premium.purchasePackage(package);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      setState(() => _errorMessage = AppStrings.premiumPurchaseError);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final success = await widget.premium.restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      setState(() => _errorMessage = AppStrings.premiumRestoreNotFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      appBar: AppBar(
        backgroundColor: SalaVerdeColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: SalaVerdeColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SalaVerdeSpace.xl,
            SalaVerdeSpace.sm,
            SalaVerdeSpace.xl,
            SalaVerdeSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: SalaVerdeSpace.xl),
              _buildBenefits(),
              const SizedBox(height: SalaVerdeSpace.xl),
              if (_loadingOfferings)
                _buildLoadingPackages()
              else if ((_offerings?.current?.availablePackages ?? []).isEmpty)
                _buildNoOfferings()
              else
                _buildPackages(),
              if (_errorMessage != null) ...[
                const SizedBox(height: SalaVerdeSpace.md),
                Text(
                  _errorMessage!,
                  style:
                      SalaVerdeType.caption(color: SalaVerdeColors.errorBright),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: SalaVerdeSpace.lg),
              SvButtonPrimary(
                label: _busy
                    ? AppStrings.premiumPurchasing
                    : AppStrings.premiumSubscribeCta,
                onTap: (_busy ||
                        _selectedPackage == null ||
                        _loadingOfferings)
                    ? null
                    : _purchase,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(
                    AppStrings.premiumRestorePurchases,
                    style:
                        SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                  ),
                ),
              ),
              // Bloque de código promocional — solo visible si el premium
              // es PromoAwarePremiumService (en producción siempre lo es).
              if (widget.premium is PromoAwarePremiumService) ...[
                const SizedBox(height: SalaVerdeSpace.xl),
                PromoCodeSection(
                  promoService:
                      (widget.premium as PromoAwarePremiumService).promoService,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SalaVerdeColors.brass.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.sports_rounded,
            color: SalaVerdeColors.brass,
            size: 26,
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        Text(AppStrings.premiumTitle, style: SalaVerdeType.headline()),
        const SizedBox(height: SalaVerdeSpace.sm),
        Text(
          AppStrings.premiumSubtitle,
          style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    return SvSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _benefit(Icons.sports_rounded, AppStrings.premiumBenefitCoach),
          const SizedBox(height: SalaVerdeSpace.md),
          _benefit(Icons.construction_rounded, AppStrings.premiumBenefitTools),
          const SizedBox(height: SalaVerdeSpace.md),
          _benefit(Icons.block_rounded, AppStrings.premiumBenefitNoAds),
          const SizedBox(height: SalaVerdeSpace.md),
          _benefit(Icons.favorite_rounded, AppStrings.premiumBenefitSupport),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: SalaVerdeColors.brassBright, size: 18),
        const SizedBox(width: SalaVerdeSpace.md),
        Expanded(child: Text(text, style: SalaVerdeType.body())),
      ],
    );
  }

  Widget _buildLoadingPackages() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(SalaVerdeSpace.xl),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: SalaVerdeColors.brassBright,
          ),
        ),
      ),
    );
  }

  Widget _buildNoOfferings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.premiumNoOfferings,
          style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        SvButtonPrimary(
          label: AppStrings.premiumRetry,
          onTap: _loadOfferings,
        ),
      ],
    );
  }

  Widget _buildPackages() {
    final packages = _offerings!.current!.availablePackages;
    return Column(
      children: [
        for (final pkg in packages)
          _PackageTile(
            package: pkg,
            isSelected: _selectedPackage?.identifier == pkg.identifier,
            onTap: () => setState(() => _selectedPackage = pkg),
          ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  String get _title {
    return switch (package.packageType) {
      PackageType.monthly => 'Mensual',
      PackageType.annual => 'Anual',
      PackageType.weekly => 'Semanal',
      PackageType.lifetime => 'Pago único',
      _ => package.identifier,
    };
  }

  String get _period {
    return switch (package.packageType) {
      PackageType.monthly => 'por mes',
      PackageType.annual => 'por año',
      PackageType.weekly => 'por semana',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final period = _period;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SalaVerdeMotion.fast,
        margin: const EdgeInsets.only(bottom: SalaVerdeSpace.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? SalaVerdeColors.brass.withValues(alpha: 0.10)
              : SalaVerdeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          border: Border.all(
            color: isSelected
                ? SalaVerdeColors.brass
                : SalaVerdeColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SalaVerdeSpace.lg,
          vertical: SalaVerdeSpace.md,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SalaVerdeMotion.fast,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? SalaVerdeColors.brass
                      : SalaVerdeColors.textMuted,
                  width: 2,
                ),
                color: isSelected
                    ? SalaVerdeColors.brass.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: SalaVerdeColors.brassBright,
                        size: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Text(_title, style: SalaVerdeType.bodyStrong()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  package.storeProduct.priceString,
                  style: SalaVerdeType.bodyStrong(
                      color: SalaVerdeColors.brassBright),
                ),
                if (period.isNotEmpty)
                  Text(
                    period,
                    style:
                        SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
