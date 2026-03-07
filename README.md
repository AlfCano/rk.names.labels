# rk.names.labels: Data Cleaning & Labeling Tools for RKWard

![Version](https://img.shields.io/badge/Version-0.0.5-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.names.labels/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.names.labels/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

This package provides a suite of RKWard plugins designed to streamline the often tedious process of cleaning variable names and managing variable labels in R. It creates a graphical user interface for powerful data tidying functions from packages like `janitor`, `stringr`, `tibble`, `vctrs`, and `rio`.

It is specifically designed to handle both **column names** (technical identifiers) and **variable labels** (descriptive metadata used by RKWard), allowing users to clean, format, and synchronize them easily.

## 🌍 Internationalization

As of version 0.0.5, this plugin is fully localized. The interface automatically adapts to the language settings of your RKWard installation.

**Supported Languages:**
*   🇺🇸 **English** (Default)
*   🇪🇸 **Spanish** (`es`)
*   🇫🇷 **French** (`fr`)
*   🇩🇪 **German** (`de`)
*   🇧🇷 **Portuguese** (Brazil) (`pt_BR`)

## Features / Included Plugins

This package installs a new submenu in RKWard: **Data > Names and Labels**.

### Main Tools
*   **Tidy Names and Labels:** The central tool for cleaning data frames.
    *   **Name Repair:** Standardize column names using `janitor::clean_names()` (snake_case), base R's `make.names` (syntactic), `make.unique`, or `tibble`'s universal repair strategies.
    *   **Case Conversion:** Convert names or labels to `tolower` or `toupper`.
    *   **String Cleanup:** Apply `stringr::str_trim()` (remove surrounding whitespace) and `str_squish()` (reduce repeated internal whitespace).
    *   **Scope Control:** Apply cleaning rules to **Names only**, **Labels only**, or **Both**.
    *   **Sync:** Option to copy cleaned variable names directly into the variable labels.

*   **Pattern Replacement:** A regex-based search and replace tool.
    *   Uses `stringr::str_replace_all()` to find and replace patterns.
    *   Can be applied to either column names or variable labels.

*   **Sequence Rename:** Tools for batch renaming variables.
    *   **Sequence Mode:** Rename selected columns with a custom pattern (e.g., `Item_1`, `Item_2`, `Item_3`).
    *   **Tibble Repair:** Apply specific `tibble` name repair strategies (Universal, Unique) to an entire data frame to fix duplicate or broken names.

*   **Dictionary Lookup:** Automate labeling using a codebook.
    *   Select a target data frame and a "dictionary" data frame.
    *   Select the Key (variable name) and Value (label) columns directly using drag-and-drop slots.
    *   Maps descriptive labels using a Key/Value matching system (via the `lookup` package).

### Submenu: Value labels (levels)
*   **Catalog Assignment:** Applies value labels to factor levels using reference catalogs.
    *   Accepts a **List of Data Frames** (automatically matches list names to variable names in the target).
    *   Accepts a **Single Data Frame** (applies one catalog to all compatible variables in the target).
    *   Uses `lookup::vlookup` to map codes to descriptions.

*   **Import Catalog:** A utility to build catalog lists.
    *   Batch imports multiple CSV files from a selected directory.
    *   Cleans character encoding (e.g., UTF-8 or Latin1).
    *   Creates a named list of data frames ready for use in "Catalog Assignment".

## Installation

### With `remotes` (Recommended)
To install the plugin package directly from GitHub:

```R
local({
## Preparar
require(remotes)
## Computar
  install_github(
    repo="AlfCano/rk.names.labels"
  )
## Imprimir el resultado
rk.header ("Resultados de Instalar desde git")
})
```

### Manual Installation
1.  Download this repository as a `.zip` file.
2.  In RKWard, go to **Settings -> R Packages -> Install package(s) from local zip file(s)**.

## Usage

Once installed, all plugins can be found under the **Data > Names and Labels** menu in RKWard.

### Example: Cleaning a Messy Dataset

1.  Load a dataset with messy column names (e.g., "First Name", "Last  Name", "Age (Years)").
2.  Navigate to **Data > Names and Labels > Tidy Names and Labels**.
3.  **Input Tab:** Select your data frame.
4.  **Transformations Tab:**
    *   Set **Name Repair Strategy** to "Janitor (snake_case)".
    *   Set **Apply Transformations To** to "Both Names and Labels".
    *   Check "Squish Whitespace" to fix spacing issues.
5.  **Output Tab:**
    *   Check "Copy variable names to labels" if you want the new clean names to be the default label.
    *   Define the output object name (default is `tidy_data`).
6.  Click **Submit**.

The result will be a clean data frame (`first_name`, `last_name`, `age_years`) ready for analysis.

## Requirements

*   **RKWard:** Version 0.7.0 or greater.
*   **R Packages:** `janitor`, `stringr`, `tibble`, `vctrs`, `lookup`, `rio`.

## Author & License

*   **Author:** Alfonso Cano (<alfonso.cano@correo.buap.mx>)
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)
