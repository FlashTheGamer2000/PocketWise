# PocketWise keyboard / defensive UI update

This patch is based on the uploaded `PocketWise_v0.3.5-beta` project.

## What changed

- Explicitly set `resizeToAvoidBottomInset: true` on the Welcome, Sign Up,
  Add Expense, Budget, and Profile scaffolds. Flutter now explicitly resizes
  each screen's available body area when the on-screen keyboard appears.
- Kept the existing `SingleChildScrollView` layouts and drag-to-dismiss
  keyboard behavior on the form screens.
- Added drag-to-dismiss behavior to the Profile screen.
- Kept the Budget and Profile edit dialogs' scrollable content and enabled
  `AlertDialog.scrollable` so dialog content/actions can adapt on short screens.
- Removed the extra keyboard-height bottom padding from Add Expense. The
  Scaffold already resizes its body for the keyboard; adding the full inset
  again would count the keyboard space twice.

## Verify on an emulator or phone

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Then manually verify on a small emulator (for example, 360 x 640):

1. Open Welcome and focus the account-name and password fields.
2. Open Sign Up and focus each of its three fields.
3. Open Add Expense, focus the description and amount fields, and scroll to
   the Save button while the keyboard is visible.
4. Open Budget and edit the monthly budget with the keyboard visible.
5. Open Profile and test the profile-name and password dialogs.
6. On each screen, confirm the focused field and action buttons remain
   reachable by scrolling, and that no yellow/black overflow stripes appear.
7. Dismiss the keyboard by dragging the form where supported.

The source has been updated, but a real Flutter analyze/test run and physical
emulator check are still required to confirm runtime behavior.
