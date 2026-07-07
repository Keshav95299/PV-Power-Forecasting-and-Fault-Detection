# Short-Term PV Power Forecasting and Fault Detection Using MATLAB

## Overview

This project presents an end-to-end MATLAB pipeline for short-term photovoltaic (PV) power forecasting and online fault detection. The system combines machine learning-based forecasting with conformal prediction to quantify prediction uncertainty and uses residual-based methods to detect inverter underperformance and soiling faults.

The project was developed as part of an MSc research project on renewable energy analytics and predictive maintenance.

---

## Features

- Data preprocessing and cleaning
- Feature engineering using weather and temporal variables
- Short-term PV power forecasting using LSBoost regression
- Split conformal prediction for uncertainty quantification
- Residual analysis and forecasting evaluation
- Inverter underperformance fault injection
- Soiling fault simulation
- Sliding-window fault detection
- Detection delay vs. false-positive trade-off analysis

---

## Project Structure

```
project/
│
├── src/                      % MATLAB source files
├── figures/                  % Output figures
├── data/                     % Input CSV files (not included)
├── main.m                    % Main execution script
├── loadData.m
├── 01_DataCleaning.m
├── README.md
└── LICENSE
```

---

## Methodology

The workflow consists of the following stages:

1. Load and clean photovoltaic and weather datasets.
2. Merge datasets and engineer predictive features.
3. Train an LSBoost regression forecasting model.
4. Evaluate forecasting performance using RMSE and MAE.
5. Apply Split Conformal Prediction to estimate prediction intervals.
6. Inject inverter underperformance and soiling faults.
7. Detect faults using a sliding-window residual monitoring algorithm.
8. Evaluate detection delay and false-positive performance.

---

## Forecasting Model

Regression algorithm:

- **LSBoost (Least Squares Boosting)**

Input features include:

- Global irradiance
- Direct irradiance
- Diffuse irradiance
- Temperature
- Humidity
- Solar zenith angle
- Solar azimuth angle
- Hour of day (cyclic encoding)
- Day of year (cyclic encoding)

---

## Results

The implemented framework successfully demonstrates:

- Accurate short-term PV forecasting
- Prediction uncertainty estimation using conformal prediction
- Fast detection of inverter underperformance
- Detection of gradual soiling degradation
- Trade-off analysis between detection delay and false alarms

Example output figures are available in the **figures/** directory.

---

## Figures

The repository contains example outputs including:

- Forecasting performance
- Conformal prediction intervals
- Residual analysis
- Inverter underperformance detection
- Soiling fault detection
- Detection delay vs. false-positive trade-off

---

## Dataset

The raw datasets are **not included** because they exceed GitHub's file size limits.

Place the required CSV files inside the local `data/` directory before running the project.

Expected files include:

- photovoltaic_measurement_history.csv
- weather_station_measurement_history.csv
- weather_prediction_history.csv
- photovoltaic_metadata.csv

---

## Requirements

- MATLAB R2023a or later (recommended)
- Statistics and Machine Learning Toolbox

---

## Running the Project

Execute:

```matlab
main
```

The script automatically performs:

- Data loading
- Feature engineering
- Model training
- Forecast evaluation
- Conformal prediction
- Fault injection
- Fault detection
- Result visualization

---

## Future Improvements

Potential future work includes:

- LightGBM/XGBoost forecasting models
- Adaptive conformal prediction
- Real-time streaming implementation
- Multiple fault classification
- Deep learning forecasting models

---

## Author

**Keshav Sharma**

MSc Project

---

## License

This project is released under the MIT License.
