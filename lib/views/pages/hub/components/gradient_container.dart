import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/client_rating.dart';
import 'package:blockatie/services/client_rating_service.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';

class GradientBorderRankBox extends StatefulWidget {
  const GradientBorderRankBox({super.key});

  @override
  State<GradientBorderRankBox> createState() => _GradientBorderRankBoxState();
}

class _GradientBorderRankBoxState extends State<GradientBorderRankBox> {
  ClientRating? _clientRating;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchClientRating();
  }

  Future<void> _fetchClientRating() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rating = await ClientRatingService.getClientRating();
      if (mounted) {
        setState(() {
          _clientRating = rating;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Show loading indicator while fetching data
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [AppColors.gradient1, AppColors.gradient2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Semantics(
            label: AppTranslations.getText('loading_rating'),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Show error state if there's an error
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [AppColors.gradient1, AppColors.gradient2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Semantics(
            label: AppTranslations.getText('error_loading_rating'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 8,
                  backgroundImage: NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/2922/2922510.png'),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: AppTranslations.getText('client_rating'),
                  child: Text(
                    '${AppTranslations.getText('rank')} 0.0',
                    style: textTheme.bodyMedium!.copyWith(color: Colors.black),
                    semanticsLabel:
                        '${AppTranslations.getText('client_rating')}: 0.0',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
        padding: const EdgeInsets.all(1), // Border thickness
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [AppColors.gradient1, AppColors.gradient2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Semantics(
            label:
                '${AppTranslations.getText('client_rating')}: ${_clientRating?.avgRating.toStringAsFixed(1) ?? '0.0'}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundImage: _clientRating?.clientImage != null &&
                          _clientRating!.clientImage.isNotEmpty
                      ? NetworkImage(
                          'https://dashboard.blockatie.com${_clientRating!.clientImage}')
                      : const NetworkImage(
                          'https://cdn-icons-png.flaticon.com/512/2922/2922510.png'),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: AppTranslations.getText('client_rating'),
                  child: Text(
                    _clientRating?.avgRating != null
                        ? '${AppTranslations.getText('rank')} ${_clientRating!.avgRating.toStringAsFixed(1)}'
                        : '${AppTranslations.getText('rank')} 0.0',
                    style: textTheme.bodyMedium!.copyWith(color: Colors.black),
                    semanticsLabel:
                        '${AppTranslations.getText('client_rating')}: ${_clientRating?.avgRating.toStringAsFixed(1) ?? '0.0'}',
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
