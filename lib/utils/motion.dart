import 'package:flutter/widgets.dart';

/// Shared motion helpers (#69).
///
/// Every animation goes through [motionDuration] so it collapses to zero
/// when the user has asked the OS to reduce motion.
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : duration;

/// Hero tag linking a bird's photo in the list to the detail header.
String birdPhotoHeroTag(String birdId) => 'bird-photo-$birdId';
