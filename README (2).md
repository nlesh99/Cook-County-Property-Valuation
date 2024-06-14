
# Property Assessment Model

This repository contains an R-based implementation of a Lasso regression model to predict property sale prices using historical property data. The model uses various property characteristics and geographical data to generate predictions for property assessments.

## Project Structure

- **`historic_property_data.csv`**: Historical property data for training the model.
- **`predict_property_data.csv`**: Property data for which sale prices need to be predicted.
- **`codebook.csv`**: Data dictionary describing the columns in the dataset.

## Dependencies

Ensure you have the following R packages installed:

```r
install.packages(c("boot", "glmnet", "ggplot2", "dplyr", "tidyr", "Matrix"))
```

## Usage

1. **Load Data**: The script reads and processes the historical and prediction property data from CSV files.

2. **Handle Missing Values**: Character-type columns with missing values are filled with "Unknown". Rows with other missing values are dropped.

3. **Feature Selection**: The script selects predictor columns based on the codebook and separates numerical and non-numerical columns.

4. **Data Transformation**: Numerical columns are cast as numeric, non-numerical columns are converted to factors, and data is concatenated for one-hot encoding.

5. **One-Hot Encoding**: Applied to factor columns to ensure consistent columns between training and prediction datasets.

6. **Data Splitting**: Training data is split into training and testing datasets.

7. **Lasso Regression**: Lasso regression with cross-validation is performed on the training data.

8. **Model Evaluation**: Mean Squared Error (MSE) is calculated for the test dataset.

9. **Prediction**: The model generates sale price predictions for the prediction dataset and writes them to `prediction.csv`.

## Script Execution

To execute the script, run the following R code:

```r
# Load required libraries
library(boot)
library(glmnet)
library(ggplot2)
library(dplyr)
library(tidyr)
library(Matrix)

# Read data from CSV files
train <- read.csv("historic_property_data.csv")
predict <- read.csv("predict_property_data.csv")
codebook <- read.csv("codebook.csv")

# Handle missing values and preprocess data
# ... (remaining script as provided)

# Run Lasso regression and make predictions
# ... (remaining script as provided)
```

## Output

- **`prediction.csv`**: Contains the predicted sale prices for the properties in the `predict_property_data.csv` dataset. The `pid` column identifies each property, and the `assessed_value` column contains the predicted sale price.

## Key Points

- **Model**: Lasso regression with cross-validation.
- **Feature Engineering**: Includes handling missing values, type casting, and one-hot encoding.
- **Evaluation**: Mean Squared Error (MSE) is used to evaluate the model performance on the test dataset.
- **Final Predictions**: Missing predictions are replaced with the mean of the available predictions.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more information.

## Contact

For any questions or issues, please open an issue or contact the project maintainers.
