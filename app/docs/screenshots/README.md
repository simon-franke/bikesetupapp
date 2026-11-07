# README screenshots

These images show actual Flutter widgets rendered with sample repositories. No personal ride or account data is used. They are UI previews, not photographs of a running device.

From `app/`, regenerate the source captures with the existing visual-review test:

```sh
UI_REVIEW_OUTPUT=/tmp/clickwise-readme flutter test test/ui_consistency_test.dart --update-goldens --plain-name 'setup and experiment hierarchy fits dark=false scale=1.0'
```

Copy `overview-false-1.0.png`, `pressure-editor-false-1.0.png` and `comparison-false-1.0.png` to `setup.png`, `pressure.png` and `experiment.png` respectively. Review the images before replacing the published screenshots.
