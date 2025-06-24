# PRD: SnapUI Design System

## 1. Introduction/Overview

This document outlines the requirements for **SnapUI**, a comprehensive, in-house design system for the SnapAMeal application. The primary purpose of this feature is to establish a unique, mature, and cohesive brand identity that distinguishes SnapAMeal from its competitors and appeals to a broader demographic (late teens to early 50s). This system will standardize all visual elements, improve UI consistency, and create a scalable framework that streamlines future development.

## 2. Goals

- **Establish Brand Identity:** Create a clean, modern, and trustworthy visual language that defines the SnapAMeal brand.
- **Ensure Consistency:** Guarantee that all UI elements—colors, typography, spacing, and components—are uniform across the entire application on all platforms.
- **Improve Developer Experience:** Centralize all UI constants and widgets into a single, easy-to-use library, accessible via a single import, to accelerate development.
- **Eliminate Technical Debt:** Completely refactor and remove all legacy, one-off styling and old component widgets.

## 3. User Stories

- **As a user,** I want the app to have a cohesive and polished look and feel, so that my experience feels intuitive, professional, and trustworthy.
- **As a developer,** I want to import a single `snap_ui.dart` file to access all common widgets and constants, so I can build new features quickly without worrying about styling.
- **As a developer,** I want all core components (buttons, text fields, avatars) to be standardized and reusable, so I don't have to write custom styles for each new screen.

## 4. Functional Requirements

1.  **Directory Structure:** A new directory `lib/design_system` will be created to house all related files.
2.  **Color Palette:** A `colors.dart` file will define a standard color palette, including a primary golden-yellow, accents, and a greyscale for both light and dark themes.
3.  **Typography:** A `typography.dart` file will define a standard `TextTheme` using the "Nunito Sans" font from Google Fonts.
4.  **Dimensions:** A `dimensions.dart` file will define standard values for spacing, padding, border radii, and icon sizes.
5.  **Iconography:** The `eva_icons_flutter` package will be integrated as the official icon library.
6.  **`SnapButton` Widget:** A reusable button widget will be created with support for primary (filled) and secondary (outline/subtle) styles.
7.  **`SnapTextField` Widget:** A reusable, styled text field widget will be created for all input forms.
8.  **`SnapAvatar` Widget:** A reusable avatar widget will be created to display user-uploaded profile pictures, with a fallback to user initials.
9.  **Theme Refactoring:** The existing `light_mode.dart` and `dark_mode.dart` files will be fully refactored to source all their values from the new design system files.
10. **Component Refactoring:** All existing instances of `MyButton`, `MyTextField`, and any other custom-styled widgets will be replaced with their new `SnapUI` equivalents.
11. **Barrel File:** A single file, `lib/design_system/snap_ui.dart`, will be created to export all public widgets and constants for easy importation.

## 5. Non-Goals (Out of Scope)

- This feature does **not** include the creation of a custom icon set. A third-party library (`eva_icons_flutter`) will be used.
- This feature does **not** cover the implementation of complex animations or micro-interactions. The focus is on static UI elements and themes.

## 6. Design Considerations

- **Primary Color:** A mature, golden-yellow (`#FFC107`).
- **Font:** "Nunito Sans" via `google_fonts`.
- **Icons:** `eva_icons_flutter`.
- **Overall Feel:** Clean, minimalist, and spacious, with clear visual hierarchy.

## 7. Technical Considerations

- All design system code will be located within `lib/design_system/`.
- The `snap_ui.dart` barrel file should be the single point of entry for developers using the system.
- Legacy component files in `lib/components/` must be deleted after they are fully refactored and no longer referenced.

## 8. Success Metrics

- **100% Refactoring:** All UI styling and component definitions are sourced exclusively from the `lib/design_system` directory.
- **Legacy Code Removal:** The `lib/components/` directory and its contents are completely deleted from the project.
- **Codebase Simplification:** UI-related code in feature files is simplified to only reference `SnapUI` components, with no local styling overrides.

## 9. Open Questions

- None at this time. 