# Probabilistic Photovoltaic Power Forecasting and Fault Detection Using Split Conformal Prediction

## Overview

This project presents a complete photovoltaic (PV) monitoring framework that combines:

- 24-hour-ahead PV power forecasting
- Distribution-free uncertainty quantification using Split Conformal Prediction
- Automatic fault detection using a sliding-window persistence rule

The framework predicts PV power every 15 minutes over a 24-hour forecasting horizon and uses prediction intervals to distinguish normal forecasting uncertainty from abnormal system behaviour.

Two common PV fault scenarios are simulated and evaluated:

- Inverter underperformance
- Gradual photovoltaic soiling

This work was completed as part of an MSc dissertation at Robert Gordon University.

---

# Project Workflow

```
Weather Forecast Data
          │
          ▼
Forecast Dataset Construction
          │
          ▼
24-Hour Ahead Forecasting Model
          │
          ▼
Split Conformal Prediction
          │
          ▼
Prediction Intervals
          │
          ▼
Fault Injection
          │
          ▼
Sliding-Window Fault Detection
          │
          ▼
Fault Alarm
```

---

# Repository Structure

```
project/
│
├── data/
│   ├── photovoltaic_measurement_history.csv
│   ├── weather_station_measurement_history.csv
│   └── weather_prediction_history.csv
│
├── src/
│   ├── loadData.m
│   ├── cleanData.m
│   ├── resampleData.m
│   ├── decodeForecast.m
│   ├── buildDayAheadDataset.m
│   ├── splitData.m
│   ├── trainForecastModel.m
│   ├── evaluateForecastModel.m
│   ├── conformalPrediction.m
│   ├── prepareMonitoringStream.m
│   ├── injectInverterFault.m
│   ├── injectSoilingFault.m
│   ├── detectFaults.m
│   ├── detectFaultsCUSUM.m
│   └── featureEngineering.m
│
├── figures/
│
├── main.m
│
└── README.md
```

---

# Dataset

The framework uses three synchronized datasets.

### Photovoltaic measurements

- Active power
- Global irradiance
- Module temperature

### Weather station measurements

- Ambient temperature
- Humidity
- Wind speed
- Solar geometry

### Numerical weather forecasts

- Global irradiance
- Temperature
- Cloud cover
- Humidity
- Wind speed

All measurements are resampled to a common 15-minute resolution.

---

# Forecasting Pipeline

The forecasting stage constructs a **true day-ahead forecasting dataset**.

Characteristics:

- Forecast horizon: **24 hours**
- Resolution: **15 minutes**
- Forecast lead times: **96**
- Chronological splitting by forecast issue time

Input features include:

- Forecast irradiance
- Forecast temperature
- Forecast humidity
- Forecast cloud cover
- Forecast lead time
- Cyclic hour encoding
- Cyclic day-of-year encoding

The forecasting model is trained using MATLAB's **LSBoost regression ensemble**.

---

# Forecasting Performance

Testing results

| Metric | Value |
|---------|------:|
| RMSE | 1698.74 W |
| MAE | 865.80 W |
| Bias | -478.55 W |
| Maximum Absolute Error | 8705.26 W |

Although the forecasting model captures the overall daily PV generation profile, forecasting errors increase during rapidly changing weather conditions.

---

# Split Conformal Prediction

Lead-time-conditioned Split Conformal Prediction is applied to quantify forecasting uncertainty.

Performance

| Metric | Value |
|---------|------:|
| Nominal Coverage | 90% |
| Empirical Coverage | 87.95% |
| Average Interval Width | 3508.09 W |
| Global Conformal Quantile | 2657.59 W |

Prediction intervals are subsequently used for fault detection.

---

# Fault Simulation

Two synthetic fault scenarios are implemented.

## Inverter Underperformance

- Sudden 20% reduction in PV output

## Gradual Soiling

- Progressive power reduction
- Final loss = 20%

Faults are injected only into the monitoring dataset while leaving forecasting unchanged.

---

# Sliding-Window Fault Detection

The final monitoring framework detects faults using a persistence-based sliding-window rule.

Detection rule:

An alarm is generated when

Measured Power

falls below

Lower Conformal Prediction Bound

for

**k = 4**

consecutive 15-minute samples.

This corresponds to one hour of persistent abnormal behaviour.

---

# Detection Results

## Inverter Underperformance

| Metric | Value |
|---------|------:|
| Detection Delay | 1.25 hours |
| False Positive Rate | 0.98% |

## Gradual Soiling

| Metric | Value |
|---------|------:|
| Detection Delay | 1.25 hours |
| False Positive Rate | 0.98% |

The detector successfully identifies both simulated fault scenarios while maintaining a low false-positive rate.

---

# Previous CUSUM Implementation

During development, a one-sided CUSUM detector was also implemented and evaluated.

The CUSUM approach successfully detected faults but was ultimately replaced by the sliding-window detector because:

- the project specification explicitly required a persistence rule using **k consecutive lower-bound violations**;
- the sliding-window detector is simpler to interpret;
- it directly corresponds to the required anomaly detection methodology.

The CUSUM implementation remains in the repository (`detectFaultsCUSUM.m`) for comparison purposes.

---

# Running the Project

Execute

```matlab
main
```

The pipeline performs:

1. Load datasets
2. Data cleaning
3. Resampling
4. Day-ahead dataset construction
5. Forecast model training
6. Forecast evaluation
7. Split Conformal Prediction
8. Monitoring stream preparation
9. Fault injection
10. Sliding-window fault detection
11. Performance evaluation

---

# MATLAB Version

Tested using

- MATLAB R2024a

Required toolboxes

- Statistics and Machine Learning Toolbox

---

# Future Improvements

Possible future work includes:

- Deep learning forecasting models (LSTM, Transformer)
- Adaptive conformal prediction
- Multi-fault classification
- Real-world fault datasets
- Online model updating

---

# Author

**Keshav Sharma**

MSc (Eu-Core)


---

# License

This repository is provided for academic and research purposes.

---

