# Swiggy-Sales-Analysis-Using-Sql

## 🛵 Swiggy Sales Data Analysis (Star Schema Implementation)

## 📌 Project Overview
This project demonstrates an end-to-end Data Engineering and Analytics workflow using MySQL. I transformed a flat, unorganized CSV dataset of Swiggy delivery orders containing **1,97,430 rows** into a professional Star Schema. The goal was to optimize the data structure for high-performance querying and to extract key business insights regarding revenue, customer spending, and regional performance.

## 🏗️ Data Architecture: The Star Schema
To move away from a redundant "flat-file" structure, I architected a Star Schema. This approach ensures data integrity and prepares the database for advanced Business Intelligence (BI) reporting.

### Fact Table: 

- fact_swiggy_orders (Centralized metrics: Price, Ratings, and Order IDs).

- Dimension Tables:

- dim_location: State, City, and Area data.

- dim_restaurant: Vendor details.

- dim_category: Food classification and cuisine types.

- dim_dish: Individual product tracking.

### 🛠️ Data Engineering & ETL Workflow

- I performed rigorous data cleaning to ensure the "Single Source of Truth" was accurate:

- Encoding Fixes: Resolved hidden UTF-8 BOM characters (ï»¿) in the source headers to ensure proper column referencing.

- Date Transformation: Converted string-based "Order Date" (DD-MM-YYYY) into proper ISO-standard Date objects using STR_TO_DATE for time-series analysis.

- Quality Validation: Executed a comprehensive Null and Blank check across all critical fields (Price, Date, and Location) to guarantee 100% data reliability.

### 📈 Key Business Insights Generated

Using the optimized schema, I developed a suite of analytical queries to answer critical business questions:

- Financial Performance: Calculated Total Revenue (formatted in Millions) 

- Growth Trends: Analyzed Monthly Order Volume to identify seasonal peaks.

- Geographic Deep-Dive: Ranked the Top 10 Cities by order volume to identify high-growth markets.

- Customer Segmentation: Built a Spending Bucket analysis (Budget, Eco, Mid, Premium, Luxury) to visualize the distribution of customer purchasing power.

- Product Performance: Evaluated Cuisine Categories by both order volume and average customer ratings.

- Quality Metrics: Analyzed the Distribution of Ratings across the entire platform.

### 🚀 Repository Contents
swiggy_raw_data.csv: The initial flat dataset.

swiggy_analysis_master_script.sql: The complete MySQL script containing ETL, Schema Creation, and Business Logic.

Visuals/: Screenshots of the Star Schema ER Diagram and key Excel visualizations.

## 🎓 About the Author

**Mohammad Taiyeb**

MBA Business Economics Candidate at the Department of Business Economics (DBE), University of Delhi.

Specializing in Data-Driven Decision Making and Business Intelligence.

Connect with me at https://www.linkedin.com/in/mohammad-taiyeb-623713259/
