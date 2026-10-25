import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app/theme/app_theme.dart';

/// A shared avatar that also handles expired or unavailable profile URLs.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const ProfileAvatar({super.key, this.photoUrl, this.size = 76});

  @override
  Widget build(BuildContext context) {
    Widget fallback() =>
        Image.asset('assets/images/default_avatar.png', fit: BoxFit.cover);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold.withValues(alpha: .65)),
      ),
      child: ClipOval(
        child:
            photoUrl?.trim().isNotEmpty == true
                ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                )
                : fallback(),
      ),
    );
  }
}

class AccountProfileCard extends StatelessWidget {
  final String name;
  final String? email;
  final String? photoUrl;
  final bool guest;
  final VoidCallback? onEditPhoto;
  const AccountProfileCard({
    super.key,
    required this.name,
    this.email,
    this.photoUrl,
    required this.guest,
    this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF493427), AppTheme.espresso],
      ),
      border: Border.all(color: AppTheme.gold.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileAvatar(photoUrl: photoUrl),
            const Spacer(),
            if (onEditPhoto != null)
              IconButton.filledTonal(
                tooltip: 'edit_profile_photo'.tr(),
                onPressed: onEditPhoto,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.gold.withValues(alpha: .15),
                  foregroundColor: AppTheme.gold,
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              )
            else
              const Icon(
                Icons.auto_stories_outlined,
                color: AppTheme.gold,
                size: 24,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: const Color(0xFFFFF5E3)),
        ),
        if (email?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            email!,
            style: const TextStyle(color: Color(0xFFE0D0BC), height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          (guest ? 'guest_account' : 'reader_account').tr(),
          style: const TextStyle(
            color: AppTheme.gold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class AccountSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const AccountSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool selected;
  const AccountTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.secondary;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: danger ? scheme.error : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
