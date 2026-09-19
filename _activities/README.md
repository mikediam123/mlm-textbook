# ICC teaching activity

The editable activity source is `icc-simulation.fragment.html`. The standalone export is `../activities/icc-simulation.html`; Quarto copies it to `docs/activities/icc-simulation.html` through the project resources setting. The null-model chapter links to that page.

The activity runs locally in the browser and does not collect responses. It contains two variance sliders, population ICC, fixed simulated random draws, a reset button, and four discussion questions. Initial variances are the rounded textbook values 8.55 and 39.15. No external R service is required.

To re-export after changing the fragment, run the visualization skill's `scripts/render.py` with this fragment as input and `activities/icc-simulation.html` as destination (`--force` to replace). The export bundles its styles and standalone state bridge. Then render the textbook and commit the source and generated files. The exported HTML can also be downloaded and opened offline.

Public activity URL: https://mikediam123.github.io/mlm-textbook/activities/icc-simulation.html
