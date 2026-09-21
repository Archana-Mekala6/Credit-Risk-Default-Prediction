# Credit Risk PD Model — Loan Default Prediction & Risk Dashboard

## Business Question

Lenders need to understand **which borrowers are more likely to default and how predicted risk can support lending decisions**.

This project builds a **Probability of Default (PD) model** and uses Power BI to analyse portfolio risk, segment borrowers, evaluate model thresholds, and understand potential business impact.

## Key Findings

* Dataset contains approximately **25,000 loan records**.
* A **Logistic Regression** model was built to estimate Probability of Default.
* **CIBIL score** emerged as the strongest predictor of default risk among all features.
* The model achieved a **Precision-Recall AUC of 0.37**, reflecting the added difficulty of ranking risk in an imbalanced dataset where defaults are the minority class.
* At a **0.20 classification threshold** (chosen to maximize F1-score), default recall improved to **48%**, compared to just **10% recall at the standard 0.50 threshold** — with **39% precision** and a **43% F1-score**.
* Risk-band default rates on the test set (5,000 loans) increased from **2.24% (Low Risk)** to **51.85% (Very High Risk)**, showing the model meaningfully separates risk tiers.
* Threshold analysis illustrates the trade-off between catching more defaults and generating more false positives.

## Dataset

* **Source:** Indian Personal Loan Dataset (Kaggle)
* **Size:** Approximately 25,000 loan records
* **Target:** Default Flag
* **Key variables:** Income, EMI, CIBIL Score, Existing Loans, Loan Amount, Loan Purpose, Employment Type, City Tier, Collateral, Credit Inquiries, and Late Payments
* **Data quality:** Missing values were present in select columns and imputed using the median during preprocessing.

## Approach

### 1. Data Exploration & Validation — SQL

* Checked the dataset structure and record counts.
* Checked data types and missing values.
* Analysed default patterns across different segments.
* Created risk-related features.
* Prepared data for Python modelling.

### 2. Preprocessing — Python

* Filled missing numerical values using the median.
* Encoded categorical variables.
* Scaled numerical variables.
* Split the data into training and testing sets.

### 3. Model Building

* Built a **Logistic Regression** model.
* Generated a Probability of Default for each loan.

### 4. Model Evaluation

* Evaluated Precision, Recall and F1-score.
* Analysed the Confusion Matrix.
* Evaluated Precision-Recall AUC (0.37).
* Tested different classification thresholds.

### 5. Risk Segmentation

Predicted PD values for the test set (5,000 loans) were grouped into four risk bands:

| Risk Band | Loans | Default Rate |
| --------- | ----: | -----------: |
| Low       | 4,143 |        2.24% |
| Medium    |   476 |       13.86% |
| High      |   273 |       33.69% |
| Very High |   108 |       51.85% |

### 6. Power BI Dashboard

The project contains a **4-page Power BI report**:

1. **Portfolio Overview** — portfolio and default summary
2. **Risk Segmentation** — borrower risk-band analysis
3. **PD Model & Threshold Analysis** — cutoff, Precision, Recall, F1-score, approval rate and confusion matrix
4. **Business Impact Summary** — risk distribution, segment analysis and model-based loss impact
   
## Dashboard Preview

### 1. Portfolio Overview

![Portfolio Overview](power%20BI/Screenshots/page1_overview.png)

### 2. Risk Segmentation

![Risk Segmentation](power%20BI/Screenshots/page%202_risk%20segmentation.png)

### 3. PD Threshold Analysis

![PD Threshold Analysis](power%20BI/Screenshots/page%203_threshold_analysis.png)

### 4. Business Impact

![Business Impact](power%20BI/Screenshots/page%204_business_impact.png)

## Tools & Skills

- **SQL:** MySQL
- **Python:** Pandas, Scikit-learn
- **Modelling:** Logistic Regression, Probability of Default
- **Visualisation:** Power BI, DAX
- **Other:** SQLAlchemy, PyMySQL, Git, GitHub

## Project Structure

```text
Credit-Risk-Default-Prediction/
│
├── SQL/
├── Python/
├── Power BI/
├── .gitignore
└── README.md
```
## Future Improvements

* Compare Logistic Regression with Random Forest and Gradient Boosting.
* Perform probability calibration and validate the model across different borrower segments.
* Add SHAP-based explainability to identify the key factors contributing to each borrower's predicted risk.
* Deploy the PD model as an interactive Streamlit application for individual borrower-level risk prediction
* Incorporate macroeconomic indicators such as the RBI repo rate, inflation, and GDP growth as additional features to assess how broader economic conditions influence borrower default risk.

## Disclaimer

This project is developed for educational and portfolio purposes. The dataset and model outputs should not be used as the sole basis for real-world lending or credit decisions.
Actual credit-risk models require validated data, regulatory controls, model governance, fairness testing, and ongoing monitoring.
